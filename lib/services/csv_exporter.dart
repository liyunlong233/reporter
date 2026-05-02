import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reporter/models/app_settings.dart';
import 'package:reporter/models/recording_entry.dart';
import 'package:reporter/repositories/recording_repository.dart';
import 'package:reporter/repositories/settings_repository.dart';

class CsvExporter {
  final RecordingRepository _recordingRepository;
  final SettingsRepository _settingsRepository;

  CsvExporter({
    required RecordingRepository recordingRepository,
    required SettingsRepository settingsRepository,
  })  : _recordingRepository = recordingRepository,
        _settingsRepository = settingsRepository;

  Future<String> exportToCsv() async {
    try {
      final entries = await _recordingRepository.getAllRecordings();

      if (entries.isEmpty) {
        throw Exception('没有可导出的录音记录');
      }

      final appSettings = await _settingsRepository.getSettings();
      final csvContent = _generateCsvContent(entries, appSettings);

      String? outputPath;
      if (!kIsWeb) {
        final result = await FilePicker.platform.getDirectoryPath();
        if (result == null) {
          throw Exception('未选择保存目录');
        }
        outputPath = result;
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'recordings_$timestamp.csv';

      String filePath;
      if (outputPath != null) {
        filePath = '$outputPath${Platform.pathSeparator}$fileName';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$fileName';
      }

      final file = File(filePath);
      await file.writeAsString(csvContent, encoding: utf8);

      return filePath;
    } catch (e, stackTrace) {
      debugPrint('导出CSV失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      rethrow;
    }
  }

  String _generateCsvContent(List<RecordingEntry> entries, AppSettings? appSettings) {
    final buffer = StringBuffer();

    _writeProjectInfo(buffer, appSettings);
    buffer.writeln();
    buffer.writeln(_buildHeader());

    for (final entry in entries) {
      buffer.writeln(_buildRow(entry));
    }

    return buffer.toString();
  }

  void _writeProjectInfo(StringBuffer buffer, AppSettings? settings) {
    if (settings == null) return;

    buffer.writeln('Project Information');
    buffer.writeln(_csvEncodeRow(['Project Name', settings.projectName]));
    buffer.writeln(_csvEncodeRow(['Production Company', settings.productionCompany]));
    buffer.writeln(_csvEncodeRow(['Sound Engineer', settings.soundEngineer]));
    buffer.writeln(_csvEncodeRow(['Boom Operator', settings.boomOperator]));
    buffer.writeln(_csvEncodeRow(['Equipment Model', settings.equipmentModel]));
    buffer.writeln(_csvEncodeRow(['File Format', settings.fileFormat]));
    buffer.writeln(_csvEncodeRow(['Frame Rate', settings.frameRate.toString()]));
    buffer.writeln(_csvEncodeRow(['Project Date', settings.projectDate.toIso8601String()]));
    buffer.writeln(_csvEncodeRow(['Roll Number', settings.rollNumber]));
    buffer.writeln(_csvEncodeRow(['Channel Count', settings.channelCount.toString()]));
  }

  String _buildHeader() {
    final headers = [
      'ID',
      'File Name',
      'Start TC',
      'Scene',
      'Shot',
      'Take',
      'Discarded',
      'Notes',
      'Created At',
      for (var i = 1; i <= RecordingEntry.maxTracks; i++) 'Track $i',
      for (var i = 1; i <= RecordingEntry.maxTracks; i++) 'Track ${i} Enabled',
    ];
    return _csvEncodeRow(headers);
  }

  String _buildRow(RecordingEntry entry) {
    final values = [
      entry.id?.toString() ?? '',
      entry.fileName,
      entry.startTC,
      entry.scene,
      entry.take,
      entry.slate,
      entry.isDiscarded ? 'Yes' : 'No',
      entry.notes,
      entry.createdAt.toIso8601String(),
      for (var i = 0; i < RecordingEntry.maxTracks; i++) entry.tracks[i] ?? '',
      for (var i = 0; i < RecordingEntry.maxTracks; i++) entry.trackChecked[i] ? 'Yes' : 'No',
    ];
    return _csvEncodeRow(values);
  }

  String _csvEncodeRow(List<String> values) {
    return values.map((value) {
      final needsQuotes = value.contains(',') ||
          value.contains('"') ||
          value.contains('\n') ||
          value.contains('\r');

      if (needsQuotes) {
        final escaped = value.replaceAll('"', '""');
        return '"$escaped"';
      }
      return value;
    }).join(',');
  }
}
