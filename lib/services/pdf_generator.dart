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

class PdfGenerator {
  final DatabaseHelper _dbHelper;
  final BuildContext context;

  PdfGenerator(this._dbHelper, this.context);

  Future<void> generateRecordingReport() async {
    final chineseFont = await _loadChineseFont();
    final logoBytes = await _loadLogoImage();
    final entries = await _dbHelper.getAllRecordingEntries();
    final trackConfig = await _dbHelper.getLatestTrackConfig();
    final appSettings = await _dbHelper.getAppSettings();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: chineseFont),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => _buildPdfContent(
          entries,
          trackConfig,
          appSettings,
          logoBytes,
          chineseFont,
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => pdf.save(),
    );
  }

  pw.Widget _buildPdfContent(
    List<RecordingEntry> entries,
    TrackConfig? trackConfig,
    AppSettings? appSettings,
    Uint8List logoBytes,
    pw.Font chineseFont,
  ) {
    return pw.Stack(
      children: [
        _buildLogo(logoBytes),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(text: '同期录音报告', level: 0, textStyle: pw.TextStyle(font: chineseFont, fontSize: 40)),
            _buildInfoTable(appSettings, chineseFont),
            pw.SizedBox(height: 20),
            _buildRecordingTable(entries, trackConfig, chineseFont),
            _buildSignatureArea(chineseFont),
          ],
        ),
      ],
    );
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
      top: 20,
      child: pw.Image(
        pw.MemoryImage(logoBytes),
        width: 200,
        height: 200,
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
    TrackConfig? trackConfig,
    pw.Font chineseFont,
  ) {
    return pw.Table.fromTextArray(
      headers: _getTableHeaders(trackConfig),
      data: entries.map((e) => _formatEntry(e, trackConfig)).toList(),
      headerStyle: pw.TextStyle(font: chineseFont),
      cellStyle: pw.TextStyle(font: chineseFont),
    );
  }

  List<String> _getTableHeaders(TrackConfig? trackConfig) {
    return [
      '文件名',
      'StartTC',
      '场',
      '镜',
      '次',
      '标签',
      ...trackConfig?.trackNames ?? [],
      '备注',
    ];
  }

  List<String> _formatEntry(RecordingEntry entry, TrackConfig? trackConfig) {
    return [
      entry.fileName,
      entry.startTC,
      entry.scene,
      entry.take,
      entry.slate,
      entry.isDiscarded ? '废' : '过/保',
      ...List.generate(trackConfig?.trackNames.length ?? 0, (_) => ''),
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
}