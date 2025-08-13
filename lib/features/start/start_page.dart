// lib/features/start/start_page.dart
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../legal/terms_page.dart';
import '../legal/privacy_page.dart';
import '../../core/app_routes.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // 1) ヒーロー（16:9固定で崩れ防止）
              const _HeroVisual(),
              const SizedBox(height: 16),

              // 2) タイトル
              const Text(
                'カオタイプ16',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '顔×性格で自分の新発見。ポップに診断、シェアで盛り上がろう！',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 16),

              // 3) 信頼バッジ
              const _TrustBadges(),
              const SizedBox(height: 16),

              // 4) メインCTA
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.upload),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('診断を始める'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 5) 注意書き（軽量グラス風）
              _GlassNote(
                child: const Text(
                  'この診断では、選択した顔写真がサーバーに送信されます。\n'
                  '詳細は「利用規約」と「プライバシーポリシー」をご確認ください。',
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),
              const _ScrollHint(),
              const SizedBox(height: 18),

              // 6) タイプ一覧プレビュー（★修正済み：高さ固定グリッド）
              const _SectionHeader(
                icon: Icons.grid_view_rounded,
                title: 'タイプ一覧プレビュー',
                subtitle: '人気タイプをチラ見せ。あなたはどれっぽい？',
              ),
              const SizedBox(height: 10),
              const _ExamplesScroller(items: _sampleExamples),

              const SizedBox(height: 24),

              // 8) 2次CTA
              FilledButton.tonal(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.upload),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('写真を選んで今すぐ診断'),
                ),
              ),

              const SizedBox(height: 16),

              // 9) 規約リンク
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    child: const Text('利用規約'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsPage()),
                      );
                    },
                  ),
                  const Text('  /  '),
                  TextButton(
                    child: const Text('プライバシーポリシー'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPage()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// ヒーロー：16:9 比率で固定（画像は後差し替えOK）
// =====================================================
class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final mainSize = math.min(w * 0.48, 170.0);
          final subSize = math.min(w * 0.30, 110.0);

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-1, -0.8),
                      end: const Alignment(1, 0.9),
                      colors: [
                        cs.primary.withOpacity(0.12),
                        cs.secondary.withOpacity(0.10),
                        cs.tertiary.withOpacity(0.08),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 18,
                child: _Blob(size: 90, color: cs.secondary.withOpacity(0.25)),
              ),
              Positioned(
                right: 24,
                bottom: 14,
                child: _Blob(size: 110, color: cs.primary.withOpacity(0.22)),
              ),
              Align(
                alignment: const Alignment(0, -0.25),
                child: _GlassCircle(diameter: math.min(w * 0.60, 200)),
              ),
              Align(
                alignment: const Alignment(0, -0.15),
                child: _CharacterSticker(
                  imagePath: 'lib/image/kmla.png',
                  tilt: 2,
                  size: mainSize,
                  shadow: cs.primary,
                ),
              ),
              Align(
                alignment: const Alignment(-0.85, 0.1),
                child: _CharacterSticker(
                  imagePath: 'lib/image/smha.png',
                  tilt: -6,
                  size: subSize,
                  shadow: cs.secondary,
                ),
              ),
              Align(
                alignment: const Alignment(0.85, 0.35),
                child: _CharacterSticker(
                  imagePath: 'lib/image/sphc.png',
                  tilt: 8,
                  size: subSize,
                  shadow: cs.tertiary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(width: size, height: size, color: color),
      ),
    );
  }
}

class _GlassCircle extends StatelessWidget {
  const _GlassCircle({required this.diameter});
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.20),
            border: Border.all(color: Colors.white.withOpacity(0.55)),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// セクションヘッダー
// =====================================================
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================
// 信頼バッジ
// =====================================================
class _TrustBadges extends StatelessWidget {
  const _TrustBadges();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: const [
        _Badge(
          icon: Icons.face_retouching_natural,
          labelTop: 'AI分析',
          labelBottom: '顔×性格マッチ',
        ),
        _Badge(
          icon: Icons.lock_outline_rounded,
          labelTop: '匿名OK',
          labelBottom: 'ニックネーム診断',
        ),
        _Badge(
          icon: Icons.stars_rounded,
          labelTop: 'SNS映え',
          labelBottom: 'カードを自動生成',
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.labelTop,
    required this.labelBottom,
  });
  final IconData icon;
  final String labelTop;
  final String labelBottom;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labelTop,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                labelBottom,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================================
// 注意書き（グラス風）
// =====================================================
class _GlassNote extends StatelessWidget {
  const _GlassNote({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.08),
            border: Border.all(color: cs.primary.withOpacity(0.20)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
      ),
    );
  }
}

// =====================================================
// スクロール誘導
// =====================================================
class _ScrollHint extends StatefulWidget {
  const _ScrollHint();

  @override
  State<_ScrollHint> createState() => _ScrollHintState();
}

