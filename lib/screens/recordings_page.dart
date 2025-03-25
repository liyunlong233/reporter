import 'dart:convert' as PdfEncoding;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:reporter/database/database_helper.dart';
import 'package:reporter/models/recording_entry.dart';
import 'package:reporter/models/track_config.dart';

class RecordingsPage extends StatefulWidget {
  const RecordingsPage({super.key});

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  final _dbHelper = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();
  final List<RecordingEntry> _entries = [];
  TrackConfig? _currentTrackConfig;
  int? _currentEntryId;
  final TextEditingController _fileNameController = TextEditingController();
  final TextEditingController _startTCController = TextEditingController();
  final TextEditingController _sceneController = TextEditingController();
  final TextEditingController _takeController = TextEditingController();
  final TextEditingController _slateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isDiscarded = false;

  @override
  void initState() {
    super.initState();
    _loadTrackConfig();
    _loadExistingRecordings();
    _loadLastInputValues();
  }

  Future<void> _loadLastInputValues() async {
    final lastEntry = await _dbHelper.getLatestRecordingEntry();
    if (lastEntry != null) {
      _currentEntryId = lastEntry.id;
      _fileNameController.text = lastEntry.fileName;
      _startTCController.text = lastEntry.startTC;
      _sceneController.text = lastEntry.scene;
      _takeController.text = lastEntry.take;
      _slateController.text = lastEntry.slate;
      _notesController.text = lastEntry.notes;
      _isDiscarded = lastEntry.isDiscarded;
    }
  }

