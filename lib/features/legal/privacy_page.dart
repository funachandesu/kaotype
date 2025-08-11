import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('プライバシーポリシー')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(child: _PrivacyBody()),
        ),
      ),
    );
  }
}

class _PrivacyBody extends StatelessWidget {
  const _PrivacyBody();

  @override
  Widget build(BuildContext context) {
    final h = Theme.of(context).textTheme.titleMedium;
    final p = Theme.of(context).textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('1. 収集する情報', style: h),
        const SizedBox(height: 8),
        Text(
          '本サービスは診断のため、ユーザーがアップロードする顔写真画像および設問への回答を収集します。'
          'アプリの安定運用のために、端末情報やログ情報等を取得する場合があります。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('2. 利用目的', style: h),
        const SizedBox(height: 8),
        Text(
          'アップロードされた画像は、16タイプ診断アルゴリズムの実行と結果表示のために利用します。'
          '回答データは診断算出、品質向上、統計的分析に用いられます。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('3. 画像の送信と保管', style: h),
        const SizedBox(height: 8),
        Text(
          '画像はユーザーの端末から当社サーバーへ送信され、診断処理のために保存されます。'
          '保存期間は必要最小限とし、目的達成後は削除または匿名化します（法令により保存を要する場合を除く）。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('4. 第三者提供', style: h),
        const SizedBox(height: 8),
        Text(
          '法令に基づく場合や業務委託先（クラウド事業者等）への提供を除き、本人の同意なく第三者へ提供しません。'
          '委託先には適切な契約と安全管理措置を求めます。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('5. 安全管理', style: h),
        const SizedBox(height: 8),
        Text(
          '送信時・保存時のセキュリティに配慮し、アクセス制御や暗号化等の対策を講じます。'
          'ただし、インターネット上の通信における完全な安全性を保証するものではありません。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('6. ユーザーの権利', style: h),
        const SizedBox(height: 8),
        Text(
          'ユーザーは、自己のデータに関する開示、訂正、削除の請求が可能です。'
          'お問い合わせは下記連絡先までご連絡ください。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('7. ポリシーの変更', style: h),
        const SizedBox(height: 8),
        Text('本ポリシーは適宜改訂される場合があります。重要な変更はアプリ内でお知らせします。', style: p),
        const SizedBox(height: 16),

        Text('8. 連絡先', style: h),
        const SizedBox(height: 8),
        Text('お問い合わせ：info@kao-type.com', style: p),
        const SizedBox(height: 32),
        Text('制定日：2025年8月11日', style: p),
      ],
    );
  }
}
