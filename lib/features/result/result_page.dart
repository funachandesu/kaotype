// lib/features/result/result_page.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
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

  // JSONデータ
  Map<String, dynamic>? _typeDb;
  bool _dbLoading = true;
  String? _dbError;

  final GlobalKey _captureKey = GlobalKey();

  // 演出用
  int _countdown = 0; // 0で非表示、3→2→1→0
  bool _blast = false; // 決定時のきらめき

  Future<void> _loadTypeDb() async {
    setState(() {
      _dbLoading = true;
      _dbError = null;
    });
    try {
      // 同ディレクトリに配置したJSONを読み込む
      // pubspec.yaml の assets にこのパスを追加しておくこと
      final jsonStr = await rootBundle.loadString(
        'lib/features/result/result_definitions.json',
      );
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _typeDb = decoded;
        _dbLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dbError = '結果データの読み込みに失敗しました: $e';
        _dbLoading = false;
      });
    }
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTypeDb();
      fetchResult();
    });
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

    final isBusy = loading || _dbLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('診断結果')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isBusy
            ? const Center(child: CircularProgressIndicator())
            : (error ?? _dbError) != null
            ? Center(child: Text((error ?? _dbError)!))
            : res == null
            ? const Center(child: Text('結果がありません'))
            : (_typeDb?[res.type] == null)
            ? Center(child: Text('結果データに ${res.type} の定義が見つかりませんでした'))
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
                            child: _ResultCard(
                              typeCode: res.type,
                              data: _typeDb![res.type] as Map<String, dynamic>,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ===== SNSシェア導線 =====
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
/// 結果カード（JSON 準拠UI）
/// =====================================================
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.typeCode, required this.data});
  final String typeCode;
  final Map<String, dynamic> data;

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

  double _toPct(dynamic v) {
    if (v == null) return 0.0;
    double d;
    if (v is int) {
      d = v.toDouble();
    } else if (v is double) {
      d = v;
    } else {
      d = double.tryParse(v.toString()) ?? 0.0;
    }
    // 0〜100 を想定し、ガード
    return (d / 100.0).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _accentFromType(cs, typeCode);

    final name = (data['name'] ?? '').toString();
    final catchCopy = (data['catch_copy'] ?? '').toString();
    final catchPhrase = (data['catch_phrase'] ?? '').toString();
    final manual = (data['manual'] ?? '').toString();

    final strongPoints = (data['strong_point'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final weekPoints = (data['week_point'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final advice = (data['one_point_advice'] ?? '').toString();

    final chart = (data['chart'] as Map<String, dynamic>? ?? {});
    final sk = _toPct(chart['SK']);
    final mp = _toPct(chart['MP']);
    final hl = _toPct(chart['HL']);
    final ac = _toPct(chart['AC']);

    final typeThings = (data['type_things'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final careers = (data['suitable_careers_and_roles'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final compatible = (data['compatible_types'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .cast<Map<String, dynamic>>()
        .toList();
    final incompatible = (data['incompatible_types'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .cast<Map<String, dynamic>>()
        .toList();

    final celebrities = (data['similar_famous_people'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .cast<Map<String, dynamic>>()
        .toList();

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
                // タイトル帯（タイプ4文字バッジ + JSONタイトル/キャッチコピー）
                _TypeBadge(
                  code: typeCode,
                  title: name,
                  subtitle: catchCopy,
                  accent: accent,
                ),

                const SizedBox(height: 10),
                if (catchPhrase.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      child: Text(
                        catchPhrase,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // メイン画像
                Center(
                  child: SizedBox(
                    width: imageSide,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _ResultImage(type: typeCode),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 概要（manual）
                _SectionHeader(title: '概要'),
                const SizedBox(height: 6),
                Text(manual),

                const SizedBox(height: 16),

                // 4軸チャート（バー） JSONの chart をそのまま表示 + ラベル（ベタ書き）
                _SectionHeader(title: 'タイプチャート'),
                const SizedBox(height: 8),

                // S-K
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'S = 親しみやすさ',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'K = クールな安定感',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _DualBar(label: 'S↔K', valueLeft: sk),

                const SizedBox(height: 8),

                // M-P
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'M = 瞬発力・ノリ',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'P = 丁寧さ・配慮',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _DualBar(label: 'M↔P', valueLeft: mp),

                const SizedBox(height: 8),

                // H-L
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'H = 存在感・メリハリ',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'L = 落ち着き',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _DualBar(label: 'H↔L', valueLeft: hl),

                const SizedBox(height: 8),

                // A-C
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'A = 行動力',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'C = 計画性',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _DualBar(label: 'A↔C', valueLeft: ac),

                const SizedBox(height: 16),

                // 強み・弱み（JSON 準拠）
                Row(
                  children: [
                    Expanded(
                      child: _BulletCard(
                        title: '強み',
                        accent: accent,
                        bullets: strongPoints,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BulletCard(
                        title: '弱み',
                        accent: cs.error,
                        bullets: weekPoints,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // アドバイス（JSON 準拠）
                _AdviceCard(accent: accent, tips: [advice]),

                const SizedBox(height: 16),

                // タイプあるある
                if (typeThings.isNotEmpty) ...[
                  _SectionHeader(title: 'タイプあるある'),
                  const SizedBox(height: 8),
                  _ChipWrap(items: typeThings, color: cs.primary),
                  const SizedBox(height: 16),
                ],

                // 向いてる職業・役割
                if (careers.isNotEmpty) ...[
                  _SectionHeader(title: '向いてる職業・役割'),
                  const SizedBox(height: 8),
                  _ChipWrap(items: careers, color: cs.secondary),
                  const SizedBox(height: 16),
                ],

                // 相性（良い／注意）理由つき
                _SectionHeader(title: '相性'),
                const SizedBox(height: 8),
                if (compatible.isNotEmpty)
                  _ReasonList(
                    title: 'ベスト',
                    items: compatible,
                    pillColor: accent,
                  ),
                if (incompatible.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ReasonList(
                    title: '注意',
                    items: incompatible,
                    pillColor: cs.error,
                  ),
                ],

                const SizedBox(height: 16),

                // 似ている有名人
                if (celebrities.isNotEmpty) ...[
                  _SectionHeader(title: '似ている有名人'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: celebrities.map((m) {
                      final name = (m['name'] ?? '').toString();
                      final desc = (m['description'] ?? '').toString();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                '($desc)',
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.65),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// JSON画像パスのマップは従来と同様
class _ResultImage extends StatelessWidget {
  const _ResultImage({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Image.asset(_getImagePath(type), fit: BoxFit.cover);
  }
}

/// タイプ4文字の目立つバッジ（JSONの name/catch_copy を表示）
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.accent,
  });
  final String code;
  final String title;
  final String subtitle;
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
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                  ),
                ],
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

/// 4軸のデュアルバー（左側比率を 0〜1 で受け取る）
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

/// 箇条書きカード（強み・弱み）
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

/// アドバイスカード（1点アドバイス）
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
          ...tips
              .where((t) => t.trim().isNotEmpty)
              .map(
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

/// タグ/チップ群
class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.items, required this.color});
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((t) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
          ),
          child: Text(
            t,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        );
      }).toList(),
    );
  }
}

/// 相性の理由付きリスト
class _ReasonList extends StatelessWidget {
  const _ReasonList({
    required this.title,
    required this.items,
    required this.pillColor,
  });
  final String title;
  final List<Map<String, dynamic>> items;
  final Color pillColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
        const SizedBox(height: 6),
        Column(
          children: items.map((m) {
            final type = (m['type'] ?? '').toString();
            final reason = (m['reason'] ?? '').toString();
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.6)),
                color: cs.surfaceVariant.withOpacity(0.35),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイプピル
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: pillColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.6)),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: pillColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(reason)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
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
