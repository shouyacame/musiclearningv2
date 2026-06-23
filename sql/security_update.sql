-- =====================================================
-- セキュリティ修正パッチ
-- 既存DBに適用する場合は Supabase SQL Editor でこのファイルを実行してください
-- setup.sql を最初から実行する場合はこのファイルは不要です
-- =====================================================

-- ヘルパー関数: 認証済み先生の school_id を返す
CREATE OR REPLACE FUNCTION teacher_school_id()
RETURNS TEXT LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT school_id FROM teacher_profiles WHERE id = auth.uid()
$$;
GRANT EXECUTE ON FUNCTION teacher_school_id() TO authenticated;

-- --------------------------------------------------
-- classes: 書き込みを自校の先生のみに制限
-- --------------------------------------------------
DROP POLICY IF EXISTS "classes_write" ON classes;
CREATE POLICY "classes_write" ON classes FOR ALL TO authenticated
  USING (school_id = teacher_school_id())
  WITH CHECK (school_id = teacher_school_id());

-- --------------------------------------------------
-- students: 認証済みの自校先生のみ読み書き可に変更
-- （生徒画面は students テーブルを直接参照しないため anon アクセス不要）
-- --------------------------------------------------
DROP POLICY IF EXISTS "students_select" ON students;
DROP POLICY IF EXISTS "students_write"  ON students;
CREATE POLICY "students_select" ON students FOR SELECT TO authenticated
  USING (school_id = teacher_school_id());
CREATE POLICY "students_write"  ON students FOR ALL TO authenticated
  USING (school_id = teacher_school_id())
  WITH CHECK (school_id = teacher_school_id());

-- --------------------------------------------------
-- koto_tasks: 書き込みを自校の先生のみに制限
-- --------------------------------------------------
DROP POLICY IF EXISTS "koto_write" ON koto_tasks;
CREATE POLICY "koto_write" ON koto_tasks FOR ALL TO authenticated
  USING (school_id = teacher_school_id())
  WITH CHECK (school_id = teacher_school_id());

-- --------------------------------------------------
-- songs: 書き込みを自校の先生のみに制限
-- --------------------------------------------------
DROP POLICY IF EXISTS "songs_write" ON songs;
CREATE POLICY "songs_write" ON songs FOR ALL TO authenticated
  USING (school_id = teacher_school_id())
  WITH CHECK (school_id = teacher_school_id());

-- --------------------------------------------------
-- song_tasks: 書き込みを自校の先生のみに制限
-- --------------------------------------------------
DROP POLICY IF EXISTS "song_tasks_write" ON song_tasks;
CREATE POLICY "song_tasks_write" ON song_tasks FOR ALL TO authenticated
  USING (school_id = teacher_school_id())
  WITH CHECK (school_id = teacher_school_id());

-- --------------------------------------------------
-- student_progress: 権限を細かく分割
--   anon（生徒）: SELECT/INSERT/UPDATE のみ（DELETE は不要）
--   authenticated（先生）: 自校データのみ読み書き可
-- --------------------------------------------------
DROP POLICY IF EXISTS "progress_all"          ON student_progress;
DROP POLICY IF EXISTS "progress_anon_rw"      ON student_progress;
DROP POLICY IF EXISTS "progress_anon_select"  ON student_progress;
DROP POLICY IF EXISTS "progress_anon_insert"  ON student_progress;
DROP POLICY IF EXISTS "progress_anon_update"  ON student_progress;
DROP POLICY IF EXISTS "progress_teacher"      ON student_progress;

CREATE POLICY "progress_anon_select" ON student_progress FOR SELECT TO anon USING (true);
CREATE POLICY "progress_anon_insert" ON student_progress FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "progress_anon_update" ON student_progress FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY "progress_teacher"     ON student_progress FOR ALL TO authenticated
  USING (school_id = teacher_school_id())
  WITH CHECK (school_id = teacher_school_id());

-- --------------------------------------------------
-- announcements: 書き込みを自校の先生のみに制限
-- --------------------------------------------------
DROP POLICY IF EXISTS "announce_write" ON announcements;
CREATE POLICY "announce_write" ON announcements FOR ALL TO authenticated
  USING (school_id = teacher_school_id())
  WITH CHECK (school_id = teacher_school_id());
