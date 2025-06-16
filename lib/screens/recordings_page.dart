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
  int? _currentEntryId;
  final TextEditingController _fileNameController = TextEditingController();
  final TextEditingController _startTCController = TextEditingController();
  final TextEditingController _sceneController = TextEditingController();
  final TextEditingController _takeController = TextEditingController();
  final TextEditingController _slateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isDiscarded = false;
  List<RecordingEntry> _filteredEntries = [];
  bool _showDiscarded = true;
  String _searchText = '';
  List<TextEditingController> _trackControllers = List.generate(8, (index) => TextEditingController());
  List<String> _lastTrackNames = List.generate(8, (index) => '');
  String _lastFileNamePrefix = 'REC_';
  int _lastFileNameNumber = 0;
  int _lastFileNameDigits = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
    for (var controller in _trackControllers) {
      controller.dispose();
    }
    _currentEntryId = null;
    super.dispose();
  }

  String _generateNextFileName() {
    _lastFileNameNumber++;
    return '$_lastFileNamePrefix${_lastFileNameNumber.toString().padLeft(_lastFileNameDigits, '0')}';
  }

  void _updateFileNameFormat(String fileName) {
    // 匹配文件名中的前缀和数字部分
    final match = RegExp(r'^(.+?)(\d+)$').firstMatch(fileName);
    if (match != null) {
      _lastFileNamePrefix = match.group(1)!;
      _lastFileNameNumber = int.parse(match.group(2)!);
      _lastFileNameDigits = match.group(2)!.length;
    }
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
          createdAt: DateTime.now(),
          track1: _trackControllers[0].text.isEmpty ? null : _trackControllers[0].text,
          track2: _trackControllers[1].text.isEmpty ? null : _trackControllers[1].text,
          track3: _trackControllers[2].text.isEmpty ? null : _trackControllers[2].text,
          track4: _trackControllers[3].text.isEmpty ? null : _trackControllers[3].text,
          track5: _trackControllers[4].text.isEmpty ? null : _trackControllers[4].text,
          track6: _trackControllers[5].text.isEmpty ? null : _trackControllers[5].text,
          track7: _trackControllers[6].text.isEmpty ? null : _trackControllers[6].text,
          track8: _trackControllers[7].text.isEmpty ? null : _trackControllers[7].text,
        ),
      );
      setState(() => _currentEntryId = newEntry);
    }
  }

  Future<void> _clearForm() async {
    setState(() {
      _currentEntryId = null;
      _isDiscarded = false;
      _startTCController.clear();
      _sceneController.clear();
      _takeController.clear();
      _slateController.clear();
      _notesController.clear();
      
      // 自动填充递增的文件名
      _fileNameController.text = _generateNextFileName();
      
      // 自动填充上次的轨道名称
      for (var i = 0; i < 8; i++) {
        _trackControllers[i].text = _lastTrackNames[i];
      }
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
      
      // 更新文件名格式
      _updateFileNameFormat(lastEntry.fileName);
      
      // 使用上次的轨道名称
      _trackControllers[0].text = lastEntry.track1 ?? _lastTrackNames[0];
      _trackControllers[1].text = lastEntry.track2 ?? _lastTrackNames[1];
      _trackControllers[2].text = lastEntry.track3 ?? _lastTrackNames[2];
      _trackControllers[3].text = lastEntry.track4 ?? _lastTrackNames[3];
      _trackControllers[4].text = lastEntry.track5 ?? _lastTrackNames[4];
      _trackControllers[5].text = lastEntry.track6 ?? _lastTrackNames[5];
      _trackControllers[6].text = lastEntry.track7 ?? _lastTrackNames[6];
      _trackControllers[7].text = lastEntry.track8 ?? _lastTrackNames[7];

      // 保存轨道名称以供下次使用
      for (var i = 0; i < 8; i++) {
        _lastTrackNames[i] = _trackControllers[i].text;
      }
    } else {
      // 如果没有之前的记录，初始化文件名和轨道名称
      _lastFileNamePrefix = 'REC_';
      _lastFileNameNumber = 0;
      _lastFileNameDigits = 3;
      _fileNameController.text = 'REC_001';
      for (var i = 0; i < 8; i++) {
        _trackControllers[i].text = '';
        _lastTrackNames[i] = '';
      }
    }
  }

  Future<void> _loadExistingRecordings() async {
    final entries = await _dbHelper.getAllRecordingEntries();
    setState(() {
      _entries.clear();
      _entries.addAll(entries);
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredEntries = _entries.where((entry) {
        final matchesSearch = _searchText.isEmpty ||
            entry.fileName.toLowerCase().contains(_searchText.toLowerCase()) ||
            entry.scene.toLowerCase().contains(_searchText.toLowerCase()) ||
            entry.take.toLowerCase().contains(_searchText.toLowerCase()) ||
            entry.slate.toLowerCase().contains(_searchText.toLowerCase()) ||
            entry.notes.toLowerCase().contains(_searchText.toLowerCase());

        final matchesDiscardFilter = _showDiscarded || !entry.isDiscarded;

        return matchesSearch && matchesDiscardFilter;
      }).toList();
    });
  }

  void _filterRecordings(bool showDiscarded, String searchText) {
    setState(() {
      _showDiscarded = showDiscarded;
      _searchText = searchText;
      _applyFilters();
    });
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
        actions: [
          IconButton(
            icon: Icon(_showDiscarded ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showDiscarded = !_showDiscarded;
                _applyFilters();
              });
            },
            tooltip: _showDiscarded ? '隐藏已删除' : '显示已删除',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePDF,
            tooltip: '生成PDF报告',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: '筛选记录',
          ),
        ],
      ),
        body: Column(
          children: [
            _buildQuickInputCard(),
            Expanded(
              child: _buildRecordingsList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _clearForm,
          child: const Icon(Icons.add),
          tooltip: '新建记录',
        ),
      ),
    );
  }

  Widget _buildQuickInputCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField('文件名', _fileNameController),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField('场', _sceneController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextFormField('镜', _takeController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextFormField('次', _slateController),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField('StartTC', _startTCController),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: _autoFillStartTC,
                    tooltip: '自动填充时码',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDiscardSwitch(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTextFormField('备注', _notesController),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('轨道设置'),
                    onPressed: _showTrackSettings,
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('清空'),
                    onPressed: _clearForm,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('保存'),
                    onPressed: _addEntry,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingsList() {
    return ListView.builder(
      itemCount: _filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = _filteredEntries[index];
        return Dismissible(
          key: Key(entry.id.toString()),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('确认删除'),
                  content: const Text('确定要删除这条记录吗？'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('删除'),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            _deleteEntry(entry);
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExpansionTile(
              title: Row(
                children: [
                  Expanded(
                    child: Text('${entry.scene} - ${entry.take}'),
                  ),
                  if (entry.isDiscarded)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red),
                      ),
                      child: const Text(
                        '已删除',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(entry.fileName),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('时码: ${entry.startTC}'),
                      Text('场记板: ${entry.slate}'),
                      if (entry.notes.isNotEmpty) Text('备注: ${entry.notes}'),
                      const SizedBox(height: 8),
                      _buildTrackChips(entry),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _editEntry(entry),
                            icon: const Icon(Icons.edit),
                            label: const Text('编辑'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _toggleDiscard(entry),
                            icon: Icon(entry.isDiscarded ? Icons.restore : Icons.delete_outline),
                            label: Text(entry.isDiscarded ? '恢复' : '废弃'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editEntry(RecordingEntry entry) async {
    setState(() {
      _currentEntryId = entry.id;
      _isDiscarded = entry.isDiscarded;
      _fileNameController.text = entry.fileName;
      _startTCController.text = entry.startTC;
      _sceneController.text = entry.scene;
      _takeController.text = entry.take;
      _slateController.text = entry.slate;
      _notesController.text = entry.notes;
      
      for (var i = 0; i < RecordingEntry.maxTracks; i++) {
        _trackControllers[i].text = entry.tracks[i] ?? '';
      }
    });
  }

  Future<void> _showFilterDialog() async {
    bool showDiscarded = true;
    String searchText = '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('筛选记录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: '搜索',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() => searchText = value);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('显示废弃记录'),
                value: showDiscarded,
                onChanged: (value) {
                  setState(() => showDiscarded = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                _filterRecordings(showDiscarded, searchText);
                Navigator.pop(context);
              },
              child: const Text('应用'),
            ),
          ],
        ),
      ),
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
      final now = DateTime.now();
      _startTCController.text = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}:00';
  }

  Future<void> _addEntry() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // 更新文件名格式
      _updateFileNameFormat(_fileNameController.text);
      
      final tracks = _trackControllers.map((c) => c.text.isEmpty ? null : c.text).toList();
      
      if (_currentEntryId != null) {
        // 如果是编辑现有条目，调用更新方法
        final existingEntry = _entries.firstWhere((entry) => entry.id == _currentEntryId);
        final updatedEntry = existingEntry.copyWith(
          fileName: _fileNameController.text,
          startTC: _startTCController.text,
          scene: _sceneController.text,
          take: _takeController.text,
          slate: _slateController.text,
          notes: _notesController.text,
          tracks: tracks,
        );
        await _updateEntry(updatedEntry);
      } else {
        // 如果是新条目，创建新记录
        final entry = RecordingEntry(
          fileName: _fileNameController.text,
          startTC: _startTCController.text,
          scene: _sceneController.text,
          take: _takeController.text,
          slate: _slateController.text,
          isDiscarded: false,
          notes: _notesController.text,
          createdAt: DateTime.now(),
          track1: tracks[0],
          track2: tracks[1],
          track3: tracks[2],
          track4: tracks[3],
          track5: tracks[4],
          track6: tracks[5],
          track7: tracks[6],
          track8: tracks[7],
        );

        await DatabaseHelper.instance.saveRecordingEntry(entry);
      }
      
      await _loadExistingRecordings();
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记录已保存')),
      );
    }
  }

  Future<void> _updateEntry(RecordingEntry entry) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final updatedEntry = entry.copyWith(
        fileName: _fileNameController.text,
        startTC: _startTCController.text,
        scene: _sceneController.text,
        take: _takeController.text,
        slate: _slateController.text,
        notes: _notesController.text,
        tracks: _trackControllers.map((c) => c.text.isEmpty ? null : c.text).toList(),
      );

      await _dbHelper.updateRecordingEntry(updatedEntry);
      await _loadExistingRecordings();
        _clearForm();
      }
  }

  Future<void> _deleteEntry(RecordingEntry entry) async {
    if (entry.id != null) {
      try {
        await _dbHelper.deleteRecordingEntry(entry.id!);
        await _loadExistingRecordings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记录已删除')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  Future<void> _generatePDF() async {
    final result = await showDialog<PdfConfig>(
      context: context,
      builder: (context) => PdfConfigDialog(),
    );

    if (result != null) {
      final pdfGenerator = PdfGenerator(
        _dbHelper,
        context,
        config: result,
        onProgress: (progress) {
          // 显示进度对话框
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('生成PDF'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('正在生成PDF报告...'),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).toInt()}%'),
                ],
              ),
            ),
          );
        },
      );

      try {
        await pdfGenerator.generateRecordingReport();
        if (context.mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF报告生成成功')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('生成PDF时出错: $e')),
          );
        }
      }
    }
  }

  List<String> _getTrackHeaders() {
    return List.generate(8, (index) => '轨道 ${index + 1}');
  }

  List<String> _formatEntry(RecordingEntry entry) {
    return [
      entry.fileName,
      entry.startTC,
      entry.scene,
      entry.take,
      entry.slate,
      entry.isDiscarded ? '废' : '过/保',
      entry.track1 ?? '',
      entry.track2 ?? '',
      entry.track3 ?? '',
      entry.track4 ?? '',
      entry.track5 ?? '',
      entry.track6 ?? '',
      entry.track7 ?? '',
      entry.track8 ?? '',
      entry.notes
    ];
  }

  Widget _buildTrackFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('轨道信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _showTrackSettings,
              icon: const Icon(Icons.settings),
              label: const Text('设置轨道名称'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: RecordingEntry.maxTracks,
          itemBuilder: (context, index) {
            return TextFormField(
              controller: _trackControllers[index],
              decoration: InputDecoration(
                labelText: '轨道 ${index + 1}',
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrackChips(RecordingEntry entry) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: entry.tracks
          .where((track) => track != null && track.isNotEmpty)
          .map((track) => _buildTrackChip(track))
          .toList(),
    );
  }

  Widget _buildTrackChip(String? trackName) {
    if (trackName == null || trackName.isEmpty) return const SizedBox.shrink();
    return Chip(
      label: Text(trackName),
      backgroundColor: Colors.blue.withOpacity(0.1),
      labelStyle: const TextStyle(color: Colors.blue),
    );
  }

  Future<void> _toggleDiscard(RecordingEntry entry) async {
    final updatedEntry = entry.copyWith(isDiscarded: !entry.isDiscarded);
    await DatabaseHelper.instance.updateRecordingEntry(updatedEntry);
    await _loadExistingRecordings();
  }

  Future<void> _showTrackSettings() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => TrackSettingsDialog(
        initialTrackNames: _trackControllers.map((c) => c.text).toList(),
      ),
    );

    if (result != null) {
      setState(() {
        for (var i = 0; i < 8; i++) {
          _trackControllers[i].text = result[i];
          _lastTrackNames[i] = result[i];
        }
      });
    }
  }
}

