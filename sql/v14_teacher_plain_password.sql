-- =====================================================
-- v14: teacher_profilesにパスワード保管列を追加（管理者画面での確認用）
-- Supabase SQL Editor で実行してください（既存データは影響なし）
-- =====================================================

ALTER TABLE teacher_profiles ADD COLUMN IF NOT EXISTS plain_password TEXT DEFAULT '';
