import 'package:flutter_test/flutter_test.dart';
import 'package:reporter/data/datasources/local_database.dart';
import 'package:reporter/data/repositories/local_recording_repository.dart';
import 'package:reporter/data/repositories/local_settings_repository.dart';
import 'package:reporter/main.dart';

void main() {
  testWidgets('App should load without errors', (WidgetTester tester) async {
    final database = LocalDatabase.instance;
    final dependencies = AppDependencies(
      database: database,
      recordingRepository: LocalRecordingRepository(database),
      settingsRepository: LocalSettingsRepository(database),
    );

    await tester.pumpWidget(MyApp(dependencies: dependencies));

    await tester.pumpAndSettle();

    expect(find.text('同期录音报告系统'), findsOneWidget);
  });
}
