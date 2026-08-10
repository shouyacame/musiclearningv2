-- =====================================================
-- v5 セキュリティ強化
-- Supabase SQL Editor で実行してください
-- =====================================================

-- ① pgcrypto 有効化（PIN ハッシュ化に使用）
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ② セッショントークンテーブル
--    生徒ログイン成功時に発行し、書き込みRPCの認証に使う
CREATE TABLE IF NOT EXISTS student_sessions (
  token      UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id  TEXT NOT NULL,
  student_id TEXT NOT NULL,
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours'),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE student_sessions ENABLE ROW LEVEL SECURITY;
-- anon は直接アクセス不可（SECURITY DEFINER 関数経由のみ）
DROP POLICY IF EXISTS "sessions_anon" ON student_sessions;
REVOKE ALL ON student_sessions FROM anon;
GRANT SELECT, INSERT, DELETE ON student_sessions TO authenticated;

-- ③ validate_student_pin 更新（bcrypt 比較 + セッショントークン発行）
CREATE OR REPLACE FUNCTION validate_student_pin(p_school_id TEXT, p_student_id TEXT, p_pin TEXT)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_student students%ROWTYPE;
  v_token   UUID;
BEGIN
  SELECT * INTO v_student
  FROM students
  WHERE school_id = p_school_id AND student_id = p_student_id;

  IF NOT FOUND THEN
    RETURN json_build_object('valid', false, 'reason', 'not_found');
  END IF;

  -- PIN チェック
  IF v_student.pin IS NULL OR v_student.pin = '' THEN
    NULL; -- PIN 未設定はそのまま通過
  ELSIF v_student.pin LIKE '$2a$%' OR v_student.pin LIKE '$2b$%' THEN
    -- bcrypt ハッシュ済み
    IF crypt(p_pin, v_student.pin) <> v_student.pin THEN
      RETURN json_build_object('valid', false, 'reason', 'wrong_pin');
    END IF;
  ELSE
    -- 旧プレーンテキスト（移行期間の後方互換）
    IF v_student.pin <> p_pin THEN
      RETURN json_build_object('valid', false, 'reason', 'wrong_pin');
    END IF;
  END IF;

  -- 期限切れセッションを掃除
  DELETE FROM student_sessions WHERE expires_at < NOW();

  -- セッショントークン発行（24h有効）
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

-- ④ set_student_pin RPC（bcrypt ハッシュ化してから保存）
--    teacher.html から呼び出す。先生の school_id と一致する生徒のみ変更可能。
CREATE OR REPLACE FUNCTION set_student_pin(p_student_uuid UUID, p_pin TEXT)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_school_id TEXT;
BEGIN
  -- 呼び出し元の先生の school_id を取得
  SELECT school_id INTO v_school_id FROM teacher_profiles WHERE id = auth.uid();
  -- 管理者もOK
  IF v_school_id IS NULL THEN
    IF EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid()) THEN
      SELECT school_id INTO v_school_id FROM students WHERE id = p_student_uuid;
    END IF;
  END IF;
  IF v_school_id IS NULL THEN
    RETURN json_build_object('ok', false, 'error', 'unauthorized');
  END IF;

  -- 生徒が同じ学校に属しているか確認
  IF NOT EXISTS (SELECT 1 FROM students WHERE id = p_student_uuid AND school_id = v_school_id) THEN
    RETURN json_build_object('ok', false, 'error', 'student_not_found');
  END IF;

  IF p_pin = '' OR p_pin IS NULL THEN
    -- PIN 削除
    UPDATE students SET pin = '' WHERE id = p_student_uuid;
  ELSE
    -- bcrypt でハッシュ化して保存
    UPDATE students SET pin = crypt(p_pin, gen_salt('bf')) WHERE id = p_student_uuid;
  END IF;

  RETURN json_build_object('ok', true);
END;
$$;
GRANT EXECUTE ON FUNCTION set_student_pin(UUID, TEXT) TO authenticated;

-- ⑤ upsert_student_progress RPC（セッショントークン認証）
--    completed_level / is_completed / yt_speed / memo のいずれかを選択して更新可能
CREATE OR REPLACE FUNCTION upsert_student_progress(
  p_token           UUID,
  p_task_db_id      UUID,
  p_completed_level INT     DEFAULT NULL,
  p_is_completed    BOOLEAN DEFAULT NULL,
  p_yt_speed        TEXT    DEFAULT NULL,
  p_memo            TEXT    DEFAULT NULL
) RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_school_id  TEXT; v_student_id TEXT;
BEGIN
  SELECT school_id, student_id INTO v_school_id, v_student_id
  FROM student_sessions
  WHERE token = p_token AND expires_at > NOW();

  IF NOT FOUND THEN
    RETURN json_build_object('ok', false, 'error', 'invalid_session');
  END IF;

  INSERT INTO student_progress
    (school_id, student_id, task_db_id, completed_level, is_completed, yt_speed, memo, updated_at)
  VALUES
    (v_school_id, v_student_id, p_task_db_id,
     COALESCE(p_completed_level, 0),
     COALESCE(p_is_completed, false),
     COALESCE(p_yt_speed, '1.0'),
     COALESCE(p_memo, ''),
     NOW())
  ON CONFLICT (school_id, student_id, task_db_id) DO UPDATE SET
    completed_level = CASE WHEN p_completed_level IS NOT NULL THEN p_completed_level ELSE student_progress.completed_level END,
    is_completed    = CASE WHEN p_is_completed    IS NOT NULL THEN p_is_completed    ELSE student_progress.is_completed    END,
    yt_speed        = CASE WHEN p_yt_speed        IS NOT NULL THEN p_yt_speed        ELSE student_progress.yt_speed        END,
    memo            = CASE WHEN p_memo            IS NOT NULL THEN p_memo            ELSE student_progress.memo            END,
    updated_at      = NOW();

  RETURN json_build_object('ok', true);
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('ok', false, 'error', SQLERRM);
END;
$$;
GRANT EXECUTE ON FUNCTION upsert_student_progress(UUID, UUID, INT, BOOLEAN, TEXT, TEXT) TO anon;

