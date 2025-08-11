// lib/features/questions/questions_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_routes.dart';
import '../../state/app_state.dart';

class QuestionsPage extends ConsumerStatefulWidget {
  const QuestionsPage({super.key});
  @override
  ConsumerState<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends ConsumerState<QuestionsPage> {
  // 診断質問（8問）
  final questions = const [
    {
      'id': 'q1',
      'text': '鏡を見たとき、最初に目が行くのは？',
      'options': ['口元（笑顔や口角）', '目（形や光り方）', '全体のバランス', '髪型や輪郭'],
    },
    {
      'id': 'q2',
      'text': '普段の眉の形は？',
      'options': ['太くて存在感ある', '細めで繊細', '上がり気味（ツリ眉）', '下がり気味（タレ眉）'],
    },
    {
      'id': 'q3',
      'text': '無意識にしてる表情は？',
      'options': ['口角が上がってる', '目が細くなってる', '眉間にシワ寄ってる', 'ほぼ無表情'],
    },
    {
      'id': 'q4',
      'text': '写真を撮るときの顔は？',
      'options': ['歯を見せて笑う', '軽いスマイル', '真顔でキメる', '変顔やポーズで遊ぶ'],
    },
    {
      'id': 'q5',
      'text': '初対面の人と話すときのテンションは？',
      'options': ['最初からハイテンション', '様子を見て徐々に上げる', '基本落ち着きモード', '相手次第で変える'],
    },
    {
      'id': 'q6',
      'text': '休日の理想は？',
      'options': ['予定ギチギチで遊ぶ', '気分で外出', '家でのんびり', '趣味や作業に没頭'],
    },
    {
      'id': 'q7',
      'text': '物事を決めるときの基準は？',
      'options': ['勢いと直感', '人の気持ち', '数字や事実', 'ルールや計画'],
    },
    {
      'id': 'q8',
      'text': '周囲からよく言われる第一印象は？',
      'options': ['明るい / 元気', '優しそう / 癒し系', 'クール / 落ち着いてる', 'ミステリアス / 近寄りがたい'],
    },
  ];

  int index = 0;
  int? selected; // 0~3（配列index）

  void saveAnswer() {
    final id = questions[index]['id'] as String;
    final map = {...ref.read(answersProvider)};
    map[id] = selected;
    ref.read(answersProvider.notifier).state = map;
  }

  void goNext() {
    if (selected == null) return;
    saveAnswer();

    final total = questions.length;
    final nextIndex = index + 1;

    if (nextIndex >= total) {
      Navigator.pushNamed(context, AppRoutes.result);
      return;
    }

    setState(() {
      index = nextIndex;
      final nextId = questions[index]['id'] as String;
      selected = ref.read(answersProvider)[nextId] as int?;
    });
  }

  void goPrev() {
    if (index == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      index--;
      final prevId = questions[index]['id'] as String;
      selected = ref.read(answersProvider)[prevId] as int?;
    });
  }

  @override
  void initState() {
    super.initState();
    // 初期表示時に保存済み回答があれば復元
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = questions[index]['id'] as String;
      setState(() {
        selected = ref.read(answersProvider)[id] as int?;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = questions.length;
    final q = questions[index];

    return Scaffold(
      appBar: AppBar(
        title: Text('${index + 1}/$total'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: goPrev, // 戻る
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // プログレスバー（テーマカラー）
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (index + 1) / total,
                color: cs.primary,
                backgroundColor: cs.primary.withOpacity(0.15),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),

            // 質問カード
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withOpacity(0.15)),
              ),
              child: Text(
                q['text'] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ラジオの色をテーマに合わせる
            RadioTheme(
              data: RadioThemeData(
                fillColor: WidgetStateProperty.resolveWith(
                  (states) => cs.primary,
                ),
              ),
              child: ListTileTheme(
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  children: (q['options'] as List<String>).asMap().entries.map((
                    entry,
                  ) {
                    final optIndex = entry.key;
                    final optText = entry.value;
                    final isSelected = selected == optIndex;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? cs.primary
                              : cs.primary.withOpacity(0.12),
                        ),
                        color: isSelected
                            ? cs.primary.withOpacity(0.08)
                            : Colors.transparent,
                      ),
                      child: RadioListTile<int>(
                        value: optIndex,
                        groupValue: selected,
                        onChanged: (val) => setState(() => selected = val),
                        title: Text(optText),
                        // Material3での見た目を詰める
                        controlAffinity: ListTileControlAffinity.trailing,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const Spacer(),

            // 次へ / 結果へ
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: selected == null ? null : goNext,
                child: Text(index == total - 1 ? '結果を見る' : '次へ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
