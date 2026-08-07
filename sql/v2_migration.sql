-- =====================================================
-- v2 マイグレーション
-- Supabase SQL Editor で実行してください
-- =====================================================

-- 達成レベル (koto_tasks)
ALTER TABLE koto_tasks ADD COLUMN IF NOT EXISTS level_count   INTEGER DEFAULT 1;
ALTER TABLE koto_tasks ADD COLUMN IF NOT EXISTS level_1_text  TEXT    DEFAULT '';
ALTER TABLE koto_tasks ADD COLUMN IF NOT EXISTS level_2_text  TEXT    DEFAULT '';
ALTER TABLE koto_tasks ADD COLUMN IF NOT EXISTS level_3_text  TEXT    DEFAULT '';
ALTER TABLE koto_tasks ADD COLUMN IF NOT EXISTS youtube_url   TEXT    DEFAULT '';

-- 達成レベル (song_tasks)
ALTER TABLE song_tasks ADD COLUMN IF NOT EXISTS level_count   INTEGER DEFAULT 1;
ALTER TABLE song_tasks ADD COLUMN IF NOT EXISTS level_1_text  TEXT    DEFAULT '';
ALTER TABLE song_tasks ADD COLUMN IF NOT EXISTS level_2_text  TEXT    DEFAULT '';
ALTER TABLE song_tasks ADD COLUMN IF NOT EXISTS level_3_text  TEXT    DEFAULT '';
ALTER TABLE song_tasks ADD COLUMN IF NOT EXISTS youtube_url   TEXT    DEFAULT '';

-- 達成レベル記録 (student_progress)
ALTER TABLE student_progress ADD COLUMN IF NOT EXISTS completed_level INTEGER DEFAULT 0;

-- ワークシート表示切替 + YouTube (study_sections)
ALTER TABLE study_sections ADD COLUMN IF NOT EXISTS is_visible  BOOLEAN DEFAULT true;
ALTER TABLE study_sections ADD COLUMN IF NOT EXISTS youtube_url TEXT    DEFAULT '';

-- 先生メモ (study_topics)
ALTER TABLE study_topics ADD COLUMN IF NOT EXISTS teacher_memo TEXT DEFAULT '';

-- 正解複数パターン (quiz_questions)
ALTER TABLE quiz_questions ADD COLUMN IF NOT EXISTS alt_answers TEXT DEFAULT '';

-- 楽器種別 (teacher_profiles)
ALTER TABLE teacher_profiles ADD COLUMN IF NOT EXISTS instrument_type TEXT DEFAULT '三線';
