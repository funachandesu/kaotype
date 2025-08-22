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

/// ============ カラーパレット（HTMLに寄せたトーン） ============
const kGreenMain = Color(0xFF127158);
const kGreenLight = Color(0xFF46C5A1);
const kGreenPale = Color(0xFF92D8C5);
const kPurpleMain = Color(0xFF7D4F9F);
const kPurpleLight = Color(0xFFA572AF);
const kGrayBg = Color(0xFFF3F4F6);

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
    final isBusy = loading || _dbLoading;

    return Scaffold(
      backgroundColor: kGrayBg,
      body: SafeArea(
        child: isBusy
            ? const Center(child: CircularProgressIndicator())
            : (error ?? _dbError) != null
            ? Center(child: Text((error ?? _dbError)!))
            : res == null
            ? const Center(child: Text('結果がありません'))
            : (_typeDb?[res.type] == null)
            ? Center(child: Text('結果データに ${res.type} の定義が見つかりませんでした'))
            : _ResultView(
                typeCode: res.type,
                data: _typeDb![res.type] as Map<String, dynamic>,
                captureKey: _captureKey,
                onShare: () => _shareCapture(targetLabel: 'ALL'),
                countdown: _countdown,
                blast: _blast,
              ),
      ),
    );
  }
}

/// =====================================================
/// 画面全体（HTMLデザインに寄せた構成）
/// =====================================================
class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.typeCode,
    required this.data,
    required this.captureKey,
    required this.onShare,
    required this.countdown,
    required this.blast,
  });

  final String typeCode;
  final Map<String, dynamic> data;
  final GlobalKey captureKey;
  final VoidCallback onShare;
  final int countdown;
  final bool blast;

  Color _accentFromFirstLetter(String t) {
    // S系=グリーン, K系=パープル
    final ch = (t.isNotEmpty ? t[0] : 'S').toUpperCase();
    return ch == 'K' ? kPurpleMain : kGreenMain;
  }

  Color _accentLightFromFirstLetter(String t) {
    final ch = (t.isNotEmpty ? t[0] : 'S').toUpperCase();
    return ch == 'K' ? kPurpleLight : kGreenLight;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentFromFirstLetter(typeCode);
    final accentLight = _accentLightFromFirstLetter(typeCode);

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
    double _toPct(dynamic v) {
      if (v == null) return 0.0;
      final d = v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;
      return (d / 100.0).clamp(0.0, 1.0);
    }

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

    final mq = MediaQuery.of(context);
    final size = mq.size;
    final shortest = size.shortestSide;

    // “タブレット”判定（iPad想定）
    final isTablet = shortest >= 600;

    // 画像の最大サイズを制限（iPadは少し大きめまで許容）
    final heroImageMax = isTablet ? 360.0 : 300.0;

    // iPadはヘッダーを広めに確保（中身が多い前提）
    final headerHeight =
        (isTablet
                ? math.min(MediaQuery.of(context).size.height * 0.95, 980)
                : math.max(620.0, MediaQuery.of(context).size.height * 0.55))
            .toDouble();

    final content = CustomScrollView(
      slivers: [
        // ====== ヒーローヘッダー（キャプチャ対象） ======
        SliverToBoxAdapter(
          child: RepaintBoundary(
            key: captureKey,
            child: Container(
              height: headerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'あなたの診断結果は...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 円形アイコン
                  // 画像（任意・ポスター用）
                  _CardSurface(
                    padding: const EdgeInsets.all(8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: heroImageMax,
                        maxHeight: heroImageMax,
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _ResultImage(type: typeCode),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // タイトル群
                  Text(
                    catchCopy,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (accent == kPurpleMain ? kPurpleLight : kGreenPale)
                          .withOpacity(0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      typeCode,
                      style: TextStyle(
                        color: accent,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ====== 本文 ======
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // キャッチーな一言
                if (catchPhrase.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (accent == kPurpleMain ? kPurpleLight : kPurpleLight)
                              .withOpacity(0.10),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(14),
                      ),
                      border: Border(
                        left: BorderSide(color: kPurpleLight, width: 4),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '“$catchPhrase”',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: kPurpleMain,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 14),

                // シェアボタン
                FilledButton(
                  onPressed: onShare,
                  style: FilledButton.styleFrom(
                    backgroundColor: kPurpleMain,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        '結果をシェアする',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // あなたのトリセツ
                _SectionTitle(
                  title: 'あなたのトリセツ',
                  barColor: kGreenLight,
                  textColor: kGreenMain,
                ),
                const SizedBox(height: 10),
                _CardSurface(
                  child: Text(
                    manual,
                    style: TextStyle(color: Colors.grey.shade800, height: 1.6),
                  ),
                ),

                const SizedBox(height: 20),

                // 顔×性格チャート
                _SectionTitle(
                  title: '顔×性格チャート',
                  barColor: kGreenLight,
                  textColor: kGreenMain,
                ),
                const SizedBox(height: 10),
                _CardSurface(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: Column(
                    children: [
                      _DotBar(
                        leftLabel: '社交的 (S)',
                        rightLabel: '内省的 (K)',
                        value: sk,
                        trackColor: kGreenPale,
                        dotColor: kPurpleMain,
                      ),
                      const SizedBox(height: 18),
                      _DotBar(
                        leftLabel: '感覚派 (M)',
                        rightLabel: '直感派 (P)',
                        value: mp,
                        trackColor: kGreenPale,
                        dotColor: kPurpleMain,
                      ),
                      const SizedBox(height: 18),
                      _DotBar(
                        leftLabel: '情熱的 (H)',
                        rightLabel: '冷静沈着 (L)',
                        value: hl,
                        trackColor: kGreenPale,
                        dotColor: kPurpleMain,
                      ),
                      const SizedBox(height: 18),
                      _DotBar(
                        leftLabel: '協調性 (A)',
                        rightLabel: '計画性 (C)',
                        value: ac,
                        trackColor: kGreenPale,
                        dotColor: kPurpleMain,
                      ),
                    ],
                  ),
                ),

                // あるある
                if (typeThings.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: '$name あるある',
                    barColor: kGreenLight,
                    textColor: kGreenMain,
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: List.generate(typeThings.length, (i) {
                      final emojis = ['🎉', '😂', '🏃', '✨', '💬', '🧭'];
                      final emoji = emojis[i % emojis.length];
                      return _CardSurface(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(typeThings[i])),
                          ],
                        ),
                      );
                    }),
                  ),
                ],

                // 向いている職業・役割
                if (careers.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: '向いている職業・役割',
                    barColor: kGreenLight,
                    textColor: kGreenMain,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: careers
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: kGreenPale,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                color: kGreenMain,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],

                // 強み・弱み
                if (strongPoints.isNotEmpty || weekPoints.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _CardSurface(
                          padding: const EdgeInsets.all(14),
                          child: _BulletList(
                            title: '強み',
                            bullets: strongPoints,
                            titleColor: accent,
                            icon: Icons.check_circle_rounded,
                            iconColor: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CardSurface(
                          padding: const EdgeInsets.all(14),
                          child: _BulletList(
                            title: '弱み',
                            bullets: weekPoints,
                            titleColor: Colors.red.shade700,
                            icon: Icons.error_rounded,
                            iconColor: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // アドバイス
                if (advice.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: 'アドバイス',
                    barColor: kGreenLight,
                    textColor: kGreenMain,
                  ),
                  const SizedBox(height: 10),
                  _CardSurface(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.tips_and_updates_rounded,
                          color: kPurpleMain,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            advice,
                            style: const TextStyle(height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 相性診断
                if (compatible.isNotEmpty || incompatible.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: '相性診断',
                    barColor: kGreenLight,
                    textColor: kGreenMain,
                  ),
                  const SizedBox(height: 10),
                  if (compatible.isNotEmpty) ...[
                    Text(
                      'ベスト',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: compatible.map((m) {
                        return _ReasonTile(
                          type: (m['type'] ?? '').toString(),
                          reason: (m['reason'] ?? '').toString(),
                          pillColor: accentLight,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (incompatible.isNotEmpty) ...[
                    Text(
                      '注意',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: incompatible.map((m) {
                        return _ReasonTile(
                          type: (m['type'] ?? '').toString(),
                          reason: (m['reason'] ?? '').toString(),
                          pillColor: Colors.red.shade300,
                        );
                      }).toList(),
                    ),
                  ],
                ],

                // 似ている有名人
                if (celebrities.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: '似ている有名人',
                    barColor: kGreenLight,
                    textColor: kGreenMain,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: celebrities.map((m) {
                      final n = (m['name'] ?? '').toString();
                      final d = (m['description'] ?? '').toString();
                      return _CardSurface(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              n,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (d.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                '($d)',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 28),

                // 再診断
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'もう一度診断する',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    // カウントダウン・スパーク演出（オーバーレイ）
    return Stack(
      children: [
        content,
        if (countdown > 0) _CountdownOverlay(number: countdown),
        if (blast) const _SparkOverlay(),
      ],
    );
  }
}

/// タイトル（左にカラーバー）
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.barColor,
    required this.textColor,
  });
  final String title;
  final Color barColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 22, color: barColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// カード風サーフェス
class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.child, this.padding, this.margin});

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// ドットで位置を示すバー（HTMLのチャート風）
class _DotBar extends StatelessWidget {
  const _DotBar({
    required this.leftLabel,
    required this.rightLabel,
    required this.value,
    required this.trackColor,
    required this.dotColor,
  });

  final String leftLabel;
  final String rightLabel;

  /// 0.0(左) ~ 1.0(右)
  final double value;
  final Color trackColor;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ラベル行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                leftLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                rightLabel,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // トラック + ドット
        SizedBox(
          height: 22,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final pos = (w - 20) * value; // ドット直径=20を考慮
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: trackColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: pos.clamp(0.0, math.max(0.0, w - 20)),
                    top: 1,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 箇条書き（強み/弱み）
class _BulletList extends StatelessWidget {
  const _BulletList({
    required this.title,
    required this.bullets,
    required this.titleColor,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final List<String> bullets;
  final Color titleColor;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...bullets.map(
          (b) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Expanded(child: Text(b)),
              ],
            ),
          ),
        ),
        if (bullets.isEmpty)
          Text('—', style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}

/// 相性タイル（タイプピル + 理由）
class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.type,
    required this.reason,
    required this.pillColor,
  });

  final String type;
  final String reason;
  final Color pillColor;

  @override
  Widget build(BuildContext context) {
    return _CardSurface(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: pillColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.6)),
            ),
            child: Text(
              type,
              style: TextStyle(fontWeight: FontWeight.w800, color: pillColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(reason)),
        ],
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

/// カウントダウンオーバーレイ
class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    final text = number > 0 ? '$number' : '決定！';
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withOpacity(0.15),
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
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
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
    final size = MediaQuery.of(context).size;
    final stars = List.generate(
      16,
      (i) => Positioned(
        left: (i * 37) % size.width,
        top: (i * 53) % (size.height * 0.4) + 60,
        child: Opacity(
          opacity: 0.85 - (i % 5) * 0.12,
          child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
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
