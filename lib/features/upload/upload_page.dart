// lib/features/upload/upload_page.dart
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;
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

  Future<void> _pickImage({
    required bool isFront,
    required ImageSource source,
  }) async {
    final x = await picker.pickImage(source: source, imageQuality: 85);
    if (x == null) return;

    final bytes = await x.readAsBytes();
    if (isFront) {
      ref.read(selectedImageBytesProvider.notifier).state = bytes;
      ref.read(selectedImagePathProvider.notifier).state = x.path;
    } else {
      ref.read(selectedSideImageBytesProvider.notifier).state = bytes;
      ref.read(selectedSideImagePathProvider.notifier).state = x.path;
    }
  }

  Future<void> _showSourceSheet({required bool isFront}) async {
    final ctx = context;
    showModalBottomSheet(
      context: ctx,
      showDragHandle: true,
      backgroundColor: Theme.of(ctx).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('フォトライブラリから選ぶ'),
                onTap: () {
                  Navigator.pop(c);
                  _pickImage(isFront: isFront, source: ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('カメラで撮る'),
                onTap: () {
                  Navigator.pop(c);
                  _pickImage(isFront: isFront, source: ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final frontBytes = ref.watch(selectedImageBytesProvider);
    final sideBytes = ref.watch(selectedSideImageBytesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('写真アップロード'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // -------- ヘッダー：軽いノリのコピー＋Tips --------
          _HeaderCopy(),

          const SizedBox(height: 14),

          // -------- 正面（必須） --------
          _SectionTitle(
            title: '正面写真（必須）',
            trailing: _ChipHint(text: '明るい場所・マスクなし'),
          ),
          const SizedBox(height: 8),
          _UploadDropZone(
            bytes: frontBytes,
            hintBig: 'タップして\n正面写真を選ぶ',
            hintSmall: '',
            onTapPick: () => _showSourceSheet(isFront: true),
            onTapChange: () => _showSourceSheet(isFront: true),
            onTapDelete: () {
              ref.read(selectedImageBytesProvider.notifier).state = null;
              ref.read(selectedImagePathProvider.notifier).state = null;
            },
          ),

          const SizedBox(height: 22),

          // -------- 横（任意） --------
          _SectionTitle(
            title: '横写真（任意）',
            tooltip: '横顔があると精度が上がる場合があります。',
            trailing: _ChipHint(text: 'アゴ先が見える角度'),
          ),
          const SizedBox(height: 8),
          _UploadDropZone(
            bytes: sideBytes,
            hintBig: 'タップして\n横写真を選ぶ',
            hintSmall: '',
            onTapPick: () => _showSourceSheet(isFront: false),
            onTapChange: () => _showSourceSheet(isFront: false),
            onTapDelete: () {
              ref.read(selectedSideImageBytesProvider.notifier).state = null;
              ref.read(selectedSideImagePathProvider.notifier).state = null;
            },
          ),

          const SizedBox(height: 18),

          // -------- 注意書き（軽い口調＋アイコン） --------
          _NoteCard(),

          const SizedBox(height: 16),

          // -------- 次へ --------
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: frontBytes == null
                  ? null
                  : () => Navigator.pushNamed(context, AppRoutes.questions),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('次へ'),
              ),
            ),
          ),
        ],
      ),
      // backgroundColor: cs.surfaceContainerHighest.withOpacity(0.35),
    );
  }
}

/// -----------------------------------------------------
/// ドロップゾーン風ウィジェット
/// ・未選択時：点線枠＋アイコン＋説明
/// ・選択時：プレビューに切替、右上に削除、下部に「変更」
/// -----------------------------------------------------
class _UploadDropZone extends StatelessWidget {
  const _UploadDropZone({
    required this.bytes,
    required this.hintBig,
    required this.hintSmall,
    required this.onTapPick,
    required this.onTapChange,
    required this.onTapDelete,
  });

