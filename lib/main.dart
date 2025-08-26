// lib/main.dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'features/start/start_page.dart';
import 'features/upload/upload_page.dart';
import 'features/questions/questions_page.dart';
import 'features/result/result_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Firebase 初期化 ---
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // ---------------------

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _maybeRequestATTOnFirstLaunch();
  }

  Future<void> _maybeRequestATTOnFirstLaunch() async {
    if (!Platform.isIOS) return;

    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 400));
        final result =
            await AppTrackingTransparency.requestTrackingAuthorization();
        debugPrint('ATT status: $result');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'カオタイプ16',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.start,
      routes: {
        AppRoutes.start: (_) => const StartPage(),
        AppRoutes.upload: (_) => const UploadPage(),
        AppRoutes.questions: (_) => const QuestionsPage(),
        AppRoutes.result: (_) => const ResultPage(),
      },
      theme: buildKaotypeTheme(Brightness.light),
      darkTheme: buildKaotypeTheme(Brightness.dark),
      themeMode: ThemeMode.light,
    );
  }
}
