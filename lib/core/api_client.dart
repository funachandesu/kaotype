// lib/core/api_client.dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../state/app_state.dart';

class ApiClient {
  final Dio _dio;
  final bool useMock;

  ApiClient({required String baseUrl, required this.useMock})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      ) {
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
      ),
    );
  }

  /// 顔写真をアップロードしてサーバー上のパスを取得（端末パス使用）
  /// POST /image-upload (multipart/form-data)
  Future<({String frontPath, String? sidePath})> uploadImage({
    required String frontImagePath,
    String? sideImagePath,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return (
        frontPath: "/uploads/faces/mock_front.jpg",
        sidePath: sideImagePath != null ? "/uploads/faces/mock_side.jpg" : null,
      );
    }

    final form = FormData.fromMap({
      'front_image': await MultipartFile.fromFile(
        frontImagePath,
        filename: 'front.jpg',
      ),
      if (sideImagePath != null)
        'side_image': await MultipartFile.fromFile(
          sideImagePath,
          filename: 'side.jpg',
        ),
    });

    final res = await _dio.post('/image-upload', data: form);
    final data = res.data as Map<String, dynamic>;
    return (
      frontPath: data['front_image_path'] as String,
      sidePath: data['side_image_path'] as String?,
    );
  }

  /// 顔写真をアップロードしてサーバー上のパスを取得（バイト列使用：Web/モバイル両対応）
  /// POST /image-upload (multipart/form-data)
  Future<({String frontPath, String? sidePath})> uploadImageBytes({
    required Uint8List frontImageBytes,
    Uint8List? sideImageBytes,
    String frontFileName = 'front.jpg',
    String sideFileName = 'side.jpg',
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return (
        frontPath: "/uploads/faces/mock_front.jpg",
        sidePath: sideImageBytes != null
            ? "/uploads/faces/mock_side.jpg"
            : null,
      );
    }

    final form = FormData.fromMap({
      'front_image': MultipartFile.fromBytes(
        frontImageBytes,
        filename: frontFileName,
      ),
      if (sideImageBytes != null)
        'side_image': MultipartFile.fromBytes(
          sideImageBytes,
          filename: sideFileName,
        ),
    });

    final res = await _dio.post('/image-upload', data: form);
    final data = res.data as Map<String, dynamic>;
    return (
      frontPath: data['front_image_path'] as String,
      sidePath: data['side_image_path'] as String?,
    );
  }

  /// 旧：画像+回答のmultipart（将来用に残す）
  Future<AnalyzeResult> analyze({
    required String imagePath,
    String? sideImagePath,
    required Map<String, dynamic> answers,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return AnalyzeResult.fromJson({
        "type": "SMHA",
        "label": "祭りの太鼓フェイス",
        "description": "計画立案が得意。静かな環境で力を発揮します。",
      });
    }

    final form = FormData.fromMap({
      'front_image': await MultipartFile.fromFile(
        imagePath,
        filename: 'front.jpg',
      ),
      if (sideImagePath != null)
        'side_image': await MultipartFile.fromFile(
          sideImagePath,
          filename: 'side.jpg',
        ),
      'answers': answers, // 旧仕様の名残。必要なら削除
    });

    final res = await _dio.post('/analyze', data: form);
    return AnalyzeResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// 新：回答のみ + アップロード済み画像パスで診断
  /// POST /diagnosis (application/json)
  Future<AnalyzeResult> analyzeAnswers({
    required List<Map<String, String>> answers,
    required String front_image_path,
    String? side_image_path,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return AnalyzeResult.fromJson({
        "type": "SMHA",
        "label": "祭りの太鼓フェイス",
        "description":
            "キャッチコピー：ノリで世界を明るくする主役顔\n周囲を巻き込むポジティブオーラ\n初対面でも物怖じしない\n笑顔で全てを解決しがち",
      });
    }

    final payload = <String, dynamic>{
      "answers": answers,
      "front_image_path": front_image_path,
      if (side_image_path != null) "side_image_path": side_image_path,
    };

    final res = await _dio.post(
      '/diagnosis',
      data: payload,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    return AnalyzeResult.fromJson(res.data as Map<String, dynamic>);
  }
}
