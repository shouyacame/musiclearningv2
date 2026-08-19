-- =====================================================
-- v10: トピックに画像フォルダURL（Googleドライブ等）列を追加
-- Supabase SQL Editor で実行してください（既存データは影響なし）
-- =====================================================

ALTER TABLE study_topics ADD COLUMN IF NOT EXISTS drive_url TEXT DEFAULT '';
