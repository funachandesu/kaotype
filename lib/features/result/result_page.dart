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
    } catch (e) {
      setState(() => error = 'エラー: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
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

      await Share.shareXFiles([
        XFile(file.path, mimeType: 'lib/image/png', name: 'kaotype_result.png'),
      ], text: '私のカオタイプ診断結果\nhttps://google.com で診断する！');
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
                  // スクロール可能 + 画面高に合わせて最小高確保
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 16,
                      ),
                      child: Column(
                        children: [
                          RepaintBoundary(
                            key: _captureKey,
                            child: _ResultCard(res: res),
                          ),
                          const SizedBox(height: 16),
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
                },
              ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.res});
  final AnalyzeResult res;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) {
            // 画像の最大サイズに上限を設ける（横が広いWebでも縦が足りない時にオーバーフローしない）
            final double imageSide = math.min(
              c.maxWidth,
              520,
            ); // 上限 520px（好みで調整可）

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    width: imageSide,
                    child: const AspectRatio(
                      aspectRatio: 1, // 正方形
                      child: _ResultImage(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  res.type,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(res.label, style: const TextStyle(fontSize: 16)),
                const Divider(height: 24),
                Text(res.description),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Image.asset のラッパ。将来差し替えやローディング調整があればここで。
class _ResultImage extends StatelessWidget {
  const _ResultImage();

  @override
  Widget build(BuildContext context) {
    final res = (context.findAncestorWidgetOfExactType<_ResultCard>())!.res;
    return Image.asset(_getImagePath(res.type), fit: BoxFit.cover);
  }
}

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
