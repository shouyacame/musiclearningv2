-- =====================================================
-- 三線学習システム - 完全リセット版セットアップ
-- Supabase SQL Editor で実行してください
-- ※ 既存データは全て削除されます
-- =====================================================

DROP TABLE IF EXISTS student_progress CASCADE;
DROP TABLE IF EXISTS song_tasks CASCADE;
DROP TABLE IF EXISTS songs CASCADE;
DROP TABLE IF EXISTS koto_tasks CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS announcements CASCADE;
DROP TABLE IF EXISTS teacher_profiles CASCADE;

-- =====================================================
-- テーブル定義
-- =====================================================

CREATE TABLE teacher_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  email TEXT,
  name TEXT,
  school_id TEXT NOT NULL,
  school_name TEXT,
  department TEXT DEFAULT '音楽科',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE classes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id TEXT NOT NULL,
  grade TEXT NOT NULL,
  class_name TEXT NOT NULL,
  max_students INTEGER DEFAULT 40,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, grade, class_name)
);

CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id TEXT NOT NULL,
  student_id TEXT NOT NULL,
  name TEXT DEFAULT '',
  grade TEXT,
  class_name TEXT,
  number INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, student_id)
);

CREATE TABLE koto_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  category TEXT DEFAULT '基礎',
  order_num INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE songs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id TEXT NOT NULL,
  title TEXT NOT NULL,
  artist TEXT DEFAULT '',
  description TEXT DEFAULT '',
  order_num INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE song_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  song_id UUID REFERENCES songs(id) ON DELETE CASCADE,
  school_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  order_num INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE student_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id TEXT NOT NULL,
  student_id TEXT NOT NULL,
  task_db_id UUID NOT NULL,
  task_type TEXT DEFAULT 'koto',
  is_completed BOOLEAN DEFAULT false,
  memo TEXT DEFAULT '',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, student_id, task_db_id)
);

CREATE TABLE announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT DEFAULT '',
  is_active BOOLEAN DEFAULT true,
  is_pinned BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- RLS有効化
-- =====================================================

ALTER TABLE teacher_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE koto_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE songs ENABLE ROW LEVEL SECURITY;
ALTER TABLE song_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 権限付与（GRANTが必要）
-- =====================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated;

GRANT SELECT ON teacher_profiles TO anon;
GRANT ALL ON teacher_profiles TO authenticated;

GRANT SELECT ON classes TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON classes TO authenticated;

GRANT SELECT ON students TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON students TO authenticated;

GRANT SELECT ON koto_tasks TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON koto_tasks TO authenticated;

GRANT SELECT ON songs TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON songs TO authenticated;

GRANT SELECT ON song_tasks TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON song_tasks TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON student_progress TO anon, authenticated;

GRANT SELECT ON announcements TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON announcements TO authenticated;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- =====================================================
-- RLSポリシー
-- =====================================================

-- teacher_profiles: 匿名はSELECTのみ（ユーザーID→メール変換に必要）
CREATE POLICY "tp_select" ON teacher_profiles FOR SELECT USING (true);
CREATE POLICY "tp_insert" ON teacher_profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "tp_update" ON teacher_profiles FOR UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY "tp_delete" ON teacher_profiles FOR DELETE TO authenticated USING (auth.uid() = id);

-- 各テーブル: 全員読み取り、認証済みは書き込み可
CREATE POLICY "classes_select" ON classes FOR SELECT USING (true);
CREATE POLICY "classes_write"  ON classes FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "students_select" ON students FOR SELECT USING (true);
CREATE POLICY "students_write"  ON students FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "koto_select" ON koto_tasks FOR SELECT USING (true);
CREATE POLICY "koto_write"  ON koto_tasks FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "songs_select" ON songs FOR SELECT USING (true);
CREATE POLICY "songs_write"  ON songs FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "song_tasks_select" ON song_tasks FOR SELECT USING (true);
CREATE POLICY "song_tasks_write"  ON song_tasks FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- student_progress: 誰でも読み書き可（生徒が直接更新する）
CREATE POLICY "progress_all" ON student_progress FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "announce_select" ON announcements FOR SELECT USING (true);
CREATE POLICY "announce_write"  ON announcements FOR ALL TO authenticated USING (true) WITH CHECK (true);
