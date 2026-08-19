-- =====================================================
-- v9: ワークシート（quiz_sets）に本文・表サポートを追加
-- Supabase SQL Editor で実行してください（1回だけ）
-- 既存データは影響ありません
-- =====================================================

ALTER TABLE quiz_sets ADD COLUMN IF NOT EXISTS body TEXT DEFAULT '';
