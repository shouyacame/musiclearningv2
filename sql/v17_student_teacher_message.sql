-- v17: student_progressに先生へのメッセージ欄を追加

-- ① カラム追加
ALTER TABLE student_progress ADD COLUMN IF NOT EXISTS teacher_message TEXT DEFAULT '';

-- ② upsert_student_progress を7パラメータ版に更新
DROP FUNCTION IF EXISTS upsert_student_progress(UUID, UUID, INT, BOOLEAN, TEXT, TEXT);

CREATE OR REPLACE FUNCTION upsert_student_progress(
  p_token           UUID,
  p_task_db_id      UUID,
  p_completed_level INT     DEFAULT NULL,
  p_is_completed    BOOLEAN DEFAULT NULL,
  p_yt_speed        TEXT    DEFAULT NULL,
  p_memo            TEXT    DEFAULT NULL,
  p_teacher_message TEXT    DEFAULT NULL
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
    (school_id, student_id, task_db_id, completed_level, is_completed, yt_speed, memo, teacher_message, updated_at)
  VALUES
    (v_school_id, v_student_id, p_task_db_id,
     COALESCE(p_completed_level, 0),
     COALESCE(p_is_completed, false),
     COALESCE(p_yt_speed, '1.0'),
     COALESCE(p_memo, ''),
     COALESCE(p_teacher_message, ''),
     NOW())
  ON CONFLICT (school_id, student_id, task_db_id) DO UPDATE SET
    completed_level = CASE WHEN p_completed_level IS NOT NULL THEN p_completed_level ELSE student_progress.completed_level END,
    is_completed    = CASE WHEN p_is_completed    IS NOT NULL THEN p_is_completed    ELSE student_progress.is_completed    END,
    yt_speed        = CASE WHEN p_yt_speed        IS NOT NULL THEN p_yt_speed        ELSE student_progress.yt_speed        END,
    memo            = CASE WHEN p_memo            IS NOT NULL THEN p_memo            ELSE student_progress.memo            END,
    teacher_message = CASE WHEN p_teacher_message IS NOT NULL THEN p_teacher_message ELSE student_progress.teacher_message END,
    updated_at      = NOW();

  RETURN json_build_object('ok', true);
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('ok', false, 'error', SQLERRM);
END;
$$;
GRANT EXECUTE ON FUNCTION upsert_student_progress(UUID, UUID, INT, BOOLEAN, TEXT, TEXT, TEXT) TO anon;

-- ③ get_student_progress を更新（teacher_message を追加）
CREATE OR REPLACE FUNCTION get_student_progress(p_token UUID)
RETURNS TABLE(
  task_db_id      UUID,
  is_completed    BOOLEAN,
  memo            TEXT,
  completed_level INT,
  yt_speed        TEXT,
  teacher_message TEXT
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
  SELECT sp.task_db_id, sp.is_completed, sp.memo, sp.completed_level, sp.yt_speed,
         COALESCE(sp.teacher_message, '')
  FROM student_progress sp
  WHERE sp.school_id = v_school_id AND sp.student_id = v_student_id;
END;
$$;
GRANT EXECUTE ON FUNCTION get_student_progress(UUID) TO anon;
