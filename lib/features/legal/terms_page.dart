import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('利用規約')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(child: _TermsBody()),
        ),
      ),
    );
  }
}

class _TermsBody extends StatelessWidget {
  const _TermsBody();

  @override
  Widget build(BuildContext context) {
    final h = Theme.of(context).textTheme.titleMedium;
    final p = Theme.of(context).textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('第1条（適用）', style: h),
        const SizedBox(height: 8),
        Text(
          '本利用規約（以下「本規約」）は、本アプリ「カオタイプ16」（以下「本サービス」）の利用条件を定めるものです。'
          'ユーザーは本サービスを利用することで、本規約に同意したものとみなします。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('第2条（本サービスの内容）', style: h),
        const SizedBox(height: 8),
        Text(
          '本サービスは、ユーザーがアップロードする顔写真と設問への回答をもとに、16タイプ診断結果を表示します。'
          '診断精度や結果の適合性について、当社は保証いたしません。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('第3条（画像アップロード）', style: h),
        const SizedBox(height: 8),
        Text(
          '本サービスでは、診断を行うためにユーザーの端末からサーバーへ顔写真画像を送信します。'
          '送信された画像はプライバシーポリシーに従い取り扱われます。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('第4条（禁止事項）', style: h),
        const SizedBox(height: 8),
        Text(
          '法令・公序良俗に反する行為、第三者の権利侵害、他人の画像の無断アップロード、本サービスの運営を妨害する行為等を禁止します。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('第5条（免責）', style: h),
        const SizedBox(height: 8),
        Text(
          '当社は、本サービスの提供、変更、中断、終了によりユーザーに生じた損害について、一切の責任を負いません。'
          'また、通信回線やサーバー障害等により発生した損害についても同様とします。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('第6条（規約の変更）', style: h),
        const SizedBox(height: 8),
        Text(
          '当社は、必要と判断した場合、本規約を改定できます。重要な変更はアプリ内で周知します。'
          '変更後にユーザーが本サービスを利用した場合、変更に同意したものとみなします。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('第7条（準拠法・裁判管轄）', style: h),
        const SizedBox(height: 8),
        Text('本規約は日本法に準拠し、紛争が生じた場合は当社所在地を管轄する裁判所を第一審の専属的合意管轄とします。', style: p),
        const SizedBox(height: 32),
        Text('制定日：2025年8月11日', style: p),
      ],
    );
  }
}
