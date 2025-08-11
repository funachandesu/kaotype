import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final useMockProvider = Provider<bool>((_) => false);

// 画像パス（端末ローカル）
final selectedImagePathProvider = StateProvider<String?>((_) => null); // 正面（必須）
final selectedSideImagePathProvider = StateProvider<String?>(
  (_) => null,
); // 横（任意）

// 回答
final answersProvider = StateProvider<Map<String, dynamic>>((_) => {});

// アップロード後のサーバーパス（診断APIで使う）
final uploadedFrontImagePathProvider = StateProvider<String?>((_) => null);
final uploadedSideImagePathProvider = StateProvider<String?>((_) => null);

// 追加（バイト列：Web/モバイル共通で使える）
final selectedImageBytesProvider = StateProvider<Uint8List?>((_) => null);
final selectedSideImageBytesProvider = StateProvider<Uint8List?>((_) => null);

// 診断結果
class AnalyzeResult {
  final String type;
  final String label;
  final String description;
  AnalyzeResult({
    required this.type,
    required this.label,
    required this.description,
  });
  factory AnalyzeResult.fromJson(Map<String, dynamic> j) => AnalyzeResult(
    type: j['type'] ?? '',
    label: j['label'] ?? '',
    description: j['description'] ?? j['summary'] ?? '',
  );
}

final analyzeResultProvider = StateProvider<AnalyzeResult?>((_) => null);
