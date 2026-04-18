import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:reporter/data/repositories/local_preferences_repository.dart';
import 'package:reporter/models/app_settings.dart';
import 'package:reporter/models/recording_entry.dart';
import 'package:reporter/repositories/recording_repository.dart';
import 'package:reporter/repositories/settings_repository.dart';

class PdfGenerator {
  final RecordingRepository _recordingRepository;
  final SettingsRepository _settingsRepository;
  final LocalPreferencesRepository _preferencesRepository;

  PdfGenerator({
    required RecordingRepository recordingRepository,
    required SettingsRepository settingsRepository,
    required LocalPreferencesRepository preferencesRepository,
  })  : _recordingRepository = recordingRepository,
        _settingsRepository = settingsRepository,
        _preferencesRepository = preferencesRepository;

  Future<void> generateRecordingReport() async {
    try {
      final chineseFont = await _loadChineseFont();
      final logoBytes = await _loadLogoImage();

      List<RecordingEntry> allEntries;
      try {
        allEntries = await _recordingRepository.getAllRecordings();
      } catch (e) {
        throw Exception('获取录音记录失败: $e');
      }

      AppSettings? appSettings;
      try {
        appSettings = await _settingsRepository.getSettings();
      } catch (e) {
        debugPrint('获取应用设置失败: $e');
      }

      final preferences = await _preferencesRepository.getPreferences();

      final includeDiscarded = preferences?.includeDiscardedInPDF ?? true;
      final entries = includeDiscarded
          ? allEntries
          : allEntries.where((entry) => !entry.isDiscarded).toList();

      if (entries.isEmpty) {
        throw Exception('没有可导出的录音记录');
      }

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: chineseFont),
      );

      final pages = _buildPdfContent(entries, appSettings, logoBytes, chineseFont);

