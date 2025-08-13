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

  // 各質問ごとの絵文字（アイコン代わり）
  static const Map<String, List<String>> optionEmojis = {
    'q1': ['😄', '👀', '⚖️', '💇'],
    'q2': ['🖌️', '✏️', '⬆️', '⬇️'],
    'q3': ['😊', '😌', '😤', '😐'],
    'q4': ['😁', '🙂', '😶', '🤪'],
    'q5': ['⚡', '🌤️', '🧘', '🎭'],
    'q6': ['📅', '🚶', '🏠', '🎧'],
    'q7': ['🚀', '🤝', '📊', '📋'],
    'q8': ['☀️', '🌿', '❄️', '🕶️'],
  };

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

  Color _accent(ColorScheme cs, int i) {
    if (i == 0) return cs.primary;
    if (i == 1) return cs.secondary;
    if (i == 2) return cs.tertiary;
    return Colors.teal; // フォールバック
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = questions.length;
    final q = questions[index];
    final emojis = optionEmojis[q['id']] ?? const ['✨', '✨', '✨', '✨'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Q${index + 1} / $total'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: goPrev, // 戻る
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
              const SizedBox(height: 14),

              // 質問カード（没入感の入口）
              _QuestionCard(text: q['text'] as String),

              const SizedBox(height: 12),

              // 選択肢：カード型 + アイコン + 色
              Expanded(
                child: _OptionsGrid(
                  options: (q['options'] as List<String>),
                  emojis: emojis,
                  selected: selected,
                  onSelect: (i) => setState(() => selected = i),
                  colorFor: (i) => _accent(cs, i),
                ),
              ),

              // 次へ / 結果へ
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selected == null ? null : goNext,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(index == total - 1 ? '結果を見る' : '次へ'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =========================
/// 質問テキストのカード
/// =========================
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          colors: [
            cs.primary.withOpacity(0.10),
            cs.secondary.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.quiz_rounded, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// =========================
/// オプショングリッド（1〜2列）
/// =========================
class _OptionsGrid extends StatelessWidget {
  const _OptionsGrid({
    required this.options,
    required this.emojis,
    required this.selected,
    required this.onSelect,
    required this.colorFor,
  });

  final List<String> options;
  final List<String> emojis;
  final int? selected;
  final ValueChanged<int> onSelect;
  final Color Function(int) colorFor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final isNarrow = w < 360;
        final crossAxisCount = isNarrow ? 1 : 2;

        return GridView.builder(
          padding: const EdgeInsets.only(top: 2, bottom: 8),
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 96, // 高さ固定で安定
          ),
          itemBuilder: (context, i) {
            final isSel = selected == i;
            return _OptionCard(
              label: options[i],
              emoji: emojis[i % emojis.length],
              accent: colorFor(i),
              selected: isSel,
              onTap: () => onSelect(i),
            );
          },
        );
      },
    );
  }
}

/// =========================
/// 単一のオプションカード
/// =========================
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.emoji,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final baseGrad = [accent.withOpacity(0.10), accent.withOpacity(0.06)];

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: selected ? 1.02 : 1.0,
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: const Alignment(-1, -1),
              end: const Alignment(1, 1),
              colors: selected
                  ? [accent.withOpacity(0.18), accent.withOpacity(0.10)]
                  : baseGrad,
            ),
            border: Border.all(
              color: selected ? accent : Colors.white.withOpacity(0.6),
              width: selected ? 1.6 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // ラベル
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  // チェック
                  AnimatedOpacity(
                    opacity: selected ? 1 : 0.0,
                    duration: const Duration(milliseconds: 120),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: accent,
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
