-- =====================================================
-- 三味線学習システム - Supabase テーブル設定
-- Supabase Dashboard → SQL Editor で実行してください
-- =====================================================

-- クラス設定テーブル（school_settings の代替）
CREATE TABLE IF NOT EXISTS classes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  grade TEXT NOT NULL,           -- '1', '2', '3'
  class_name TEXT NOT NULL,      -- 'A', 'B', 'さくら' など
  max_students INTEGER DEFAULT 40,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(grade, class_name)
);

-- 学年別課題テーブル
CREATE TABLE IF NOT EXISTS koto_tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  grade TEXT NOT NULL,
  task_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  criteria TEXT DEFAULT '',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 曲テーブル（動的管理・ハードコードを廃止）
CREATE TABLE IF NOT EXISTS songs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  song_key TEXT UNIQUE NOT NULL,
  song_name TEXT NOT NULL,
  icon TEXT DEFAULT '🎵',
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 曲別課題テーブル
CREATE TABLE IF NOT EXISTS song_tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  song_key TEXT NOT NULL,
  song_name TEXT NOT NULL,
  task_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  criteria TEXT DEFAULT '',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 生徒名簿テーブル（任意登録）
CREATE TABLE IF NOT EXISTS students (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  grade TEXT NOT NULL,
  class_name TEXT NOT NULL,
  number INTEGER NOT NULL,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(grade, class_name, number)
);

-- 生徒進捗テーブル（LocalStorage の代替・全デバイスから参照可能）
CREATE TABLE IF NOT EXISTS student_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  student_id TEXT NOT NULL,      -- e.g. '1A01'
  task_type TEXT NOT NULL,       -- 'koto' or 'song'
  task_db_id UUID NOT NULL,      -- koto_tasks.id or song_tasks.id
  is_completed BOOLEAN DEFAULT FALSE,
  memo TEXT DEFAULT '',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, task_db_id)
);

-- お知らせテーブル
CREATE TABLE IF NOT EXISTS announcements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT DEFAULT '',
  is_pinned BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 先生プロフィールテーブル（Supabase Auth と連携）
CREATE TABLE IF NOT EXISTS teacher_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '先生',
  department TEXT DEFAULT '音楽科',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 初期データ（曲）
-- =====================================================
INSERT INTO songs (song_key, song_name, icon, sort_order) VALUES
  ('umi_no_koe',          '海の声',     '🌊', 1),
  ('shimanchu_nu_takara', '島人ぬ宝', '🏝️', 2),
  ('namida_sousou',       '涙そうそう', '💧', 3)
ON CONFLICT (song_key) DO NOTHING;

-- =====================================================
-- RLS（行レベルセキュリティ）
-- =====================================================
ALTER TABLE classes          ENABLE ROW LEVEL SECURITY;
ALTER TABLE koto_tasks       ENABLE ROW LEVEL SECURITY;
ALTER TABLE songs            ENABLE ROW LEVEL SECURITY;
ALTER TABLE song_tasks       ENABLE ROW LEVEL SECURITY;
ALTER TABLE students         ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements    ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_profiles ENABLE ROW LEVEL SECURITY;

-- 匿名ユーザー（生徒）: 読み取りのみ
CREATE POLICY "anon_read_classes"       ON classes       FOR SELECT TO anon USING (is_active = true);
CREATE POLICY "anon_read_koto_tasks"    ON koto_tasks    FOR SELECT TO anon USING (is_active = true);
CREATE POLICY "anon_read_songs"         ON songs         FOR SELECT TO anon USING (is_active = true);
CREATE POLICY "anon_read_song_tasks"    ON song_tasks    FOR SELECT TO anon USING (is_active = true);
CREATE POLICY "anon_read_students"      ON students      FOR SELECT TO anon USING (true);
CREATE POLICY "anon_read_announcements" ON announcements FOR SELECT TO anon USING (is_active = true);

-- 匿名ユーザー（生徒）: 進捗の読み書き
CREATE POLICY "anon_all_student_progress" ON student_progress
  FOR ALL TO anon USING (true) WITH CHECK (true);

-- 認証済みユーザー（先生）: すべての操作
CREATE POLICY "auth_all_classes"          ON classes          FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_koto_tasks"       ON koto_tasks       FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_songs"            ON songs            FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_song_tasks"       ON song_tasks       FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_students"         ON students         FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_student_progress" ON student_progress FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_announcements"    ON announcements    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_own_teacher_profile"  ON teacher_profiles
  FOR ALL TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- =====================================================
-- 先生アカウント作成方法
-- =====================================================
-- 1. Supabase Dashboard → Authentication → Users → "Add user"
--    でメールアドレスとパスワードを設定してください
--    （例: yamada@school.local / password123）
--
-- 2. ユーザー作成後、以下のSQLで先生プロフィールを登録:
--    INSERT INTO teacher_profiles (id, name, department)
--    VALUES ('<auth.users の UUID>', '山田先生', '音楽科');
