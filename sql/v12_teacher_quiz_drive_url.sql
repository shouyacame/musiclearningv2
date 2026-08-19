-- =====================================================
-- v12: 先生プロフィールにワークシート用画像フォルダURL列を追加
-- Supabase SQL Editor で実行してください（既存データは影響なし）
-- =====================================================

ALTER TABLE teacher_profiles ADD COLUMN IF NOT EXISTS quiz_drive_url TEXT DEFAULT '';
