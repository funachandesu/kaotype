// lib/features/upload/upload_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_routes.dart';
import '../../state/app_state.dart';

class UploadPage extends ConsumerStatefulWidget {
  const UploadPage({super.key});
  @override
  ConsumerState<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends ConsumerState<UploadPage> {
  final picker = ImagePicker();

  Future<void> pickFront() async {
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) {
      final bytes = await x.readAsBytes(); // ← 共通でbytesを取る
      ref.read(selectedImageBytesProvider.notifier).state = bytes;
      ref.read(selectedImagePathProvider.notifier).state =
          x.path; // 既存も残す（モバイル向け）
    }
  }

  Future<void> pickSide() async {
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) {
      final bytes = await x.readAsBytes();
      ref.read(selectedSideImageBytesProvider.notifier).state = bytes;
      ref.read(selectedSideImagePathProvider.notifier).state = x.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    final frontBytes = ref.watch(selectedImageBytesProvider);
    final sideBytes = ref.watch(selectedSideImageBytesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('画像を選択')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              '正面写真（必須）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _PreviewBox(bytes: frontBytes, placeholder: '正面写真が未選択'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: pickFront,
                    child: const Text('正面をアップロード'),
                  ),
                ),
                const SizedBox(width: 8),
                if (frontBytes != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(selectedImageBytesProvider.notifier).state =
                            null;
                        ref.read(selectedImagePathProvider.notifier).state =
                            null;
                      },
                      child: const Text('削除'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: const [
                Text(
                  '横写真（任意）',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 6),
                Tooltip(
                  message: '横顔があると精度が上がる場合があります。',
                  child: Icon(Icons.info_outline, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _PreviewBox(bytes: sideBytes, placeholder: '横写真が未選択'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: pickSide,
                    child: const Text('横をアップロード'),
                  ),
                ),
                const SizedBox(width: 8),
                if (sideBytes != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref
                                .read(selectedSideImageBytesProvider.notifier)
                                .state =
                            null;
                        ref.read(selectedSideImagePathProvider.notifier).state =
                            null;
                      },
                      child: const Text('削除'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('※ 顔がはっきり映った正面写真をご利用ください。横写真は任意です。'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: frontBytes == null
                    ? null
                    : () => Navigator.pushNamed(context, AppRoutes.questions),
                child: const Text('次へ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  final Uint8List? bytes;
  final String placeholder;
  const _PreviewBox({
    required this.bytes,
    required this.placeholder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return AspectRatio(
        aspectRatio: 1,
        child: Image.memory(bytes!, fit: BoxFit.cover),
      );
    }
    return Container(
      height: 180,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border.all()),
      child: Text(placeholder),
    );
  }
}