class TrackSettingsDialog extends StatefulWidget {
  final List<String> initialTrackNames;

  const TrackSettingsDialog({
    super.key,
    required this.initialTrackNames,
  });

  @override
  State<TrackSettingsDialog> createState() => _TrackSettingsDialogState();
}

class _TrackSettingsDialogState extends State<TrackSettingsDialog> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      8,
      (index) => TextEditingController(text: widget.initialTrackNames[index]),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('轨道设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '设置轨道名称',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < 8; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextFormField(
                  controller: _controllers[i],
                  decoration: InputDecoration(
                    labelText: '轨道 ${i + 1}',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              _controllers.map((c) => c.text).toList(),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class PdfConfigDialog extends StatefulWidget {
  @override
  _PdfConfigDialogState createState() => _PdfConfigDialogState();
}

class _PdfConfigDialogState extends State<PdfConfigDialog> {
  bool _includeProjectInfo = true;
  bool _includeTracks = true;
  bool _includeNotes = true;
  bool _includeDiscarded = false;
  final List<String> _selectedTracks = [];
  final _titleController = TextEditingController();
  final _footerController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PDF报告设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: const Text('包含项目信息'),
              value: _includeProjectInfo,
              onChanged: (value) => setState(() => _includeProjectInfo = value!),
            ),
            CheckboxListTile(
              title: const Text('包含轨道信息'),
              value: _includeTracks,
              onChanged: (value) => setState(() => _includeTracks = value!),
            ),
            if (_includeTracks) ...[
              const SizedBox(height: 8),
              const Text('选择要包含的轨道：'),
              Wrap(
                spacing: 8,
                children: List.generate(8, (index) {
                  final trackName = '轨道${index + 1}';
                  return FilterChip(
                    label: Text(trackName),
                    selected: _selectedTracks.contains(trackName),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTracks.add(trackName);
                        } else {
                          _selectedTracks.remove(trackName);
                        }
                      });
                    },
                  );
                }),
              ),
            ],
            CheckboxListTile(
              title: const Text('包含备注'),
              value: _includeNotes,
              onChanged: (value) => setState(() => _includeNotes = value!),
            ),
            CheckboxListTile(
              title: const Text('包含已删除记录'),
              value: _includeDiscarded,
              onChanged: (value) => setState(() => _includeDiscarded = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '自定义标题',
                hintText: '留空使用默认标题',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _footerController,
              decoration: const InputDecoration(
                labelText: '自定义页脚',
                hintText: '留空使用默认页脚',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              PdfConfig(
                includeProjectInfo: _includeProjectInfo,
                includeTracks: _includeTracks,
                includeNotes: _includeNotes,
                includeDiscarded: _includeDiscarded,
                selectedTracks: _selectedTracks,
                customTitle: _titleController.text.isEmpty ? null : _titleController.text,
                customFooter: _footerController.text.isEmpty ? null : _footerController.text,
              ),
            );
          },
          child: const Text('生成'),
        ),
      ],
    );
  }
}