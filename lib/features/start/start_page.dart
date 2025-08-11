// lib/features/start/start_page.dart
import 'package:flutter/material.dart';
import '../legal/terms_page.dart';
import '../legal/privacy_page.dart';
import '../../core/app_routes.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final topHeight = constraints.maxHeight * 0.38; // 上部ビジュアル領域
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 20,
                ),
                child: Column(
                  children: [
                    // ===== ヒーロービジュアル（散らし配置）=====
                    SizedBox(
                      height: topHeight.clamp(260, 420),
                      width: double.infinity,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 背景の柔らかいグラデ
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(0, -0.2),
                                  radius: 1.0,
                                  colors: [
                                    cs.primary.withOpacity(0.10),
                                    cs.primary.withOpacity(0.02),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // 中央の円（淡いアクセント）
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.only(top: 12),
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primary.withOpacity(0.08),
                              ),
                            ),
                          ),
                          // キャラ1（左上）
                          Positioned(
                            top: 12,
                            left: 0,
                            child: _CharacterSticker(
                              imagePath: 'lib/image/smha.png',
                              tilt: -6,
                              size: 140,
                              shadow: cs.primary,
                            ),
                          ),
                          // キャラ2（中央やや上）
                          Align(
                            alignment: const Alignment(0.2, -0.6),
                            child: _CharacterSticker(
                              imagePath: 'lib/image/kmla.png',
                              tilt: 2,
                              size: 170,
                              shadow: cs.secondary,
                            ),
                          ),
                          // キャラ3（右下）
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: _CharacterSticker(
                              imagePath: 'lib/image/sphc.png',
                              tilt: 8,
                              size: 150,
                              shadow: cs.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== タイトル =====
                    const Text(
                      'カオタイプ16',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('顔×性格でわかる16タイプ診断', textAlign: TextAlign.center),
                    const SizedBox(height: 16),

                    // ===== 注意書きカード =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.10),
                        border: Border.all(color: cs.primary.withOpacity(0.20)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'この診断では、選択した顔写真がサーバーに送信されます。\n'
                        '詳細は「利用規約」と「プライバシーポリシー」をご確認ください。',
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ===== CTA =====
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.upload),
                        child: const Text('診断を始める'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ===== 規約リンク =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          child: const Text('利用規約'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsPage(),
                              ),
                            );
                          },
                        ),
                        const Text(' / '),
                        TextButton(
                          child: const Text('プライバシーポリシー'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacyPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
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

/// キャラクタ画像を“シール風”に見せるウィジェット
class _CharacterSticker extends StatelessWidget {
  const _CharacterSticker({
    required this.imagePath,
    required this.tilt,
    required this.size,
    required this.shadow,
  });

  final String imagePath;
  final double tilt; // 角度（度）
  final double size;
  final Color shadow;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt * 3.1415926535 / 180,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white, // シールの白縁
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadow.withOpacity(0.16),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.black12, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imagePath,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
