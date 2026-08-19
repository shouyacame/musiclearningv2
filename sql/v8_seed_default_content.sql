-- =====================================================
-- v8: デフォルトコンテンツ一括投入関数
-- Supabase SQL Editor で実行してください（1回だけ）
-- 実行後は admin.html から学校を選んでボタン一発で適用できます
-- =====================================================

CREATE OR REPLACE FUNCTION seed_default_content(p_school_id TEXT)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_topic  UUID;
  v_set1   UUID;
  v_set2   UUID;
  v_set3   UUID;
  v_set4   UUID;
  v_max_order INT;
BEGIN

  -- ============================================================
  --  基礎知識①: 三線の基礎知識
  -- ============================================================
  IF NOT EXISTS (SELECT 1 FROM study_topics WHERE school_id = p_school_id AND title = '三線の基礎知識') THEN
    SELECT COALESCE(MAX(order_num),0) INTO v_max_order FROM study_topics WHERE school_id = p_school_id AND topic_type = 'content';
    INSERT INTO study_topics (school_id, title, icon, topic_type, order_num, is_active)
    VALUES (p_school_id, '三線の基礎知識', '📚', 'content', v_max_order+1, true)
    RETURNING id INTO v_topic;

    INSERT INTO study_sections (topic_id, school_id, title, body, order_num, is_visible) VALUES
    (v_topic, p_school_id, '①三線とは',
     '三線（さんしん）は沖縄・奄美地方の伝統的な弦楽器です。3本の弦を「爪（つめ）」ではじいて演奏します。蛇皮が張られた丸い胴と細長い棹が特徴で、沖縄音楽には欠かせない楽器です。',
     1, true),
    (v_topic, p_school_id, '②各部の名称',
     '三線は主に次の部品からできています。
【チーガ】蛇皮を張った丸い胴の部分。音を響かせます。
【棹（さお）】弦を張る細長い部分。
【カラクイ（絲巻）】弦の張り具合（音の高さ）を調整するペグ。
【爪（つめ）】人差し指に付けて弦をはじく道具。水牛の骨などでできています。
【絃（いとぅ）】3本の弦。太い順に男絃・中絃・女絃と呼びます。',
     2, true),
    (v_topic, p_school_id, '③三味線との違い',
     '三線は沖縄・琉球で発展し、三味線は日本本土で発展しました。

| 項目 | 三線 | 三味線 |
| 広まった地域 | 沖縄・琉球 | **日本本土** |
| 皮 | 蛇皮が伝統的 | 猫皮や犬皮が伝統的 |
| 音の感じ | やわらかい、あたたかみがある | はっきりしている、するどさがある |

三味線は、三線が日本本土に伝わったあとに広まった楽器です。伝わった場所がちがうので、形や材料、音の感じにちがいが生まれました。',
     3, true),
    (v_topic, p_school_id, '④爪と弦について',
     '| 弦の名前 | 太さ | 音の高さ |
| 男絃（うーじる） | 太い | 低い |
| 中絃（なかじる） | 中くらい | 中くらい |
| 女絃（みーじる） | 細い | 高い |

爪は人差し指の第一関節と第二関節の間にはめ、角の部分で弦をはじきます。',
     4, true);
  END IF;

  -- ============================================================
  --  基礎知識②: 三線の歴史
  -- ============================================================
  IF NOT EXISTS (SELECT 1 FROM study_topics WHERE school_id = p_school_id AND title = '三線の歴史') THEN
    SELECT COALESCE(MAX(order_num),0) INTO v_max_order FROM study_topics WHERE school_id = p_school_id AND topic_type = 'content';
    INSERT INTO study_topics (school_id, title, icon, topic_type, order_num, is_active)
    VALUES (p_school_id, '三線の歴史', '🎵', 'content', v_max_order+1, true)
    RETURNING id INTO v_topic;

    INSERT INTO study_sections (topic_id, school_id, title, body, order_num, is_visible) VALUES
    (v_topic, p_school_id, '①起源と伝来',
     '三線のルーツは、中国の「三弦（さんげん）」といわれています。14〜15世紀ごろ、琉球（現在の沖縄）に伝わり、琉球独自のスタイルに発展しました。

琉球王国では、三線は宮廷（御座楽）から一般の民衆の音楽まで幅広く使われ、沖縄文化の象徴的な楽器になりました。',
     1, true),
    (v_topic, p_school_id, '②琉球音楽への発展',
     '| ジャンル | 特徴 |
| 古典音楽 | 宮廷で演奏された格式高い音楽。組踊などに使われる。 |
| 民謡 | 「安里屋ユンタ」「花」など庶民の歌。 |
| 現代音楽 | 「島唄」「島人ぬ宝」などポップスにも使われる。 |

現在も沖縄・奄美地方で広く親しまれており、学校教育でも取り入れられています。',
     2, true);
  END IF;

  -- ============================================================
  --  ワークシート①: 各部の名称
  -- ============================================================
  IF NOT EXISTS (SELECT 1 FROM study_topics WHERE school_id = p_school_id AND title = '各部の名称') THEN
    SELECT COALESCE(MAX(order_num),0) INTO v_max_order FROM study_topics WHERE school_id = p_school_id AND topic_type = 'quiz';
    INSERT INTO study_topics (school_id, title, icon, topic_type, order_num, is_active)
    VALUES (p_school_id, '各部の名称', '🎵', 'quiz', v_max_order+1, true)
    RETURNING id INTO v_topic;

    -- セット①
    INSERT INTO quiz_sets (topic_id, school_id, title, order_num)
    VALUES (v_topic, p_school_id, '①各部の名前を答えよう', 1) RETURNING id INTO v_set1;
    INSERT INTO quiz_questions (quiz_set_id, school_id, question_text, correct_answer, alt_answers, hint, order_num) VALUES
    (v_set1, p_school_id, '弦の張りを調整するための部品', 'カラクイ', 'からくい', 'ペグとも呼ばれる', 1),
    (v_set1, p_school_id, '蛇皮が張られた丸い胴の部分', 'チーガ', 'ちーが', '音を響かせる役割がある', 2),
    (v_set1, p_school_id, '演奏するときに人差し指に付ける道具', '爪（つめ）', 'つめ', '水牛の骨などでできている', 3),
    (v_set1, p_school_id, '三線の弦を張る細長い部分', '棹（さお）', 'さお', 'ネックとも呼ばれる', 4);

    -- セット②
    INSERT INTO quiz_sets (topic_id, school_id, title, order_num)
    VALUES (v_topic, p_school_id, '②三線の弦について', 2) RETURNING id INTO v_set2;
    INSERT INTO quiz_questions (quiz_set_id, school_id, question_text, correct_answer, alt_answers, hint, order_num) VALUES
    (v_set2, p_school_id, '三線の弦は何本あるか', '3', '三', '3本の弦で演奏する', 1),
    (v_set2, p_school_id, '3本の弦のうち一番太い弦の名前', '男絃（うーじる）', 'うーじる', '低い音が出る弦', 2),
    (v_set2, p_school_id, '3本の弦のうち一番細い弦の名前', '女絃（みーじる）', 'みーじる', '高い音が出る弦', 3);
  END IF;

  -- ============================================================
  --  ワークシート②: 三味線との違い
  -- ============================================================
  IF NOT EXISTS (SELECT 1 FROM study_topics WHERE school_id = p_school_id AND title = '三味線との違い') THEN
    SELECT COALESCE(MAX(order_num),0) INTO v_max_order FROM study_topics WHERE school_id = p_school_id AND topic_type = 'quiz';
    INSERT INTO study_topics (school_id, title, icon, topic_type, order_num, is_active)
    VALUES (p_school_id, '三味線との違い', '📝', 'quiz', v_max_order+1, true)
    RETURNING id INTO v_topic;

    -- セット①
    INSERT INTO quiz_sets (topic_id, school_id, title, order_num)
    VALUES (v_topic, p_school_id, '①三線と三味線を比べよう', 1) RETURNING id INTO v_set3;
    INSERT INTO quiz_questions (quiz_set_id, school_id, question_text, correct_answer, alt_answers, hint, order_num) VALUES
    (v_set3, p_school_id, '三線が主に発展した地域', '沖縄', '琉球', '沖縄・奄美地方で広まった', 1),
    (v_set3, p_school_id, '三味線が主に発展した地域', '日本本土', '本土', '本州・四国・九州', 2),
    (v_set3, p_school_id, '三線の胴に張られている伝統的な素材', '蛇皮', 'じゃひ', 'ハブなどの皮が使われる', 3),
    (v_set3, p_school_id, '三味線の胴に張られている伝統的な素材', '猫皮', 'ねこかわ', '猫または犬の皮が使われる', 4);

    -- セット②
    INSERT INTO quiz_sets (topic_id, school_id, title, order_num)
    VALUES (v_topic, p_school_id, '②音の感じの違い', 2) RETURNING id INTO v_set4;
    INSERT INTO quiz_questions (quiz_set_id, school_id, question_text, correct_answer, alt_answers, hint, order_num) VALUES
    (v_set4, p_school_id, '三線の音の感じとして正しいもの', 'やわらかい', 'あたたかみがある', '沖縄の風土を表した音色', 1),
    (v_set4, p_school_id, '三味線の音の感じとして正しいもの', 'するどい', 'はっきりしている', '三味線は「さわり」という独特の響きがある', 2);
  END IF;

  RETURN json_build_object('ok', true);
END;
$$;

-- 管理者のみ実行可能
GRANT EXECUTE ON FUNCTION seed_default_content(TEXT) TO authenticated;
