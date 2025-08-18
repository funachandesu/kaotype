// lib/features/result/result_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api_client.dart';
import '../../state/app_state.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final useMock = ref.watch(useMockProvider);
  return ApiClient(
    baseUrl: 'https://kaotype-api.nakayoshitalk.workers.dev',
    useMock: useMock,
  );
});

class ResultPage extends ConsumerStatefulWidget {
  const ResultPage({super.key});
  @override
  ConsumerState<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends ConsumerState<ResultPage> {
  bool loading = false;
  String? error;

  final GlobalKey _captureKey = GlobalKey();

  // 演出用
  int _countdown = 0; // 0で非表示、3→2→1→0
  bool _blast = false; // 決定時のきらめき

  Future<void> fetchResult() async {
    final localFrontPath = ref.read(selectedImagePathProvider);
    final localSidePath = ref.read(selectedSideImagePathProvider);
    final frontBytes = ref.read(selectedImageBytesProvider);
    final sideBytes = ref.read(selectedSideImageBytesProvider);
    final answersMap = ref.read(answersProvider);

    if ((frontBytes == null && localFrontPath == null) || answersMap.isEmpty) {
      setState(() => error = '入力が不足しています');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final api = ref.read(apiClientProvider);

      // 1) 画像アップロード（未アップ済みなら）
      var uploadedFront = ref.read(uploadedFrontImagePathProvider);
      var uploadedSide = ref.read(uploadedSideImagePathProvider);

      if (uploadedFront == null) {
        if (frontBytes != null) {
          final up = await api.uploadImageBytes(
            frontImageBytes: frontBytes,
            sideImageBytes: sideBytes,
            frontFileName: 'front.jpg',
            sideFileName: 'side.jpg',
          );
          uploadedFront = up.frontPath;
          uploadedSide = up.sidePath;
        } else {
          final up = await api.uploadImage(
            frontImagePath: localFrontPath!,
            sideImagePath: localSidePath,
          );
          uploadedFront = up.frontPath;
          uploadedSide = up.sidePath;
        }
        ref.read(uploadedFrontImagePathProvider.notifier).state = uploadedFront;
        ref.read(uploadedSideImagePathProvider.notifier).state = uploadedSide;
      }

      // 2) 回答を A/B/C/D 文字に変換
      String toLetter(int idx) => ['A', 'B', 'C', 'D'][idx];
      final answersList = answersMap.entries
          .map((e) => {'id': e.key, 'user_answer': toLetter(e.value as int)})
          .toList();

      // 3) 診断実行
      final res = await api.analyzeAnswers(
        answers: List<Map<String, String>>.from(answersList),
        front_image_path: uploadedFront!,
        side_image_path: uploadedSide,
      );

      ref.read(analyzeResultProvider.notifier).state = res;

      // 4) カウントダウン演出開始
      if (!mounted) return;
      _startCountdown();
    } catch (e) {
      setState(() => error = 'エラー: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _startCountdown() async {
    setState(() => _countdown = 3);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _countdown = 2);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _countdown = 1);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _countdown = 0);
    // きらめき（短時間）
    setState(() => _blast = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _blast = false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchResult());
  }