      for (var page in pages) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(30),
            build: (context) => page,
          ),
        );
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => pdf.save(),
      );
    } catch (e, stackTrace) {
      debugPrint('生成PDF失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      rethrow;
    }
  }

  List<pw.Widget> _buildPdfContent(
    List<RecordingEntry> entries,
    AppSettings? appSettings,
    Uint8List logoBytes,
    pw.Font chineseFont,
  ) {
    final channelCount = appSettings?.channelCount ?? 8;
    final pages = <pw.Widget>[];
    var currentStart = 0;

    pw.Widget buildFirstPage(List<RecordingEntry> entries, AppSettings? appSettings,
        Uint8List logoBytes, pw.Font chineseFont, int channelCount) {
      return pw.Stack(
        children: [
          _buildLogo(logoBytes),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(text: '同期录音报告', level: 0, textStyle: pw.TextStyle(font: chineseFont, fontSize: 40)),
              _buildInfoTable(appSettings, chineseFont),
              pw.SizedBox(height: 20),
              _buildRecordingTable(entries, chineseFont, channelCount),
              if (entries.length == entries.length) _buildSignatureArea(chineseFont)
            ],
          ),
        ],
      );
    }
    final pageFormat = PdfPageFormat.a4;
    final rowHeight = 15;
    
    final firstPageHeight = pageFormat.height - 200 - 200;
    final firstPageMaxEntries = (firstPageHeight / (rowHeight * 2)).floor();
    
    if (entries.isNotEmpty) {
      final firstPageEnd = firstPageMaxEntries.clamp(0, entries.length);
      final firstPageEntries = entries.sublist(0, firstPageEnd);
      pages.add(buildFirstPage(firstPageEntries, appSettings, logoBytes, chineseFont, channelCount));
      currentStart = firstPageEnd;
    }

    final subsequentPageHeight = pageFormat.height - 5;
    final subsequentPageMaxEntries = (subsequentPageHeight / (rowHeight * 2)).floor();
    
    while (currentStart < entries.length) {
      final currentEnd = (currentStart + subsequentPageMaxEntries).clamp(0, entries.length);
      final pageEntries = entries.sublist(currentStart, currentEnd);
      currentStart = currentEnd;
      
      pages.add(
        pw.Stack(
          children: [
            _buildLogo(logoBytes),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(text: '同期录音报告', level: 0, textStyle: pw.TextStyle(font: chineseFont, fontSize: 40)),
                pw.SizedBox(height: 20),
                _buildRecordingTable(pageEntries, chineseFont, channelCount),
                if (currentEnd >= entries.length) _buildSignatureArea(chineseFont)
              ],
            ),
          ],
        )
      );
    }
    
    final trackNameChanges = _getTrackNameChanges(entries, channelCount);
    if (entries.isNotEmpty) {
      pages.add(
        pw.Stack(
          children: [
            _buildLogo(logoBytes),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(text: '轨道总览', level: 0, textStyle: pw.TextStyle(font: chineseFont, fontSize: 40)),
                pw.SizedBox(height: 20),
                _buildTrackNamesTable(entries, trackNameChanges, chineseFont, channelCount),
              ],
            ),
          ],
        )
      );
    }
    
    return pages;
  }

  Future<pw.Font> _loadChineseFont() async {
    final fontData = await rootBundle.load('assets/fonts/NotoSansSCMedium-4.ttf');
    return pw.Font.ttf(fontData);
  }

  Future<Uint8List> _loadLogoImage() async {
    final logoData = await rootBundle.load('assets/fonts/logo.png');
    return logoData.buffer.asUint8List();
  }

  pw.Widget _buildLogo(Uint8List logoBytes) {
    return pw.Positioned(
      right: 20,
      top: 5,
      child: pw.Image(
        pw.MemoryImage(logoBytes),
        width: 160,
        height: 160,
      ),
    );
  }

  pw.Table _buildInfoTable(AppSettings? appSettings, pw.Font chineseFont) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(2)},
      children: [
        _buildTableRow('项目名称', appSettings?.projectName ?? '', chineseFont),
        _buildTableRow('制作公司', appSettings?.productionCompany ?? '', chineseFont),
        _buildTableRow('录音师', appSettings?.soundEngineer ?? '', chineseFont),
        _buildTableRow('话筒员', appSettings?.boomOperator ?? '', chineseFont),
        _buildTableRow('设备型号', appSettings?.equipmentModel ?? '', chineseFont),
        _buildTableRow('文件格式', appSettings?.fileFormat ?? '', chineseFont),
        _buildTableRow('帧率', '${appSettings?.frameRate.toStringAsFixed(2) ?? ''} fps', chineseFont),
        _buildTableRow('项目日期', _formatProjectDate(appSettings), chineseFont),
        _buildTableRow('卷号', appSettings?.rollNumber ?? '', chineseFont),
      ],
    );
  }

  pw.TableRow _buildTableRow(String label, String value, pw.Font font) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(font: font)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: pw.TextStyle(font: font)),
        ),
      ],
    );
  }

  String _formatProjectDate(AppSettings? appSettings) {
    return appSettings?.projectDate != null
        ? '${appSettings!.projectDate.year}年${appSettings.projectDate.month}月${appSettings.projectDate.day}日'
        : '';
  }

  pw.Widget _buildRecordingTable(
    List<RecordingEntry> entries,
    pw.Font chineseFont,
    int channelCount,
  ) {
    final headers = _getTableHeaders(channelCount);
    final trackNameChanges = _getTrackNameChanges(entries, channelCount);
    
    final changedTracksMap = <int, Set<int>>{};
    for (var change in trackNameChanges) {
      final entryIndex = change['entryIndex'] as int;
      final prevTracks = change['prevTracks'] as List<String?>;
      final currentTracks = change['currentTracks'] as List<String?>;
      
      final changedTracks = <int>{};
      for (var trackIdx = 0; trackIdx < channelCount; trackIdx++) {
        final prevName = prevTracks[trackIdx];
        final currentName = currentTracks[trackIdx];
        if (prevName != null && prevName.isNotEmpty && 
            currentName != null && currentName.isNotEmpty &&
            prevName != currentName) {
          changedTracks.add(trackIdx);
        }
      }
      if (changedTracks.isNotEmpty) {
        changedTracksMap[entryIndex] = changedTracks;
      }
    }
    
    return pw.Builder(
      builder: (context) {
        final table = pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: headers.map((header) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    header,
                    style: pw.TextStyle(
                      font: chineseFont,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            ...entries.asMap().entries.map((entry) {
              final index = entry.key;
              final e = entry.value;
              final rowData = _formatEntry(e, channelCount);
              final changedTracks = changedTracksMap[index] ?? <int>{};
              
              return pw.TableRow(
                children: rowData.asMap().entries.map((cell) {
                  final cellIndex = cell.key;
                  final cellValue = cell.value;
                  final isTrackCell = cellIndex >= 6 && cellIndex < 6 + channelCount;
                  final isChecked = isTrackCell && cellValue == '■';
                  
                  final bgColor = e.isDiscarded ? PdfColors.red50 : null;
                  
                  if (isTrackCell) {
                    final trackIdx = cellIndex - 6;
                    final hasChanged = changedTracks.contains(trackIdx);
                    final trackName = e.tracks[trackIdx] ?? '';
                    
                    final cellColor = hasChanged ? PdfColors.yellow200 : (isChecked ? PdfColors.green50 : bgColor);
                    
                    return pw.Container(
                      color: cellColor,
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          if (hasChanged)
                            pw.Container(
                              margin: const pw.EdgeInsets.only(right: 2),
                              width: 10,
                              height: 10,
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                color: PdfColors.yellow,
                                border: pw.Border.all(color: PdfColors.black, width: 1),
                              ),
                            ),
                          if (isChecked && !hasChanged)
                            pw.Text(
                              '✓',
                              style: pw.TextStyle(
                                font: chineseFont,
                                fontSize: 14,
                              ),
                            ),
                          if (hasChanged && trackName.isNotEmpty)
                            pw.Text(
                              trackName,
                              style: pw.TextStyle(font: chineseFont),
                            ),
                        ],
                      ),
                    );
                  }
                  
                  return pw.Container(
                    color: bgColor,
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      cellValue,
                      style: pw.TextStyle(font: chineseFont),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        );
        return table;
      },
    );
  }

  List<Map<String, dynamic>> _getTrackNameChanges(List<RecordingEntry> entries, int channelCount) {
    final changes = <Map<String, dynamic>>[];
    for (var i = 1; i < entries.length; i++) {
      final prevEntry = entries[i - 1];
      final currentEntry = entries[i];
      
      bool hasAnyChange = false;
      for (var trackIdx = 0; trackIdx < channelCount; trackIdx++) {
        final prevTrackName = prevEntry.tracks[trackIdx];
        final currentTrackName = currentEntry.tracks[trackIdx];
        
        if (prevTrackName != null && prevTrackName.isNotEmpty && 
            currentTrackName != null && currentTrackName.isNotEmpty &&
            prevTrackName != currentTrackName) {
          hasAnyChange = true;
          break;
        }
      }
      
      if (hasAnyChange) {
        changes.add({
          'entryIndex': i,
          'fileName': currentEntry.fileName,
          'prevTracks': prevEntry.tracks,
          'currentTracks': currentEntry.tracks,
        });
      }
    }
    return changes;
  }

  List<String> _getTableHeaders(int channelCount) {
    return [
      '文件名',
      'StartTC',
      '场',
      '镜',
      '次',
      '标签',
      ...List.generate(channelCount, (i) => '${i + 1}'),
      '备注',
    ];
  }

  List<String> _formatEntry(RecordingEntry entry, int channelCount) {
    final trackValues = List.generate(channelCount, (index) {
      final track = entry.tracks[index];
      if (track == null || track.isEmpty) return '';
      return entry.trackChecked[index] ? '■' : '';
    });
    
    return [
      entry.fileName,
      entry.startTC,
      entry.scene,
      entry.take,
      entry.slate,
      entry.isDiscarded ? '废' : '过/保',
      ...trackValues,
      entry.notes,
    ];
  }

  pw.Widget _buildSignatureArea(pw.Font chineseFont) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 30),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('录音师签名：__________', style: pw.TextStyle(font: chineseFont)),
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 10),
            child: pw.Divider(thickness: 1, color: PdfColors.black),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTrackNamesTable(
    List<RecordingEntry> entries,
    List<Map<String, dynamic>> changes,
    pw.Font chineseFont,
    int channelCount,
  ) {
    final changeSet = <int, Set<int>>{};
    for (var change in changes) {
      final entryIndex = change['entryIndex'] as int;
      final prevTracks = change['prevTracks'] as List<String?>;
      final currentTracks = change['currentTracks'] as List<String?>;
      
      final changedTracks = <int>{};
      for (var trackIdx = 0; trackIdx < channelCount; trackIdx++) {
        final prevName = prevTracks[trackIdx];
        final currentName = currentTracks[trackIdx];
        if (prevName != null && prevName.isNotEmpty && 
            currentName != null && currentName.isNotEmpty &&
            prevName != currentName) {
          changedTracks.add(trackIdx);
        }
      }
      if (changedTracks.isNotEmpty) {
        changeSet[entryIndex] = changedTracks;
      }
    }
    
    final entriesToShow = <int>{0};
    for (var change in changes) {
      entriesToShow.add(change['entryIndex'] as int);
    }
    
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('录音文件', style: pw.TextStyle(font: chineseFont, fontWeight: pw.FontWeight.bold)),
            ),
            ...List.generate(channelCount, (trackIdx) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('轨道${trackIdx + 1}', style: pw.TextStyle(font: chineseFont, fontWeight: pw.FontWeight.bold)),
              );
            }),
          ],
        ),
        ...entries.asMap().entries.where((entry) => entriesToShow.contains(entry.key)).map((entry) {
          final index = entry.key;
          final e = entry.value;
          final changedTracks = changeSet[index] ?? <int>{};
          
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(e.fileName, style: pw.TextStyle(font: chineseFont)),
              ),
              ...List.generate(channelCount, (trackIdx) {
                final trackName = e.tracks[trackIdx] ?? '';
                final hasChanged = changedTracks.contains(trackIdx);
                
                return pw.Container(
                  color: hasChanged ? PdfColors.yellow200 : null,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      if (hasChanged)
                        pw.Container(
                          margin: const pw.EdgeInsets.only(right: 4),
                          width: 12,
                          height: 12,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            color: PdfColors.yellow,
                            border: pw.Border.all(color: PdfColors.black, width: 1),
                          ),
                        ),
                      pw.Text(
                        trackName,
                        style: pw.TextStyle(font: chineseFont),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }
}