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
        Text('適用範囲', style: h),
        const SizedBox(height: 8),
        Text(
          '本プライバシーポリシー（以下「本ポリシー」）は、当社が提供する本アプリにおける個人情報および関連データの取り扱いについて定めるものです。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('1. 収集する情報', style: h),
        const SizedBox(height: 8),
        Text(
          '本サービスは診断のため、ユーザーがアップロードする顔写真画像（以下「顔画像」）および設問への回答データを収集します。'
          'また、アプリの安定運用のために、端末情報（OS種別・アプリバージョン等）やログ情報（エラーログ、アクセス時刻等）を取得する場合があります。'
          'さらに、広告配信や利用状況の解析のため、ユーザーの同意を得たうえで広告識別子（IDFA）等のデータを取得することがあります。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('2. 顔データの取り扱い（Guideline 2.1 対応）', style: h),
        const SizedBox(height: 8),
        Text(
          '（1）収集する顔データの内容\n'
          '・ユーザーがアップロードする顔画像（非匿名化の原画像）\n'
          '・診断アルゴリズムの実行に必要な範囲で生成される特徴量（例：顔領域検出結果や埋め込みベクトル等）\n\n'
          '（2）利用目的\n'
          '・16タイプ診断アルゴリズムの実行および結果表示\n'
          '・機能改良・品質向上のための検証（個人を特定しない分析の範囲に限る）\n'
          '※広告配信やトラッキング目的では利用しません。\n\n'
          '（3）保存場所\n'
          '・当社管理の一時ストレージ（Cloudflare R2）に保存します。パブリックアクセスは不可能な設定です。\n\n'
          '（4）保存期間\n'
          '・顔画像および関連特徴量は、アップロードから原則「1日（24時間）以内」に自動削除します。\n\n'
          '（5）第三者提供\n'
          '・顔写真データを外部サービス（第三者）へ提供することは一切ありません。\n\n'
          '（6）ユーザーによる削除請求\n'
          '・1日を待たずに削除を希望される場合は、アプリ内メニューまたは下記連絡先よりご請求ください。ご本人確認後、合理的な期間内に削除します。\n\n'
          '（7）安全管理\n'
          '・送信時・保存時の暗号化、アクセス制御、監査ログ等を実施します。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('3. 利用目的（一般）', style: h),
        const SizedBox(height: 8),
        Text(
          'アップロードされた顔画像および回答データは、16タイプ診断アルゴリズムの実行、結果表示、機能改良・品質向上、統計的分析（個人を特定しない集計）に利用します。'
          '広告目的のプロファイリングには利用しません。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('4. データの送信と保管', style: h),
        const SizedBox(height: 8),
        Text(
          '顔画像はユーザー端末から当社サーバーへ送信され、当社管理の一時ストレージ（Cloudflare R2／非公開設定）に保存します。'
          '保存期間は1日以内とし、満了後は削除します。匿名化処理は行わず、原画像のまま保管します。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('5. 第三者提供', style: h),
        const SizedBox(height: 8),
        Text(
          '法令に基づく場合を除き、本人の同意なく第三者へ提供しません。'
          '特に、顔写真データについては外部サービスへの提供を行いません。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('6. トラッキングとAppTrackingTransparency（Guideline 5.1.2 対応）', style: h),
        const SizedBox(height: 8),
        Text(
          '本アプリは、広告配信および利用状況の解析のために、ユーザーの許可を得た場合に限り広告識別子（IDFA）や関連データを利用します。'
          'このため、AppTrackingTransparency（ATT）フレームワークを用いて、**初回起動時**にユーザーに許可を求めるダイアログを表示します。'
          'ユーザーが許可を与えなかった場合、トラッキングは一切行いません。'
          '許可・不許可の設定は、iOSの「設定」>「プライバシーとセキュリティ」>「トラッキング」からいつでも変更できます。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('7. 安全管理措置', style: h),
        const SizedBox(height: 8),
        Text(
          '当社は、アクセス制御、最小権限、通信・保存時の暗号化、監査ログ、従業者教育等の安全管理措置を講じます。'
          '万一、個人データの漏えい等が発生した場合は、関連法令・ガイドラインに従い、必要な通知・公表・再発防止策を速やかに実施します。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('8. ユーザーの権利', style: h),
        const SizedBox(height: 8),
        Text(
          'ユーザーは、自己のデータに関する開示、訂正、削除、利用停止、利用目的の通知等を請求できます。'
          'アプリ内メニューまたは下記連絡先よりお問い合わせください。'
          'ご本人確認の上、合理的な期間内に対応します。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('9. 未成年の利用', style: h),
        const SizedBox(height: 8),
        Text(
          '未成年者が本サービスを利用する場合、保護者の同意を得た上でご利用ください。'
          '保護者からの代理請求にも対応します。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('10. ポリシーの変更', style: h),
        const SizedBox(height: 8),
        Text(
          '本ポリシーは、法令やサービス内容の変更に応じて改訂される場合があります。'
          '重要な変更がある場合は、アプリ内での告知等により周知します。',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('11. 本ポリシー内の顔データに関する記載箇所（App Review向け目次）', style: h),
        const SizedBox(height: 8),
        Text(
          '・収集内容：第2条（1）、第1条\n'
          '・利用目的：第2条（2）、第3条\n'
          '・保存場所：第2条（3）、第4条\n'
          '・保存期間：第2条（4）\n'
          '・第三者提供：第2条（5）、第5条\n'
          '・削除請求：第2条（6）、第8条\n'
          '・安全管理：第2条（7）、第7条\n'
          '・トラッキング/ATT：第6条（初回起動時に表示）',
          style: p,
        ),
        const SizedBox(height: 16),

        Text('12. 連絡先', style: h),
        const SizedBox(height: 8),
        Text('お問い合わせ：info@kao-type.com', style: p),
        const SizedBox(height: 32),

        Text('制定日：2025年8月11日', style: p),
        Text('最終改定日：2025年8月22日', style: p),
        const SizedBox(height: 8),
        Text('バージョン：1.4', style: p),
      ],
    );
  }
}
