-- v16: 楽曲課題に記述課題フラグを追加
ALTER TABLE song_tasks ADD COLUMN IF NOT EXISTS is_descriptive BOOLEAN DEFAULT FALSE;