  Future<void> _shareCapture({required String targetLabel}) async {
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('キャプチャの準備ができていません')));
        return;
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('キャプチャに失敗しました');
      final pngBytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kaotype_result.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: 'kaotype_result.png')],
        text: '私のカオタイプ診断結果 #カオタイプ16\nhttps://kao-type.com で診断する！',
        subject: 'カオタイプ診断 結果',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('共有に失敗しました: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(analyzeResultProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('診断結果')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(child: Text(error!))
            : res == null
            ? const Center(child: Text('結果がありません'))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final content = SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 16,
                      ),
                      child: Column(
                        children: [
                          // ===== 共有用キャプチャ領域 =====
                          RepaintBoundary(
                            key: _captureKey,
                            child: _ResultCard(res: res),
                          ),
                          const SizedBox(height: 16),

                          // ===== SNSシェア導線（目立つ） =====
                          Row(
                            children: [
                              if (!kIsWeb)
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () =>
                                        _shareCapture(targetLabel: 'LINE'),
                                    icon: const Icon(Icons.send),
                                    label: const Text('結果を共有する'),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // 再診断
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.popUntil(context, (r) => r.isFirst),
                              child: const Text('もう一度診断する'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  // カウントダウンやスパークはStackでオーバーレイ
                  return Stack(
                    children: [
                      // 本体（カウントダウン中はわずかに縮小・暗転）
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _countdown > 0 ? 0.6 : 1,
                        child: AnimatedScale(
                          scale: _countdown > 0 ? 0.98 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: content,
                        ),
                      ),

                      if (_countdown > 0) _CountdownOverlay(number: _countdown),

                      if (_blast) const _SparkOverlay(),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

/// =====================================================
/// 結果カード（スクショ映え）
/// =====================================================
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.res});
  final AnalyzeResult res;

  Color _accentFromType(ColorScheme cs, String t) {
    final ch = (t.isNotEmpty ? t[0] : 'S').toUpperCase();
    switch (ch) {
      case 'K':
        return cs.secondary;
      case 'S':
        return cs.primary;
      default:
        return cs.tertiary;
    }
  }

  String _flipType(String type) {
    const map = {
      'S': 'K',
      'K': 'S',
      'M': 'P',
      'P': 'M',
      'H': 'L',
      'L': 'H',
      'A': 'C',
      'C': 'A',
    };
    final up = type.toUpperCase();
    return up.split('').map((c) => map[c] ?? c).join();
  }

  Map<String, double> _axisScores(String type) {
    // S/K, M/P, H/L, A/C の4軸。タイプ文字で 78/22 の強弱をつける。
    final up = type.toUpperCase().padRight(4, 'A');
    double v(String left, String right, int i) =>
        up[i] == left ? 0.78 : (up[i] == right ? 0.22 : 0.50);
    return {
      'S↔K': v('S', 'K', 0),
      'M↔P': v('M', 'P', 1),
      'H↔L': v('H', 'L', 2),
      'A↔C': v('A', 'C', 3),
    };
  }

  List<String> _strengths(String type) {
    // シンプルな擬似割当（スクショ用の見栄え重視）
    final up = type.toUpperCase();
    return [
      if (up.contains('S')) '親しみやすさ',
      if (up.contains('K')) 'クールな安定感',
      if (up.contains('M')) '瞬発力・ノリ',
      if (up.contains('P')) '丁寧さ・配慮',
      if (up.contains('H')) '存在感・メリハリ',
      if (up.contains('L')) '落ち着き',
      if (up.contains('A')) '行動力',
      if (up.contains('C')) '計画性',
    ];
  }

  List<String> _weakness(String type) {
    final up = type.toUpperCase();
    return [
      if (up.contains('S')) '優柔不断になりがち',
      if (up.contains('K')) '感情が伝わりにくい',
      if (up.contains('M')) 'その場の勢いで動く',
      if (up.contains('P')) '決断が遅れることも',
      if (up.contains('H')) '強めに見られがち',
      if (up.contains('L')) '地味見えすることも',
      if (up.contains('A')) '突っ走りがち',
      if (up.contains('C')) '柔軟性に欠けることも',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _accentFromType(cs, res.type);
    final flipped = _flipType(res.type);
    final scores = _axisScores(res.type);

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) {
            final double imageSide = math.min(c.maxWidth, 520);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // タイトル帯（タイプ4文字バッジ）
                _TypeBadge(code: res.type, label: res.label, accent: accent),

                const SizedBox(height: 12),

                // メイン画像
                Center(
                  child: SizedBox(
                    width: imageSide,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _ResultImage(type: res.type),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 説明（リッチ）
                _SectionHeader(title: '概要'),
                const SizedBox(height: 6),
                Text(res.description),

                const SizedBox(height: 16),

                // 4軸チャート（バー）
                _SectionHeader(title: 'タイプチャート'),
                const SizedBox(height: 8),
                ...scores.entries.map(
                  (e) => _DualBar(label: e.key, valueLeft: e.value),
                ),

                const SizedBox(height: 16),

                // 強み・弱み
                Row(
                  children: [
                    Expanded(
                      child: _BulletCard(
                        title: '強み',
                        accent: accent,
                        bullets: _strengths(res.type).take(4).toList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BulletCard(
                        title: '弱み',
                        accent: cs.error,
                        bullets: _weakness(res.type).take(4).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // アドバイス
                _AdviceCard(
                  accent: accent,
                  tips: const [
                    '写真は「光」を味方に。明るい正面＋少し斜めで雰囲気UP',
                    '表情は口角と目のどちらかを主役にして統一感を出す',
                    'ファッションは色数を絞ってコントラストを作ると映える',
                  ],
                ),

                const SizedBox(height: 16),

                // 相性
                _SectionHeader(title: '相性'),
                const SizedBox(height: 8),
                _CompatibilityRow(
                  good: [
                    flipped,
                    '${flipped[0]}${res.type.substring(1)}',
                    '${res.type[0]}${flipped.substring(1)}',
                  ],
                  caution: [
                    res.type,
                    '${res.type.substring(0, 2)}${flipped.substring(2)}',
                  ],
                  accent: accent,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 共有用画像
class _ResultImage extends StatelessWidget {
  const _ResultImage({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Image.asset(_getImagePath(type), fit: BoxFit.cover);
  }
}

/// タイプ4文字の目立つバッジ
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.code,
    required this.label,
    required this.accent,
  });
  final String code;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          colors: [accent.withOpacity(0.15), accent.withOpacity(0.05)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          // 4文字を大きく
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              code.toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'あなたの顔×性格タイプ',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          const Icon(Icons.auto_awesome, size: 20),
        ],
      ),
    );
  }
}

/// セクション見出し
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.stars_rounded, color: cs.primary, size: 18),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

/// 4軸のデュアルバー
class _DualBar extends StatelessWidget {
  const _DualBar({required this.label, required this.valueLeft});
  final String label; // "S↔K" など
  final double valueLeft; // 左側（0〜1）

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 10,
            child: Stack(
              children: [
                // 背景
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                // 左
                FractionallySizedBox(
                  widthFactor: valueLeft.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 箇条書きカード
class _BulletCard extends StatelessWidget {
  const _BulletCard({
    required this.title,
    required this.accent,
    required this.bullets,
  });
  final String title;
  final Color accent;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.08), accent.withOpacity(0.04)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: title == '強み' ? accent : cs.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(b)),
                ],
              ),
            ),
          ),
          if (bullets.isEmpty)
            Text('—', style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }
}

/// アドバイスカード
class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.accent, required this.tips});
  final Color accent;
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.10), accent.withOpacity(0.05)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('アドバイス', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 相性表示
class _CompatibilityRow extends StatelessWidget {
  const _CompatibilityRow({
    required this.good,
    required this.caution,
    required this.accent,
  });
  final List<String> good;
  final List<String> caution;
  final Color accent;

  Widget _pill(String t, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Text(
        t,
        style: TextStyle(fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ベスト', style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: good.map((t) => _pill(t, color: accent)).toList(),
        ),
        const SizedBox(height: 12),
        Text('注意', style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: caution.map((t) => _pill(t, color: cs.error)).toList(),
        ),
      ],
    );
  }
}

/// SNSシェア導線
class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.onShareX,
    required this.onShareIG,
    required this.onShareLINE,
  });

  final VoidCallback onShareX;
  final VoidCallback onShareIG;
  final VoidCallback onShareLINE;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ShareButton(
            label: 'Xでシェア',
            circleChild: const Text(
              'X',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            circleColor: Colors.black,
            onTap: onShareX,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ShareButton(
            label: 'ストーリーズ',
            circleChild: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
            ),
            circleColor: const Color(0xFFFD1D1D), // IG風（赤寄り）
            gradient: const [
              Color(0xFF405DE6),
              Color(0xFF5851DB),
              Color(0xFF833AB4),
              Color(0xFFC13584),
              Color(0xFFE1306C),
              Color(0xFFFD1D1D),
              Color(0xFFF56040),
              Color(0xFFFCAF45),
              Color(0xFFFFDC80),
            ],
            onTap: onShareIG,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ShareButton(
            label: 'LINEで送る',
            circleChild: const Text(
              'LINE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            circleColor: const Color(0xFF06C755),
            onTap: onShareLINE,
          ),
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.label,
    required this.circleChild,
    required this.circleColor,
    this.gradient,
    required this.onTap,
  });

  final String label;
  final Widget circleChild;
  final Color circleColor;
  final List<Color>? gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: Colors.white.withOpacity(0.6));
    final bkg = gradient == null
        ? BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: border,
          )
        : BoxDecoration(
            gradient: LinearGradient(colors: gradient!),
            shape: BoxShape.circle,
            border: border,
          );

    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: bkg,
            alignment: Alignment.center,
            child: circleChild,
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}

