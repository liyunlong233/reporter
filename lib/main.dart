import 'package:flutter/material.dart';
import 'package:reporter/database/database_helper.dart';
import 'package:reporter/home_page.dart';
import 'package:reporter/screens/recordings_page.dart';
import 'package:reporter/screens/settings_page.dart';
import 'package:reporter/screens/global_settings_page.dart';
import 'package:provider/provider.dart';
import 'global/app_state.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.instance.database;
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return MaterialApp(
      title: '同期录音报告系统',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        iconTheme: const IconThemeData(
          color: Colors.black,
          size: 24,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'NotoSansSC'),
          bodyMedium: TextStyle(fontFamily: 'NotoSansSC'),
          titleLarge: TextStyle(fontFamily: 'NotoSansSC'),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'NotoSansSC'),
          bodyMedium: TextStyle(fontFamily: 'NotoSansSC'),
          titleLarge: TextStyle(fontFamily: 'NotoSansSC'),
        ),
      ),
      themeMode: appState.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
        '/recordings': (context) => const RecordingsPage(),
        '/global_settings': (context) => const GlobalSettingsPage(),
      },
    );
  }
}
