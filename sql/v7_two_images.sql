-- =====================================================
-- v7: 基礎知識セクションに2枚目画像・マークダウン表サポート
-- Supabase SQL Editor または CLI で実行してください
-- =====================================================

-- study_sections に2枚目画像列を追加（既存データは影響なし）
ALTER TABLE study_sections ADD COLUMN IF NOT EXISTS image_url_2     TEXT DEFAULT '';
ALTER TABLE study_sections ADD COLUMN IF NOT EXISTS image_caption_2 TEXT DEFAULT '';