/// カウントダウンオーバーレイ
class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = number > 0 ? '$number' : '決定！';
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.surface.withOpacity(0.85),
                cs.surface.withOpacity(0.75),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                text,
                key: ValueKey(text),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// きらめきオーバーレイ（軽量）
class _SparkOverlay extends StatelessWidget {
  const _SparkOverlay();

  @override
  Widget build(BuildContext context) {
    final stars = List.generate(
      16,
      (i) => Positioned(
        left: (i * 37) % MediaQuery.of(context).size.width,
        top: (i * 53) % (MediaQuery.of(context).size.height * 0.4) + 60,
        child: Opacity(
          opacity: 0.85 - (i % 5) * 0.12,
          child: const Icon(Icons.auto_awesome, size: 16),
        ),
      ),
    );
    return Positioned.fill(
      child: IgnorePointer(child: Stack(children: stars)),
    );
  }
}

// =========================
// 画像パス
// =========================
String _getImagePath(String type) {
  switch (type.toUpperCase()) {
    case 'KMHA':
      return 'lib/image/kmha.png';
    case 'KMHC':
      return 'lib/image/kmhc.png';
    case 'KMLA':
      return 'lib/image/kmla.png';
    case 'KMLC':
      return 'lib/image/kmlc.png';
    case 'KPHA':
      return 'lib/image/kpha.png';
    case 'KPHC':
      return 'lib/image/kphc.png';
    case 'KPLA':
      return 'lib/image/kpla.png';
    case 'KPLC':
      return 'lib/image/kplc.png';
    case 'SMHA':
      return 'lib/image/smha.png';
    case 'SMHC':
      return 'lib/image/smhc.png';
    case 'SMLA':
      return 'lib/image/smla.png';
    case 'SMLC':
      return 'lib/image/smlc.png';
    case 'SPHA':
      return 'lib/image/spha.png';
    case 'SPHC':
      return 'lib/image/sphc.png';
    case 'SPLA':
      return 'lib/image/spla.png';
    case 'SPLC':
      return 'lib/image/splc.png';
    default:
      return 'lib/image/default.png';
  }
}
