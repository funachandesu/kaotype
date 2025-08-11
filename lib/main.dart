// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_routes.dart';
import 'features/start/start_page.dart';
import 'features/upload/upload_page.dart';
import 'features/questions/questions_page.dart';
import 'features/result/result_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
      ),
    );
  }
}
