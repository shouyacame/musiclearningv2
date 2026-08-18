# デフォルトCSVの画像設定方法

## Google Drive 画像を使う手順

1. Google Drive に画像をアップロードする
2. 画像ファイルを右クリック → 「共有」→ **「リンクを知っている全員」が閲覧可能** に設定する
3. 「リンクをコピー」する
   - コピーされるURL例: `https://drive.google.com/file/d/1aBcDeFgHiJkL/view?usp=sharing`
4. CSVの「画像URL」列にそのまま貼り付ける（`?usp=sharing` 以降は不要ですが付いていても動作します）

## アプリでの表示方法

| URLの形式 | 表示方法 |
|-----------|---------|
| `https://drive.google.com/file/d/FILE_ID/view` | iframeプレビュー（PDF・スライドにも対応） |
| `https://drive.google.com/uc?export=view&id=FILE_ID` | 画像として直接表示（`<img>`タグ） |

→ **画像（PNG/JPG）の場合は `/file/d/FILE_ID/view` 形式のままで問題ありません。**

## 各CSVの画像列

### default_content_sansin.csv（基礎知識）
| 見出し | 推奨画像 |
|--------|---------|
| ②各部の名称 | 三線の各部名称を示したイラスト or 写真 |
| ③三味線との違い | 三線と三味線を並べた比較写真 |

### default_quiz_sansin.csv（ワークシート）
| クイズセット名 | 推奨画像 |
|---------------|---------|
| ①各部の名前を答えよう | 各部の名前を伏せた三線のイラスト |
| ①三線と三味線を比べよう | 三線と三味線が並んだ写真 |

## 画像URLの置き換え方

CSVをメモ帳や Excel で開き、以下の空欄（画像URL列）にGoogle DriveのURLを貼り付けてから、teacher.htmlの「基礎知識」or「ワークシート」タブ → 「CSVインポート」で読み込んでください。

⚠️ 画像なしでも問題なく動作します。後からSupabaseダッシュボード上で直接編集も可能です。
