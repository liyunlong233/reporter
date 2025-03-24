import 'package:flutter/material.dart';
import 'package:reporter/database/database_helper.dart';
import 'package:reporter/home_page.dart';
import 'package:reporter/screens/recordings_page.dart';
import 'package:reporter/screens/settings_page.dart';
import 'package:reporter/screens/tracks_page.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '同期录音报告系统',
      theme: ThemeData(
    primarySwatch: Colors.blue,
    iconTheme: const IconThemeData(
      color: Colors.black,
      size: 24,
    ),
    textTheme: Theme.of(context).textTheme.copyWith(
      bodyLarge: TextStyle(fontFamily: 'NotoSansSC'),
      bodyMedium: TextStyle(fontFamily: 'NotoSansSC'),
      titleLarge: TextStyle(fontFamily: 'NotoSansSC'),
    ),
  ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
        '/tracks': (context) => const TracksPage(),
        '/recordings': (context) => const RecordingsPage(),
      },
    );
  }
}
