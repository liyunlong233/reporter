import 'dart:io';

import 'package:flutter/material.dart';
import 'package:reporter/data/repositories/local_preferences_repository.dart';
import 'package:reporter/models/recording_entry.dart';
import 'package:reporter/repositories/recording_repository.dart';
import 'package:reporter/repositories/settings_repository.dart';
import 'package:reporter/services/pdf_generator.dart';
import 'package:reporter/validators/validators.dart';

class RecordingsPage extends StatefulWidget {
  final RecordingRepository recordingRepository;
  final SettingsRepository settingsRepository;
  final LocalPreferencesRepository preferencesRepository;

  const RecordingsPage({
    super.key,
    required this.recordingRepository,
    required this.settingsRepository,
    required this.preferencesRepository,
  });

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
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
  final List<TextEditingController> _trackControllers = List.generate(24, (index) => TextEditingController());
  final List<String> _lastTrackNames = List.generate(24, (index) => '');
  final List<bool> _trackCheckedStates = List.generate(24, (index) => false);
  final List<bool> _lastTrackCheckedStates = List.generate(24, (index) => false);
  final List<String> _originalTrackNames = List.generate(24, (index) => '');
  int _channelCount = 8;
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
    final parsed = FileNameValidator.parseFileName(fileName);
    if (parsed != null) {
      _lastFileNamePrefix = parsed['prefix'] as String;
      _lastFileNameNumber = parsed['number'] as int;
      _lastFileNameDigits = parsed['digits'] as int;
    }
  }

  Future<void> _saveCurrentInput() async {
    if (_currentEntryId == null && !_isDiscarded) {
      final tracks = List<String?>.generate(
        _channelCount,
        (i) => _trackControllers[i].text.isEmpty ? null : _trackControllers[i].text,
      );
      final newEntry = await widget.recordingRepository.saveRecording(
        RecordingEntry.withTracks(
          fileName: _fileNameController.text,
          startTC: _startTCController.text,
          scene: _sceneController.text,
          take: _takeController.text,
          slate: _slateController.text,
          notes: _notesController.text,
          isDiscarded: _isDiscarded,
          createdAt: DateTime.now(),
          tracks: tracks,
          trackChecked: List.from(_trackCheckedStates),
        ),
      );
      if (mounted) {
        setState(() => _currentEntryId = newEntry);
      }
    }
  }

  Future<void> _clearForm() async {
    final settings = await widget.settingsRepository.getSettings();
    if (settings != null) {
      _channelCount = settings.channelCount;
    }
    
    final lastEntry = await widget.recordingRepository.getLatestRecording();
    
    setState(() {
      _currentEntryId = null;
      _isDiscarded = false;
      _startTCController.clear();
      _notesController.clear();
      
      _fileNameController.text = _generateNextFileName();
      
      if (lastEntry != null) {
        _sceneController.text = lastEntry.scene;
        _slateController.text = lastEntry.slate;
        
        if (lastEntry.isDiscarded) {
          _takeController.text = _incrementTake(lastEntry.take);
        } else {
          _takeController.clear();
        }
        
        for (var i = 0; i < _channelCount; i++) {
          _trackControllers[i].text = lastEntry.tracks[i] ?? _lastTrackNames[i];
          _trackCheckedStates[i] = lastEntry.trackChecked[i];
          _lastTrackNames[i] = _trackControllers[i].text;
          _lastTrackCheckedStates[i] = _trackCheckedStates[i];
          _originalTrackNames[i] = _trackControllers[i].text;
        }
      } else {
        _takeController.clear();
        for (var i = 0; i < _channelCount; i++) {
          _trackControllers[i].text = _lastTrackNames[i];
          _trackCheckedStates[i] = _lastTrackCheckedStates[i];
          _originalTrackNames[i] = _lastTrackNames[i];
        }
      }
    });
    await _loadExistingRecordings();
  }

  String _incrementTake(String take) {
    final regex = RegExp(r'^(\d+)(.*)$');
    final match = regex.firstMatch(take);
    if (match != null) {
      final numberPart = int.parse(match.group(1)!);
      final suffixPart = match.group(2)!;
      return '${numberPart + 1}$suffixPart';
    }
    return '1';
  }

  Future<void> _loadLastInputValues() async {
    final settings = await widget.settingsRepository.getSettings();
    if (settings != null) {
      _channelCount = settings.channelCount;
    }
    
    final lastEntry = await widget.recordingRepository.getLatestRecording();
    if (lastEntry != null) {
      _currentEntryId = lastEntry.id;
      _fileNameController.text = lastEntry.fileName;
      _startTCController.text = lastEntry.startTC;
      _sceneController.text = lastEntry.scene;
      _takeController.text = lastEntry.take;
      _slateController.text = lastEntry.slate;
      _notesController.text = lastEntry.notes;
      _isDiscarded = lastEntry.isDiscarded;
      
      _updateFileNameFormat(lastEntry.fileName);
      
      for (var i = 0; i < _channelCount; i++) {
        _trackControllers[i].text = lastEntry.tracks[i] ?? _lastTrackNames[i];
        _lastTrackNames[i] = _trackControllers[i].text;
        _trackCheckedStates[i] = lastEntry.trackChecked[i];
        _lastTrackCheckedStates[i] = lastEntry.trackChecked[i];
        _originalTrackNames[i] = lastEntry.tracks[i] ?? '';
      }
    } else {
      _lastFileNamePrefix = 'REC_';
      _lastFileNameNumber = 0;
      _lastFileNameDigits = 3;
      _fileNameController.text = 'REC_001';
      for (var i = 0; i < _channelCount; i++) {
        _trackControllers[i].text = '';
        _lastTrackNames[i] = '';
        _trackCheckedStates[i] = false;
        _lastTrackCheckedStates[i] = false;
        _originalTrackNames[i] = '';
      }
    }
  }

  Future<void> _loadExistingRecordings() async {
    final entries = await widget.recordingRepository.getAllRecordings();
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

  Future<void> _handleBackPress() async {
    try {
      if (Platform.isIOS) {
        await _saveCurrentInput();
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('保存更改'),
          content: const Text('是否要保存当前输入再退出？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('返回但不保存'),
            ),
            TextButton(
              onPressed: () async {
                await _saveCurrentInput();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('保存并返回'),
            ),
          ],
        ),
      );
      if (shouldPop == true && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('返回时出错: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackPress,
        ),
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
        tooltip: '新建记录',
        child: const Icon(Icons.add),
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
                    child: _buildTextFormField('镜', _slateController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextFormField('次', _takeController),
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
              const SizedBox(height: 8),
              _buildTrackCheckboxes(),
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
            color: entry.isDiscarded ? Colors.red.withOpacity(0.08) : null,
            child: ExpansionTile(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.scene} - ${entry.take}',
                      style: entry.isDiscarded
                          ? const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.lineThrough,
                            )
                          : null,
                    ),
                  ),
                  if (entry.isDiscarded)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '废弃',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
        _trackCheckedStates[i] = entry.trackChecked[i];
        _originalTrackNames[i] = entry.tracks[i] ?? '';
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

  void _autoFillStartTC() {
    _startTCController.text = TimeCodeValidator.generateCurrentTimeCode();
  }

  Future<void> _addEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    _updateFileNameFormat(_fileNameController.text);

    final tracks = List<String?>.generate(
      _channelCount,
      (i) => _trackControllers[i].text.isEmpty ? null : _trackControllers[i].text,
    );

    try {
      if (_currentEntryId != null) {
        final existingEntry = _entries.firstWhere((entry) => entry.id == _currentEntryId);
        final updatedEntry = existingEntry.copyWith(
          fileName: _fileNameController.text,
          startTC: _startTCController.text,
          scene: _sceneController.text,
          take: _takeController.text,
          slate: _slateController.text,
          notes: _notesController.text,
          tracks: tracks,
          trackChecked: List.from(_trackCheckedStates),
        );
        await _updateEntry(updatedEntry);
      } else {
        final entry = RecordingEntry.withTracks(
          fileName: _fileNameController.text,
          startTC: _startTCController.text,
          scene: _sceneController.text,
          take: _takeController.text,
          slate: _slateController.text,
          isDiscarded: _isDiscarded,
          notes: _notesController.text,
          createdAt: DateTime.now(),
          tracks: tracks,
          trackChecked: List.from(_trackCheckedStates),
        );

        await widget.recordingRepository.saveRecording(entry);
      }

      if (!mounted) return;

      await _loadExistingRecordings();
      _clearForm();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记录已保存')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('保存录音记录失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Future<void> _updateEntry(RecordingEntry entry) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    _formKey.currentState!.save();
    
    final updatedEntry = entry.copyWith(
      fileName: _fileNameController.text,
      startTC: _startTCController.text,
      scene: _sceneController.text,
      take: _takeController.text,
      slate: _slateController.text,
      notes: _notesController.text,
      tracks: _trackControllers.map((c) => c.text.isEmpty ? null : c.text).toList(),
      trackChecked: List.from(_trackCheckedStates),
    );

    await widget.recordingRepository.updateRecording(updatedEntry);
    
    if (!mounted) return;
    
    await _loadExistingRecordings();
    _clearForm();
  }

  Future<void> _deleteEntry(RecordingEntry entry) async {
    if (entry.id != null) {
      try {
        await widget.recordingRepository.deleteRecording(entry.id!);
        if (!mounted) return;
        await _loadExistingRecordings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记录已删除')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  Future<void> _generatePDF() async {
    try {
      final pdfGenerator = PdfGenerator(
        recordingRepository: widget.recordingRepository,
        settingsRepository: widget.settingsRepository,
        preferencesRepository: widget.preferencesRepository,
      );
      await pdfGenerator.generateRecordingReport();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF报告已生成')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成PDF失败: $e')),
        );
      }
    }
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

  Widget _buildTrackCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('使用轨道', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(_channelCount, (index) {
            final trackName = _trackControllers[index].text;
            final label = trackName.isEmpty ? '轨道 ${index + 1}' : trackName;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _trackCheckedStates[index],
                  onChanged: (value) {
                    setState(() {
                      _trackCheckedStates[index] = value ?? false;
                    });
                  },
                ),
                Text(label),
              ],
            );
          }),
        ),
      ],
    );
  }

  Future<void> _toggleDiscard(RecordingEntry entry) async {
    final updatedEntry = entry.copyWith(isDiscarded: !entry.isDiscarded);
    await widget.recordingRepository.updateRecording(updatedEntry);
    if (mounted) {
      await _loadExistingRecordings();
    }
  }

  Future<void> _showTrackSettings() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => TrackSettingsDialog(
        initialTrackNames: _trackControllers.map((c) => c.text).toList(),
        channelCount: _channelCount,
      ),
    );

    if (result != null) {
      setState(() {
        for (var i = 0; i < _channelCount; i++) {
          _trackControllers[i].text = result[i];
          _lastTrackNames[i] = result[i];
        }
      });
    }
  }

  List<Map<String, dynamic>> getTrackNameChanges() {
    final changes = <Map<String, dynamic>>[];
    for (var i = 0; i < _channelCount; i++) {
      final currentName = _trackControllers[i].text;
      final originalName = _originalTrackNames[i];
      if (originalName.isNotEmpty && currentName != originalName) {
        changes.add({
          'trackIndex': i,
          'oldName': originalName,
          'newName': currentName,
        });
      }
    }
    return changes;
  }
}

class TrackSettingsDialog extends StatefulWidget {
  final List<String> initialTrackNames;
  final int channelCount;

  const TrackSettingsDialog({
    super.key,
    required this.initialTrackNames,
    required this.channelCount,
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
      widget.channelCount,
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
            for (var i = 0; i < widget.channelCount; i++)
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