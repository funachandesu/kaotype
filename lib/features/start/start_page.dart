import 'package:flutter/material.dart';
import '../legal/terms_page.dart';
import '../legal/privacy_page.dart';
import '../../core/app_routes.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              const Text(
                'カオタイプ16',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('顔×性格でわかる16タイプ診断', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              // 画像送信の注意書き
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'この診断では、選択した顔写真がサーバーに送信されます。\n詳細は「利用規約」と「プライバシーポリシー」をご確認ください。',
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.upload),
                  child: const Text('診断を始める'),
                ),
              ),
              const SizedBox(height: 12),
              // 規約リンク行
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
                  const Text(' / '),
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