class _ScrollHintState extends State<_ScrollHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  late final Animation<double> _anim = Tween<double>(
    begin: 0,
    end: 7,
  ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _anim.value),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.keyboard_double_arrow_down_rounded, size: 18),
              SizedBox(width: 4),
              Text('スクロールでタイプ＆診断例をチェック', style: TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

// =====================================================
// ★ タイプ一覧プレビュー（オーバーフロー修正版）
//   - 列数: 幅に応じて 2/3/4 列
//   - 高さ: mainAxisExtent=72 で固定（テキスト＆アイコンが収まる）
// =====================================================
class _TypePreviewGrid extends StatelessWidget {
  const _TypePreviewGrid({required this.items});
  final List<_TypePreview> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final crossAxisCount = w < 330 ? 2 : (w < 400 ? 3 : 4);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 72, // ← 高さ固定でオーバーフロー防止
          ),
          itemBuilder: (context, i) => _TypeTile(item: items[i]),
        );
      },
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.item});
  final _TypePreview item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
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
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item.code}：${item.label}（プレビュー）')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const SizedBox(width: 2),
                CircleAvatar(
                  radius: 16,
                  child: Text(item.emoji, style: const TextStyle(fontSize: 15)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// 診断例（横スクロール）
// =====================================================
class _ExamplesScroller extends StatelessWidget {
  const _ExamplesScroller({required this.items});
  final List<_ExampleItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final it = items[i];
          return Container(
            width: 240,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  cs.secondary.withOpacity(0.10),
                  cs.primary.withOpacity(0.08),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: cs.primary.withOpacity(0.15),
                    image: it.thumbPath != null
                        ? DecorationImage(
                            image: AssetImage(it.thumbPath!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: it.thumbPath == null
                      ? const Icon(Icons.face_6_rounded, size: 28)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        it.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        it.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 16, color: cs.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${it.likes} いいね',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // const Spacer(),
                          // OutlinedButton(
                          //   onPressed: () {
                          //     ScaffoldMessenger.of(context).showSnackBar(
                          //       SnackBar(
                          //         content: Text('診断カード ${it.title}（プレビュー）'),
                          //       ),
                          //     );
                          //   },
                          //   style: OutlinedButton.styleFrom(
                          //     minimumSize: const Size(0, 32),
                          //     padding: const EdgeInsets.symmetric(
                          //       horizontal: 10,
                          //     ),
                          //     side: BorderSide(
                          //       color: cs.primary.withOpacity(0.4),
                          //     ),
                          //     shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(10),
                          //     ),
                          //   ),
                          //   child: const Text(
                          //     '見る',
                          //     style: TextStyle(fontSize: 12),
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =====================================================
// 画像カード（今風の“シール”）
// =====================================================
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
      angle: tilt * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
          borderRadius: BorderRadius.circular(14),
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

// =====================================================
// モデル＆ダミーデータ
// =====================================================
class _TypePreview {
  final String code;
  final String label;
  final String emoji;
  const _TypePreview({
    required this.code,
    required this.label,
    required this.emoji,
  });
}

class _ExampleItem {
  final String title;
  final String caption;
  final int likes;
  final String? thumbPath;
  const _ExampleItem({
    required this.title,
    required this.caption,
    required this.likes,
    this.thumbPath,
  });
}

const _sampleTypes = <_TypePreview>[
  _TypePreview(code: 'SMHA', label: 'ノリで明るい主役顔', emoji: '🥁'),
  _TypePreview(code: 'SMHC', label: '表面クール中身アツ', emoji: '🔥'),
  _TypePreview(code: 'SMLA', label: '人懐っこい癒し系', emoji: '🐪'),
  _TypePreview(code: 'KMLA', label: 'ツンデレ忍者系', emoji: '🥷'),
  _TypePreview(code: 'KPHC', label: '無表情ギタリスト', emoji: '🎸'),
  _TypePreview(code: 'KPLA', label: '闘志を秘めた仏像', emoji: '🪷'),
  _TypePreview(code: 'KPLC', label: '冷凍庫の王', emoji: '🧊'),
  _TypePreview(code: 'SFPI', label: 'マイペース癒し', emoji: '🌿'),
];

const _sampleExamples = <_ExampleItem>[
  _ExampleItem(
    title: 'SMHA・太鼓フェイス',
    caption: '陽キャ寄り。初対面でも物怖じしないタイプ。',
    likes: 128,
  ),
  _ExampleItem(title: 'KPLC・冷凍庫の王', caption: '感情の起伏は少なめ。静かに頼れる安定感。', likes: 92),
  _ExampleItem(
    title: 'KPHC・無表情ギタリスト',
    caption: '真剣に取り組む姿勢。実は内に情熱的。',
    likes: 77,
  ),
  _ExampleItem(title: 'SMLA・人懐っこい柴犬', caption: '笑顔で周りを和ませるムードメーカー。', likes: 63),
];