  Future<void> _saveCurrentInput() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fileNameController.text.isEmpty) return;
    
    final entry = RecordingEntry(
      id: _currentEntryId,
      fileName: _fileNameController.text,
      startTC: _startTCController.text,
      scene: _sceneController.text,
      take: _takeController.text,
      slate: _slateController.text,
      notes: _notesController.text,
      isDiscarded: _isDiscarded,
      trackConfigId: _currentTrackConfig?.id ?? 0,
    );
    await _dbHelper.saveRecordingEntry(entry);
  }

  void _clearForm() {
    _currentEntryId = null;
    _fileNameController.clear();
    _startTCController.clear();
    _sceneController.clear();
    _takeController.clear();
    _slateController.clear();
    _notesController.clear();
    _isDiscarded = false;
    _formKey.currentState?.reset();
  }

  Future<void> _loadTrackConfig() async {
    final config = await _dbHelper.getLatestTrackConfig();
    setState(() => _currentTrackConfig = config);
  }

  Future<void> _loadExistingRecordings() async {
    final entries = await _dbHelper.getAllRecordingEntries();
    setState(() => _entries
      ..clear()
      ..addAll(entries));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveCurrentInput();
        return true;
      },
      child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('录音记录'),
        actions: [IconButton(onPressed: _generatePDF, icon: const Icon(Icons.picture_as_pdf))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextFormField('文件名', _fileNameController),
              const SizedBox(height: 16),
              _buildTextFormField('StartTC', _startTCController),
              const SizedBox(height: 16),
              _buildTextFormField('场', _sceneController),
              const SizedBox(height: 16),
              _buildTextFormField('镜', _takeController),
              const SizedBox(height: 16),
              _buildTextFormField('次', _slateController),
              const SizedBox(height: 24),
              _buildDiscardSwitch(),
              _buildTextFormField('备注', _notesController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addEntry,
                child: const Text('添加记录', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 30),
              ..._buildEntryList(),
            ],
          ),
        ),
      ),
    )
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        validator: (value) => label == '文件名' ? (value!.isEmpty ? '请输入$label' : null) : null,
      ),
    );
  }

  Widget _buildDiscardSwitch() {
    return SwitchListTile(
      title: const Text('标记为废弃'),
      value: _isDiscarded,
      onChanged: (value) => setState(() => _isDiscarded = value),
    );
  }

  Future<void> _addEntry() async {
    _currentEntryId = null;
    if (_formKey.currentState!.validate()) {
      final entry = RecordingEntry(
        fileName: _fileNameController.text,
        startTC: _startTCController.text,
        scene: _sceneController.text,
        take: _takeController.text,
        slate: _slateController.text,
        isDiscarded: _isDiscarded,
        notes: _notesController.text,
        trackConfigId: _currentTrackConfig?.id ?? 0,
      );

      await _dbHelper.saveRecordingEntry(entry);
      setState(() => _entries.add(entry));
      _clearForm();
    }
  }

  Future<void> _generatePDF() async {
    final chineseFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf'));
    final ByteData logoData = await rootBundle.load('assets/fonts/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: chineseFont,
        bold: chineseFont,
        italic: chineseFont,
        boldItalic: chineseFont,
      ),
    );

    final entries = await _dbHelper.getAllRecordingEntries();
    final trackConfig = await _dbHelper.getLatestTrackConfig();
    final appSettings = await _dbHelper.getAppSettings();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => pw.Stack(
          children: [
            pw.Positioned(
              right: 20,
              top: 20,
              child: pw.Image(
                pw.MemoryImage(logoBytes),
                width: 200,
                height: 200,
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 30),
                pw.Header(text: '同期录音报告', level: 0, textStyle: pw.TextStyle(font: chineseFont, fontSize: 40)),
            // 主信息表
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(2)
              },
              children: [
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('项目名称', style: pw.TextStyle(font: chineseFont)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(appSettings?.projectName ?? '', style: pw.TextStyle(font: chineseFont)),
                  )
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('制作公司', style: pw.TextStyle(font: chineseFont)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(appSettings?.productionCompany ?? '', style: pw.TextStyle(font: chineseFont)),
                  )
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('录音师', style: pw.TextStyle(font: chineseFont)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(appSettings?.soundEngineer ?? '', style: pw.TextStyle(font: chineseFont)),
                  )
                ]),
                                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('话筒员', style: pw.TextStyle(font: chineseFont)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(appSettings?.boomOperator ?? '', style: pw.TextStyle(font: chineseFont)),
                  )
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('设备型号', style: pw.TextStyle(font: chineseFont)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(appSettings?.equipmentModel ?? '', style: pw.TextStyle(font: chineseFont)),
                  )
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('文件格式', style: pw.TextStyle(font: chineseFont)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(appSettings?.fileFormat ?? '', style: pw.TextStyle(font: chineseFont)),
                  )
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('帧率', style: pw.TextStyle(font: chineseFont)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${appSettings?.frameRate.toStringAsFixed(2) ?? ''} fps', style: pw.TextStyle(font: chineseFont)),
                  )
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('项目日期', style: pw.TextStyle(font: chineseFont)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(appSettings?.projectDate != null ? 
                      '${appSettings!.projectDate.year}年${appSettings!.projectDate.month}月${appSettings!.projectDate.day}日' : '', 
                      style: pw.TextStyle(font: chineseFont)),
                  )
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('卷号', style: pw.TextStyle(font: chineseFont)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(appSettings?.rollNumber ?? '', style: pw.TextStyle(font: chineseFont)),
                  )
                ]),
              ],
            ),
            pw.SizedBox(height: 20),
            // 录音记录表
            pw.Table.fromTextArray(
              headers: ['文件名', 'StartTC', '场', '镜', '次', '标签', ..._getTrackHeaders(_currentTrackConfig), '备注'],
              data: entries.map((e) => _formatEntry(e)).toList(),
              headerStyle: pw.TextStyle(font: chineseFont),
              cellStyle: pw.TextStyle(font: chineseFont),
            ),
            // 签名区域
            pw.Container(
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
            ),
          ],
          ),
          ]
        )
      
    )
      );


    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => pdf.save(),
    );
  }

  List<String> _getTrackHeaders(TrackConfig? config) {
    return _currentTrackConfig != null 
      ? _currentTrackConfig!.trackNames
      : [];
  }

  List<String> _formatEntry(RecordingEntry entry) {
    return [
      entry.fileName,
      entry.startTC,
      entry.scene,
      entry.take,
      entry.slate,
      entry.isDiscarded ? '废' : '过/保',
      ...List.generate(_currentTrackConfig?.trackNames.length ?? 0, (_) => ''),
      entry.notes
    ];
  }

  

  List<Widget> _buildEntryList() {
    return _entries.map((entry) => ListTile(
      title: Text(entry.fileName),
      subtitle: Text('场镜次: ${entry.scene}-${entry.take}-${entry.slate}'),
      trailing: Text(entry.isDiscarded ? '已废弃' : '正常', style: TextStyle(
        color: entry.isDiscarded ? Colors.red : Colors.green,
      )),
    )).toList();
  }
}