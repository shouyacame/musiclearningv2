-- =====================================================
-- v6 セキュリティ強化（中優先度）
-- Supabase SQL Editor または CLI で実行してください
-- =====================================================

-- ① ログイン試行テーブル（レート制限用）
CREATE TABLE IF NOT EXISTS login_attempts (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id    TEXT NOT NULL,
  student_id   TEXT NOT NULL,
  attempted_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE login_attempts ENABLE ROW LEVEL SECURITY;
-- SECURITY DEFINER 関数からのみアクセス（直接アクセス不可）
REVOKE ALL ON login_attempts FROM anon, authenticated;

-- ② validate_student_pin 更新（レート制限追加）
--    15分以内に10回失敗するとブロック。成功時に記録をクリア。
CREATE OR REPLACE FUNCTION validate_student_pin(p_school_id TEXT, p_student_id TEXT, p_pin TEXT)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_student  students%ROWTYPE;
  v_token    UUID;
  v_attempts BIGINT;
BEGIN
  -- レート制限チェック
  SELECT COUNT(*) INTO v_attempts
  FROM login_attempts
  WHERE school_id = p_school_id
    AND student_id = p_student_id
    AND attempted_at > NOW() - INTERVAL '15 minutes';

  IF v_attempts >= 10 THEN
    RETURN json_build_object('valid', false, 'reason', 'rate_limited');
  END IF;

  SELECT * INTO v_student
  FROM students
  WHERE school_id = p_school_id AND student_id = p_student_id;

  IF NOT FOUND THEN
    INSERT INTO login_attempts (school_id, student_id) VALUES (p_school_id, p_student_id);
    RETURN json_build_object('valid', false, 'reason', 'not_found');
  END IF;

  -- PIN チェック
  IF v_student.pin IS NULL OR v_student.pin = '' THEN
    NULL; -- PIN 未設定はそのまま通過
  ELSIF v_student.pin LIKE '$2a$%' OR v_student.pin LIKE '$2b$%' THEN
    -- bcrypt ハッシュ済み
    IF crypt(p_pin, v_student.pin) <> v_student.pin THEN
      INSERT INTO login_attempts (school_id, student_id) VALUES (p_school_id, p_student_id);
      RETURN json_build_object('valid', false, 'reason', 'wrong_pin');
    END IF;
  ELSE
    -- 旧プレーンテキスト（後方互換）
    IF v_student.pin <> p_pin THEN
      INSERT INTO login_attempts (school_id, student_id) VALUES (p_school_id, p_student_id);
      RETURN json_build_object('valid', false, 'reason', 'wrong_pin');
    END IF;
  END IF;

  -- ログイン成功: この生徒の失敗記録を削除
  DELETE FROM login_attempts
  WHERE school_id = p_school_id AND student_id = p_student_id;
  -- 1時間以上古い全記録も掃除
  DELETE FROM login_attempts WHERE attempted_at < NOW() - INTERVAL '1 hour';

  -- 期限切れセッションを掃除してからトークン発行
  DELETE FROM student_sessions WHERE expires_at < NOW();

  INSERT INTO student_sessions (school_id, student_id)
  VALUES (p_school_id, p_student_id)
  RETURNING token INTO v_token;

  RETURN json_build_object(
    'valid',        true,
    'token',        v_token::TEXT,
    'pin_required', (v_student.pin IS NOT NULL AND v_student.pin <> ''),
    'name',         v_student.name,
    'grade',        v_student.grade,
    'class_name',   v_student.class_name,
    'number',       v_student.number
  );
END;
$$;
GRANT EXECUTE ON FUNCTION validate_student_pin(TEXT, TEXT, TEXT) TO anon;

-- ③ get_student_progress RPC（トークン認証→自分のデータのみ返す）
CREATE OR REPLACE FUNCTION get_student_progress(p_token UUID)
RETURNS TABLE(
  task_db_id      UUID,
  is_completed    BOOLEAN,
  memo            TEXT,
  completed_level INT,
  yt_speed        TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_school_id TEXT; v_student_id TEXT;
BEGIN
  SELECT school_id, student_id INTO v_school_id, v_student_id
  FROM student_sessions
  WHERE token = p_token AND expires_at > NOW();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  RETURN QUERY
  SELECT sp.task_db_id, sp.is_completed, sp.memo, sp.completed_level, sp.yt_speed
  FROM student_progress sp
  WHERE sp.school_id = v_school_id AND sp.student_id = v_student_id;
END;
$$;
GRANT EXECUTE ON FUNCTION get_student_progress(UUID) TO anon;

-- ④ get_practice_logs RPC（トークン認証→自分のデータのみ返す）
CREATE OR REPLACE FUNCTION get_practice_logs(p_token UUID)
RETURNS TABLE(logged_at DATE) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_school_id TEXT; v_student_id TEXT;
BEGIN
  SELECT school_id, student_id INTO v_school_id, v_student_id
  FROM student_sessions
  WHERE token = p_token AND expires_at > NOW();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  RETURN QUERY
  SELECT pl.logged_at
  FROM practice_logs pl
  WHERE pl.school_id = v_school_id AND pl.student_id = v_student_id
  ORDER BY pl.logged_at DESC;
END;
$$;
GRANT EXECUTE ON FUNCTION get_practice_logs(UUID) TO anon;

-- ⑤ anon の student_progress / practice_logs SELECT を完全削除
--    読み取りは get_student_progress / get_practice_logs RPC 経由のみ
DROP POLICY IF EXISTS "progress_anon_select" ON student_progress;
DROP POLICY IF EXISTS "practice_logs_anon_select" ON practice_logs;
