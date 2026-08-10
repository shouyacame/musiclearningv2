-- =====================================================
-- v4 セキュリティ強化 + 管理者機能拡張
-- Supabase SQL Editor で実行してください
-- =====================================================

-- ① 生徒PINカラム追加
ALTER TABLE students ADD COLUMN IF NOT EXISTS pin TEXT DEFAULT '';

-- ② システム設定テーブル（メンテナンスモード等）
CREATE TABLE IF NOT EXISTS system_settings (
  key        TEXT PRIMARY KEY,
  value      TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "sys_settings_read"  ON system_settings;
DROP POLICY IF EXISTS "sys_settings_write" ON system_settings;
CREATE POLICY "sys_settings_read"  ON system_settings FOR SELECT USING (true);
CREATE POLICY "sys_settings_write" ON system_settings FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT ON system_settings TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON system_settings TO authenticated;

-- 初期値
INSERT INTO system_settings (key, value) VALUES ('maintenance_mode', 'false') ON CONFLICT (key) DO NOTHING;

-- ③ 先生操作ログテーブル
CREATE TABLE IF NOT EXISTS teacher_activity_log (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  teacher_id UUID,
  school_id  TEXT,
  action     TEXT,
  detail     TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE teacher_activity_log ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "activity_log_auth" ON teacher_activity_log;
CREATE POLICY "activity_log_auth" ON teacher_activity_log FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT ON teacher_activity_log TO authenticated;

-- ④ student_progress RLS 修正（anon: INSERT/UPDATE は school_id が存在する値のみ許可）
DROP POLICY IF EXISTS "progress_anon_insert" ON student_progress;
DROP POLICY IF EXISTS "progress_anon_update" ON student_progress;

CREATE POLICY "progress_anon_insert" ON student_progress
  FOR INSERT TO anon
  WITH CHECK (
    school_id IN (SELECT DISTINCT school_id FROM teacher_profiles)
  );

CREATE POLICY "progress_anon_update" ON student_progress
  FOR UPDATE TO anon
  USING (
    school_id IN (SELECT DISTINCT school_id FROM teacher_profiles)
  )
  WITH CHECK (
    school_id IN (SELECT DISTINCT school_id FROM teacher_profiles)
  );

-- ⑤ practice_logs RLS 修正
DROP POLICY IF EXISTS "practice_logs_all" ON practice_logs;
CREATE POLICY "practice_logs_anon_select" ON practice_logs FOR SELECT TO anon USING (true);
CREATE POLICY "practice_logs_anon_insert" ON practice_logs FOR INSERT TO anon
  WITH CHECK (school_id IN (SELECT DISTINCT school_id FROM teacher_profiles));
CREATE POLICY "practice_logs_anon_update" ON practice_logs FOR UPDATE TO anon
  USING (school_id IN (SELECT DISTINCT school_id FROM teacher_profiles))
  WITH CHECK (school_id IN (SELECT DISTINCT school_id FROM teacher_profiles));
CREATE POLICY "practice_logs_teacher" ON practice_logs FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ⑥ teacher_feedback RLS 修正
DROP POLICY IF EXISTS "teacher_feedback_all" ON teacher_feedback;
CREATE POLICY "teacher_feedback_anon_select" ON teacher_feedback FOR SELECT TO anon USING (true);
CREATE POLICY "teacher_feedback_teacher" ON teacher_feedback FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ⑦ 生徒PINログインRPC
CREATE OR REPLACE FUNCTION validate_student_pin(p_school_id TEXT, p_student_id TEXT, p_pin TEXT)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_student students%ROWTYPE;
BEGIN
  SELECT * INTO v_student
  FROM students
  WHERE school_id = p_school_id AND student_id = p_student_id;

  IF NOT FOUND THEN
    RETURN json_build_object('valid', false, 'reason', 'not_found');
  END IF;

  -- PINが未設定（空文字 or NULL）の場合はPINなしでログイン可
  IF v_student.pin IS NULL OR v_student.pin = '' THEN
    RETURN json_build_object('valid', true, 'pin_required', false,
      'name', v_student.name, 'grade', v_student.grade,
      'class_name', v_student.class_name, 'number', v_student.number);
  END IF;

  -- PIN設定済みの場合は一致チェック
  IF v_student.pin = p_pin THEN
    RETURN json_build_object('valid', true, 'pin_required', true,
      'name', v_student.name, 'grade', v_student.grade,
      'class_name', v_student.class_name, 'number', v_student.number);
  END IF;

  RETURN json_build_object('valid', false, 'reason', 'wrong_pin');
END;
$$;
GRANT EXECUTE ON FUNCTION validate_student_pin(TEXT, TEXT, TEXT) TO anon;

-- ⑧ 全学校統計RPC（管理者用）
CREATE OR REPLACE FUNCTION admin_school_stats()
RETURNS TABLE(
  school_id      TEXT,
  teacher_count  BIGINT,
  student_count  BIGINT,
  task_count     BIGINT,
  completed_count BIGINT,
  practice_days  BIGINT,
  last_activity  TIMESTAMPTZ
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    tp.school_id,
    COUNT(DISTINCT tp.id)                            AS teacher_count,
    COUNT(DISTINCT s.id)                             AS student_count,
    COUNT(DISTINCT kt.id)                            AS task_count,
    COUNT(DISTINCT CASE WHEN sp.is_completed THEN sp.id END) AS completed_count,
    COUNT(DISTINCT pl.id)                            AS practice_days,
    MAX(sp.updated_at)                               AS last_activity
  FROM teacher_profiles tp
  LEFT JOIN students      s  ON s.school_id  = tp.school_id
  LEFT JOIN koto_tasks    kt ON kt.school_id = tp.school_id AND kt.is_active = true
  LEFT JOIN student_progress sp ON sp.school_id = tp.school_id
  LEFT JOIN practice_logs pl ON pl.school_id = tp.school_id
  GROUP BY tp.school_id;
$$;
GRANT EXECUTE ON FUNCTION admin_school_stats() TO authenticated;

-- ⑨ メンテナンスモード取得RPC（anon用）
CREATE OR REPLACE FUNCTION get_maintenance_mode()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT value = 'true' FROM system_settings WHERE key = 'maintenance_mode';
$$;
GRANT EXECUTE ON FUNCTION get_maintenance_mode() TO anon, authenticated;
