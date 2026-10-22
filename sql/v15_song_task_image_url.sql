-- v15: song_tasksに画像URLカラムを追加
ALTER TABLE song_tasks ADD COLUMN IF NOT EXISTS image_url TEXT DEFAULT '';
