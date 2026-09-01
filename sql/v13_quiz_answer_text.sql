-- =====================================================
-- v13: quiz_answersに生徒の実際の回答テキストを保存する列を追加
-- Supabase SQL Editor で実行してください（既存データは影響なし）
-- =====================================================

ALTER TABLE quiz_answers ADD COLUMN IF NOT EXISTS answer_text TEXT DEFAULT '';
