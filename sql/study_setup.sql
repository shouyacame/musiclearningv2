-- =====================================================
-- 学習コンテンツ・ワークシート機能セットアップ
-- Supabase SQL Editor で実行してください
-- =====================================================

-- 学習トピック (例: 三線の歴史, 楽器の基礎知識)
CREATE TABLE IF NOT EXISTS study_topics (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id  TEXT NOT NULL,
  title      TEXT NOT NULL,
  icon       TEXT DEFAULT '📚',
  topic_type TEXT DEFAULT 'content',  -- 'content'(読み物) | 'quiz'(穴埋め)
  order_num  INTEGER DEFAULT 0,
  is_active  BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- コンテンツセクション (テキスト + 画像)
CREATE TABLE IF NOT EXISTS study_sections (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id       UUID REFERENCES study_topics(id) ON DELETE CASCADE,
  school_id      TEXT NOT NULL,
  title          TEXT NOT NULL,
  body           TEXT DEFAULT '',
  image_url      TEXT DEFAULT '',
  image_caption  TEXT DEFAULT '',
  order_num      INTEGER DEFAULT 0
);

-- クイズセット (画像1枚 + 複数問題)
CREATE TABLE IF NOT EXISTS quiz_sets (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id      UUID REFERENCES study_topics(id) ON DELETE CASCADE,
  school_id     TEXT NOT NULL,
  title         TEXT NOT NULL,
  image_url     TEXT DEFAULT '',
  image_caption TEXT DEFAULT '',
  order_num     INTEGER DEFAULT 0
);

-- クイズ問題 (穴埋め)
CREATE TABLE IF NOT EXISTS quiz_questions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_set_id     UUID REFERENCES quiz_sets(id) ON DELETE CASCADE,
  school_id       TEXT NOT NULL,
  question_text   TEXT NOT NULL,
  correct_answer  TEXT NOT NULL,
  hint            TEXT DEFAULT '',
  order_num       INTEGER DEFAULT 0
);

-- 生徒の回答記録
CREATE TABLE IF NOT EXISTS quiz_answers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   TEXT NOT NULL,
  student_id  TEXT NOT NULL,
  question_id UUID REFERENCES quiz_questions(id) ON DELETE CASCADE,
  is_correct  BOOLEAN DEFAULT false,
  answered_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, student_id, question_id)
);

-- RLS有効化
ALTER TABLE study_topics   ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_sets      ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_answers   ENABLE ROW LEVEL SECURITY;

-- GRANT
GRANT SELECT ON study_topics   TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON study_topics TO authenticated;
GRANT SELECT ON study_sections TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON study_sections TO authenticated;
GRANT SELECT ON quiz_sets      TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON quiz_sets TO authenticated;
GRANT SELECT ON quiz_questions TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON quiz_questions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON quiz_answers TO anon, authenticated;
GRANT DELETE ON quiz_answers TO authenticated;

-- ポリシー
CREATE POLICY "study_topics_select" ON study_topics FOR SELECT USING (true);
CREATE POLICY "study_topics_write"  ON study_topics FOR ALL TO authenticated
  USING (school_id = teacher_school_id()) WITH CHECK (school_id = teacher_school_id());

CREATE POLICY "study_sections_select" ON study_sections FOR SELECT USING (true);
CREATE POLICY "study_sections_write"  ON study_sections FOR ALL TO authenticated
  USING (school_id = teacher_school_id()) WITH CHECK (school_id = teacher_school_id());

CREATE POLICY "quiz_sets_select" ON quiz_sets FOR SELECT USING (true);
CREATE POLICY "quiz_sets_write"  ON quiz_sets FOR ALL TO authenticated
  USING (school_id = teacher_school_id()) WITH CHECK (school_id = teacher_school_id());

CREATE POLICY "quiz_questions_select" ON quiz_questions FOR SELECT USING (true);
CREATE POLICY "quiz_questions_write"  ON quiz_questions FOR ALL TO authenticated
  USING (school_id = teacher_school_id()) WITH CHECK (school_id = teacher_school_id());

CREATE POLICY "quiz_answers_anon_select" ON quiz_answers FOR SELECT TO anon USING (true);
CREATE POLICY "quiz_answers_anon_insert" ON quiz_answers FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "quiz_answers_anon_update" ON quiz_answers FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY "quiz_answers_teacher"     ON quiz_answers FOR ALL TO authenticated
  USING (school_id = teacher_school_id()) WITH CHECK (school_id = teacher_school_id());
