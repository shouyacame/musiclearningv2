-- =====================================================
-- v3 マイグレーション
-- Supabase SQL Editor で実行してください
-- =====================================================

-- ① 練習ログ
CREATE TABLE IF NOT EXISTS practice_logs (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id  TEXT NOT NULL,
  student_id TEXT NOT NULL,
  logged_at  DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, student_id, logged_at)
);
ALTER TABLE practice_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "practice_logs_all" ON practice_logs;
CREATE POLICY "practice_logs_all" ON practice_logs FOR ALL USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON practice_logs TO anon, authenticated;

-- ② 先生フィードバック
CREATE TABLE IF NOT EXISTS teacher_feedback (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id  TEXT NOT NULL,
  student_id TEXT NOT NULL,
  task_db_id UUID NOT NULL,
  comment    TEXT DEFAULT '',
  teacher_id UUID,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, student_id, task_db_id)
);
ALTER TABLE teacher_feedback ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "teacher_feedback_all" ON teacher_feedback;
CREATE POLICY "teacher_feedback_all" ON teacher_feedback FOR ALL USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON teacher_feedback TO anon, authenticated;

-- ③ YouTube再生速度メモ
ALTER TABLE student_progress ADD COLUMN IF NOT EXISTS yt_speed TEXT DEFAULT '1.0';

-- ④ クラス達成率 RPC（生徒画面から呼び出し）
CREATE OR REPLACE FUNCTION class_completion_stats(p_school_id TEXT, p_grade TEXT, p_class TEXT)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_total_students BIGINT;
  v_total_tasks    BIGINT;
  v_completed      BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total_students
  FROM students
  WHERE school_id = p_school_id AND grade = p_grade AND class_name = p_class;

  SELECT COUNT(*) INTO v_total_tasks
  FROM koto_tasks
  WHERE school_id = p_school_id AND is_active = true;

  SELECT COUNT(*) INTO v_completed
  FROM student_progress
  WHERE school_id = p_school_id
    AND student_id LIKE p_grade || p_class || '%'
    AND is_completed = true
    AND task_db_id IN (
      SELECT id FROM koto_tasks WHERE school_id = p_school_id AND is_active = true
    );

  RETURN json_build_object(
    'total_students', v_total_students,
    'total_tasks',    v_total_tasks,
    'completed',      v_completed,
    'rate', CASE WHEN v_total_students * v_total_tasks > 0
            THEN ROUND(v_completed::numeric / (v_total_students * v_total_tasks) * 100)
            ELSE 0 END
  );
END;
$$;
GRANT EXECUTE ON FUNCTION class_completion_stats(TEXT, TEXT, TEXT) TO anon, authenticated;
