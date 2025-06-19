import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:reporter/database/database_helper.dart';
import 'package:reporter/models/app_settings.dart';
import 'package:reporter/models/recording_entry.dart';
import 'package:reporter/models/track_config.dart';

class PdfConfig {
  final bool includeProjectInfo;
  final bool includeTracks;
  final bool includeNotes;
  final bool includeDiscarded;
  final List<String> selectedTracks;
  final String? customTitle;
  final String? customFooter;

  const PdfConfig({
    this.includeProjectInfo = true,
    this.includeTracks = true,
    this.includeNotes = true,
    this.includeDiscarded = false,
    this.selectedTracks = const [],
    this.customTitle,
    this.customFooter,
  });
}

class PdfGenerator {
  final DatabaseHelper _dbHelper;
  final BuildContext context;
  final PdfConfig config;
  final Function(double)? onProgress;

  PdfGenerator(
    this._dbHelper,
    this.context, {
    this.config = const PdfConfig(),
    this.onProgress,
  });

  Future<void> generateRecordingReport() async {
    try {
      final chineseFont = await _loadChineseFont();
      final logoBytes = await _loadLogoImage();
      
      // 使用分页查询获取数据
      final totalCount = await _dbHelper.getRecordingEntriesCount(
        isDiscarded: config.includeDiscarded ? null : false,
      );
      
      final pageSize = 100;
      final totalPages = (totalCount / pageSize).ceil();
      final allEntries = <RecordingEntry>[];
      
      for (var page = 1; page <= totalPages; page++) {
        final entries = await _dbHelper.getRecordingEntries(
          page: page,
          pageSize: pageSize,
          isDiscarded: config.includeDiscarded ? null : false,
        );
        allEntries.addAll(entries);
        
        // 更新进度
        if (onProgress != null) {
          onProgress!(page / totalPages);
        }
      }

      // 按文件名升序排序录音条目
      allEntries.sort((a, b) => a.fileName.compareTo(b.fileName));

      final appSettings = await _dbHelper.getAppSettings();

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: chineseFont),
      );

      final pages = _buildPdfContent(allEntries, appSettings, logoBytes, chineseFont);

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成PDF时出错: $e')),
      );
    }
  }

  List<pw.Widget> _buildPdfContent(
    List<RecordingEntry> entries,
    AppSettings? appSettings,
    Uint8List logoBytes,
    pw.Font chineseFont,
  ) {
    final pages = <pw.Widget>[];
    var currentStart = 0;

    pw.Widget _buildFirstPage(List<RecordingEntry> entries, AppSettings? appSettings,
        Uint8List logoBytes, pw.Font chineseFont) {
      return pw.Stack(
        children: [
          _buildLogo(logoBytes),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                text: config.customTitle ?? '同期录音报告',
                level: 0,
                textStyle: pw.TextStyle(font: chineseFont, fontSize: 40)
              ),
              if (config.includeProjectInfo) _buildInfoTable(appSettings, chineseFont),
              pw.SizedBox(height: 20),
              _buildRecordingTable(entries, chineseFont),
              if (entries.length == entries.length) _buildSignatureArea(chineseFont),
              if (config.customFooter != null)
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 20),
                  child: pw.Text(
                    config.customFooter!,
                    style: pw.TextStyle(font: chineseFont, fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
            ],
          ),
        ],
      );
    }

    final pageFormat = PdfPageFormat.a4;
    final rowHeight = 15;
    
    // 首页布局
    final firstPageHeight = pageFormat.height - 200 - (config.includeProjectInfo ? 200 : 0);
    final firstPageMaxEntries = (firstPageHeight / (rowHeight * 2)).floor();
    
    if (entries.isNotEmpty) {
      final firstPageEnd = firstPageMaxEntries.clamp(0, entries.length);
      final firstPageEntries = entries.sublist(0, firstPageEnd);
      pages.add(_buildFirstPage(firstPageEntries, appSettings, logoBytes, chineseFont));
      currentStart = firstPageEnd;
    }

    // 后续页面
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
                pw.Header(
                  text: config.customTitle ?? '同期录音报告',
                  level: 0,
                  textStyle: pw.TextStyle(font: chineseFont, fontSize: 40)
                ),
                pw.SizedBox(height: 20),
                _buildRecordingTable(pageEntries, chineseFont),
                if (currentEnd >= entries.length) _buildSignatureArea(chineseFont),
                if (config.customFooter != null)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 20),
                    child: pw.Text(
                      config.customFooter!,
                      style: pw.TextStyle(font: chineseFont, fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
              ],
            ),
          ],
        )
      );
    }
    
    return pages;
  }

  Future<pw.Font> _loadChineseFont() async {
    final fontData = await rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf');
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

  pw.Table _buildRecordingTable(List<RecordingEntry> entries, pw.Font chineseFont) {
    final headers = _getTableHeaders();
    final data = entries.map((e) => _formatEntry(e)).toList();
    
    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(font: chineseFont),
      cellStyle: pw.TextStyle(font: chineseFont),
    );
  }

  List<String> _getTableHeaders() {
    final headers = ['文件名', 'StartTC', '场', '镜', '次', '标签'];
    
    if (config.includeTracks) {
      if (config.selectedTracks.isEmpty) {
        headers.addAll(List.generate(8, (index) => '轨道${index + 1}'));
      } else {
        headers.addAll(config.selectedTracks);
      }
    }
    
    if (config.includeNotes) {
      headers.add('备注');
    }
    
    return headers;
  }

  List<String> _formatEntry(RecordingEntry entry) {
    final values = [
      entry.fileName,
      entry.startTC,
      entry.scene,
      entry.take,
      entry.slate,
      entry.isDiscarded ? '废' : '过/保',
    ];
    
    if (config.includeTracks) {
      if (config.selectedTracks.isEmpty) {
        values.addAll(entry.tracks.map((track) => track ?? ''));
      } else {
        final trackMap = Map.fromIterables(
          List.generate(8, (index) => '轨道${index + 1}'),
          entry.tracks,
        );
        values.addAll(config.selectedTracks.map((track) => trackMap[track] ?? ''));
      }
    }
    
    if (config.includeNotes) {
      values.add(entry.notes);
    }
    
    return values;
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
}