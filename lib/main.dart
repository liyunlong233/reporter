import 'package:flutter/material.dart';
import 'package:reporter/data/datasources/local_database.dart';
import 'package:reporter/data/repositories/local_preferences_repository.dart';
import 'package:reporter/data/repositories/local_recording_repository.dart';
import 'package:reporter/data/repositories/local_settings_repository.dart';
import 'package:reporter/home_page.dart';
import 'package:reporter/screens/basic_settings_page.dart';
import 'package:reporter/screens/recordings_page.dart';
import 'package:reporter/screens/settings_page.dart';

class AppDependencies {
  final LocalDatabase database;
  final LocalRecordingRepository recordingRepository;
  final LocalSettingsRepository settingsRepository;
  final LocalPreferencesRepository preferencesRepository;

  AppDependencies({
    required this.database,
    required this.recordingRepository,
    required this.settingsRepository,
    required this.preferencesRepository,
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final database = LocalDatabase.instance;
  final dependencies = AppDependencies(
    database: database,
    recordingRepository: LocalRecordingRepository(database),
    settingsRepository: LocalSettingsRepository(database),
    preferencesRepository: LocalPreferencesRepository(database),
  );
  
  runApp(MyApp(dependencies: dependencies));
}

class MyApp extends StatelessWidget {
  final AppDependencies dependencies;

  const MyApp({super.key, required this.dependencies});

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
        textTheme: Theme.of(context).textTheme,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(
          recordingRepository: dependencies.recordingRepository,
          settingsRepository: dependencies.settingsRepository,
          preferencesRepository: dependencies.preferencesRepository,
        ),
        '/settings': (context) => SettingsPage(
          settingsRepository: dependencies.settingsRepository,
          preferencesRepository: dependencies.preferencesRepository,
        ),
        '/basic-settings': (context) => BasicSettingsPage(
          preferencesRepository: dependencies.preferencesRepository,
        ),
        '/recordings': (context) => RecordingsPage(
          recordingRepository: dependencies.recordingRepository,
          settingsRepository: dependencies.settingsRepository,
          preferencesRepository: dependencies.preferencesRepository,
        ),
      },
    );
  }
}
