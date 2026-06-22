-- =====================================================
-- 管理者機能セットアップ
-- Supabase SQL Editor で実行してください
-- =====================================================

-- 管理者プロフィールテーブル
CREATE TABLE IF NOT EXISTS admin_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT DEFAULT '管理者',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE admin_profiles ENABLE ROW LEVEL SECURITY;

GRANT ALL ON admin_profiles TO authenticated;

-- 自分のプロフィールのみ参照・更新
CREATE POLICY "admin_select" ON admin_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "admin_update" ON admin_profiles FOR UPDATE USING (auth.uid() = id);

-- 管理者が1人もいない場合のみ初回登録を許可
CREATE POLICY "admin_insert_initial" ON admin_profiles
  FOR INSERT TO authenticated
  WITH CHECK (NOT EXISTS (SELECT 1 FROM admin_profiles));

-- 管理者判定ヘルパー関数
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid());
$$;

-- 先生プロフィール削除: 管理者も削除可能に（既存のtp_deleteポリシーを拡張）
DROP POLICY IF EXISTS "tp_admin_delete" ON teacher_profiles;
CREATE POLICY "tp_admin_delete" ON teacher_profiles
  FOR DELETE TO authenticated USING (auth.uid() = id OR is_admin());