  final Uint8List? bytes;
  final String hintBig;
  final String hintSmall;
  final VoidCallback onTapPick;
  final VoidCallback onTapChange;
  final VoidCallback onTapDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // サイズは端末幅に応じて安定するよう固定高
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          // 背景（うっすらグラデ）
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-1, -0.8),
                  end: const Alignment(1, 1),
                  colors: [
                    cs.primary.withOpacity(0.10),
                    cs.secondary.withOpacity(0.06),
                  ],
                ),
              ),
            ),
          ),

          // 中身
          SizedBox(
            height: 240,
            width: double.infinity,
            child: InkWell(
              onTap: bytes == null ? onTapPick : onTapChange,
              child: bytes == null
                  ? _EmptyZone(hintBig: hintBig, hintSmall: hintSmall)
                  : _PreviewZone(bytes: bytes!),
            ),
          ),

          // 点線枠（CustomPainter）
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: cs.primary.withOpacity(0.45),
                  radius: 18,
                  dashWidth: 8,
                  dashSpace: 6,
                  strokeWidth: 1.6,
                ),
              ),
            ),
          ),

          // 選択時の操作系オーバーレイ
          if (bytes != null) ...[
            Positioned(
              right: 8,
              top: 8,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black.withOpacity(0.45),
                child: IconButton(
                  onPressed: onTapDelete,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Center(
                child: FilledButton.tonal(
                  onPressed: onTapChange,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    backgroundColor: cs.surface.withOpacity(0.85),
                  ),
                  child: const Text('写真を変更する'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyZone extends StatelessWidget {
  const _EmptyZone({required this.hintBig, required this.hintSmall});
  final String hintBig;
  final String hintSmall;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // グラスモーフィズム風の丸背景＋アイコン
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                height: 72,
                width: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: cs.surface.withOpacity(0.6)),
                child: const Icon(Icons.cloud_upload_rounded, size: 34),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hintBig,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hintSmall,
            style: t.textTheme.bodySmall?.copyWith(
              color: t.textTheme.bodySmall?.color?.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 10),
          // 軽い補助ボタン（アクセシビリティ向上）
          OutlinedButton.icon(
            onPressed: null, // デザイン用（タップは上のInkWellで拾う）
            icon: const Icon(Icons.touch_app_rounded),
            label: const Text('タップして選択'),
            style: OutlinedButton.styleFrom(
              disabledForegroundColor: cs.primary,
              side: BorderSide(color: cs.primary.withOpacity(0.35)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewZone extends StatelessWidget {
  const _PreviewZone({required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: bytes.hashCode, // 軽いアニメ感
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: Image.memory(bytes),
      ),
    );
  }
}

/// 点線角丸ボーダー
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        final extract = metric.extractPath(
          distance,
          next.clamp(0, metric.length),
        );
        canvas.drawPath(extract, paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        radius != oldDelegate.radius ||
        dashWidth != oldDelegate.dashWidth ||
        dashSpace != oldDelegate.dashSpace ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}

/// 見出し
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.tooltip, this.trailing});

  final String title;
  final String? tooltip;
  final Widget? trailing;

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
          child: Icon(Icons.image_rounded, size: 18, color: cs.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (tooltip != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: tooltip!,
                  child: const Icon(Icons.info_outline, size: 16),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// 小さめのヒントChip
class _ChipHint extends StatelessWidget {
  const _ChipHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.8),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// ヘッダー文言
class _HeaderCopy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'サクッと1分、顔写真を選択しよう',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          '顔写真は診断にのみ使用されます。',
          style: t.textTheme.bodySmall?.copyWith(
            color: t.textTheme.bodySmall?.color?.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        // ほんのり背景チップ
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

/// 注意書きカード
class _NoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.08),
            border: Border.all(color: cs.primary.withOpacity(0.18)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NoteRow(
                icon: Icons.task_alt_rounded,
                text: '顔がはっきり写った写真を使ってください',
              ),
              SizedBox(height: 6),
              _NoteRow(
                icon: Icons.lock_outline_rounded,
                text: '写真は診断目的でのみ使用します',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
