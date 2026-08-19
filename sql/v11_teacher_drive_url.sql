-- =====================================================
-- v11: 先生プロフィールに画像フォルダURL（メモ）列を追加
-- Supabase SQL Editor で実行してください（既存データは影響なし）
-- =====================================================

ALTER TABLE teacher_profiles ADD COLUMN IF NOT EXISTS image_drive_url TEXT DEFAULT '';
