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
import 'package:reporter/services/pdf_generator.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadTrackConfig();
      await _loadExistingRecordings();
      await _loadLastInputValues();
    });
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _startTCController.dispose();
    _sceneController.dispose();
    _takeController.dispose();
    _slateController.dispose();
    _notesController.dispose();
    _currentEntryId = null; // 新增状态清理
    super.dispose();
  }

  Future<void> _saveCurrentInput() async {
    if (_currentEntryId == null && !_isDiscarded) {
      final newEntry = await _dbHelper.saveRecordingEntry(
        RecordingEntry(
          fileName: _fileNameController.text,
          startTC: _startTCController.text,
          scene: _sceneController.text,
          take: _takeController.text,
          slate: _slateController.text,
          notes: _notesController.text,
          isDiscarded: _isDiscarded,
          trackConfigId: _currentTrackConfig?.id ?? 0,
          createdAt: DateTime.now(),
        ),
      );
      setState(() => _currentEntryId = newEntry);
    }
  }

  Future<void> _clearForm() async {
    setState(() {
      _currentEntryId = null;
      _isDiscarded = false;
      _fileNameController.clear();
      _startTCController.clear();
      _sceneController.clear();
      _takeController.clear();
      _slateController.clear();
      _notesController.clear();
    });
    await _loadExistingRecordings();
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
        if (Platform.isIOS) {
          await _saveCurrentInput();
          return true;
        }
        final shouldPop = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('保存更改'),
            content: const Text('是否要保存当前输入再退出？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  await _saveCurrentInput();
                  Navigator.pop(context, true);
                },
                child: const Text('保存'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
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
              Row(
                children: [
                  Expanded(child: _buildTextFormField('StartTC', _startTCController)),
                  IconButton(
                    icon: Icon(Icons.access_time),
                    onPressed: () {
                      final now = DateTime.now();
                      final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}:00';
                      _startTCController.text = formattedTime;
                    },
                  ),
                ],
              ),
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

  Future<void> _autoFillStartTC() async {
    if (_startTCController.text.isEmpty) {
      final now = DateTime.now();
      _startTCController.text = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}:00';
    }
  }

  Future<void> _addEntry() async {
    await _autoFillStartTC();
    _currentEntryId = null;
    if (_formKey.currentState!.validate()) {
      final currentFileName = _fileNameController.text;
      final match = RegExp(r'(\D*)(\d+)').firstMatch(currentFileName);
      final prefix = match?.group(1) ?? '';
      final numberStr = match?.group(2) ?? '000';
      
      try {
        var number = int.parse(numberStr);
        number++;
        final newFileName = '$prefix${number.toString().padLeft(3, '0')}';
        
        final entry = RecordingEntry(
          fileName: currentFileName,
          startTC: _startTCController.text,
          scene: _sceneController.text,
          take: _takeController.text,
          slate: _slateController.text,
          isDiscarded: _isDiscarded,
          notes: _notesController.text,
          trackConfigId: _currentTrackConfig?.id ?? 0,
          createdAt: DateTime.now(),
        );

        await _dbHelper.saveRecordingEntry(entry);
        setState(() => _entries.add(entry));
        _clearForm();
        _fileNameController.text = newFileName;
      } catch (e) {
        _fileNameController.text = currentFileName;
        _clearForm();
      }
    }
  }

  Future<void> _generatePDF() async {
    final pdfGenerator = PdfGenerator(_dbHelper, context);
    await pdfGenerator.generateRecordingReport();
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