-- ⑥ log_student_practice RPC（セッショントークン認証）
CREATE OR REPLACE FUNCTION log_student_practice(
  p_token     UUID,
  p_logged_at DATE DEFAULT CURRENT_DATE
) RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_school_id TEXT; v_student_id TEXT;
BEGIN
  SELECT school_id, student_id INTO v_school_id, v_student_id
  FROM student_sessions
  WHERE token = p_token AND expires_at > NOW();

  IF NOT FOUND THEN
    RETURN json_build_object('ok', false, 'error', 'invalid_session');
  END IF;

  INSERT INTO practice_logs (school_id, student_id, logged_at)
  VALUES (v_school_id, v_student_id, p_logged_at)
  ON CONFLICT (school_id, student_id, logged_at) DO NOTHING;

  RETURN json_build_object('ok', true);
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('ok', false, 'error', SQLERRM);
END;
$$;
GRANT EXECUTE ON FUNCTION log_student_practice(UUID, DATE) TO anon;

-- ⑦ save_yt_speed RPC（セッショントークン認証）
CREATE OR REPLACE FUNCTION save_yt_speed(
  p_token      UUID,
  p_task_db_id UUID,
  p_yt_speed   TEXT
) RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_school_id TEXT; v_student_id TEXT;
BEGIN
  SELECT school_id, student_id INTO v_school_id, v_student_id
  FROM student_sessions
  WHERE token = p_token AND expires_at > NOW();

  IF NOT FOUND THEN
    RETURN json_build_object('ok', false, 'error', 'invalid_session');
  END IF;

  UPDATE student_progress
  SET yt_speed = p_yt_speed, updated_at = NOW()
  WHERE school_id = v_school_id AND student_id = v_student_id AND task_db_id = p_task_db_id;

  RETURN json_build_object('ok', true);
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('ok', false, 'error', SQLERRM);
END;
$$;
GRANT EXECUTE ON FUNCTION save_yt_speed(UUID, UUID, TEXT) TO anon;

-- ⑧ student_progress の anon 直接書き込みを廃止（RPC経由のみ）
DROP POLICY IF EXISTS "progress_anon_insert" ON student_progress;
DROP POLICY IF EXISTS "progress_anon_update" ON student_progress;

-- ⑨ student_progress の anon SELECT を有効な school_id のみに制限
DROP POLICY IF EXISTS "progress_anon_select" ON student_progress;
CREATE POLICY "progress_anon_select" ON student_progress FOR SELECT TO anon
  USING (school_id IN (SELECT DISTINCT school_id FROM teacher_profiles));

-- ⑩ practice_logs の anon 直接書き込みを廃止（RPC経由のみ）
DROP POLICY IF EXISTS "practice_logs_anon_insert" ON practice_logs;
DROP POLICY IF EXISTS "practice_logs_anon_update" ON practice_logs;

-- practice_logs の anon SELECT を有効な school_id のみに制限
DROP POLICY IF EXISTS "practice_logs_anon_select" ON practice_logs;
CREATE POLICY "practice_logs_anon_select" ON practice_logs FOR SELECT TO anon
  USING (school_id IN (SELECT DISTINCT school_id FROM teacher_profiles));

-- ⑪ students テーブルの anon アクセスを禁止（個人情報保護）
--    生徒のログイン情報は validate_student_pin RPC 経由のみ取得可能
DROP POLICY IF EXISTS "students_anon_select" ON students;
DROP POLICY IF EXISTS "students_anon_read" ON students;

-- 先生は自分の学校の生徒のみ読み書き可能
DROP POLICY IF EXISTS "students_teacher_rw" ON students;
CREATE POLICY "students_teacher_rw" ON students FOR ALL TO authenticated
  USING (school_id IN (SELECT school_id FROM teacher_profiles WHERE id = auth.uid()))
  WITH CHECK (school_id IN (SELECT school_id FROM teacher_profiles WHERE id = auth.uid()));

-- 管理者はすべての生徒にアクセス可能
DROP POLICY IF EXISTS "students_admin_rw" ON students;
CREATE POLICY "students_admin_rw" ON students FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid()));
