import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:reporter/data/repositories/local_preferences_repository.dart';
import 'package:reporter/models/app_preferences.dart';

class BasicSettingsPage extends StatefulWidget {
  final LocalPreferencesRepository preferencesRepository;

  const BasicSettingsPage({super.key, required this.preferencesRepository});

  @override
  State<BasicSettingsPage> createState() => _BasicSettingsPageState();
}

class _BasicSettingsPageState extends State<BasicSettingsPage> {
  bool _includeDiscardedInPDF = true;
  bool _addLogoToPDF = true;
  final List<String> _fileFormats = [];
  final List<String> _equipmentModels = [];
  final List<String> _quickNotes = [];
  String? _customLogoPath;
  final _fileFormatController = TextEditingController();
  final _equipmentModelController = TextEditingController();
  final _quickNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await widget.preferencesRepository.getPreferences();
    if (prefs != null) {
      setState(() {
        _includeDiscardedInPDF = prefs.includeDiscardedInPDF;
        _addLogoToPDF = prefs.addLogoToPDF;
        _fileFormats.addAll(prefs.defaultFileFormats);
        _equipmentModels.addAll(prefs.defaultEquipmentModels);
        _quickNotes.addAll(prefs.quickNotes);
        _customLogoPath = prefs.customLogoPath;
      });
    }
  }

  Future<void> _savePreferences() async {
    final prefs = AppPreferences(
      includeDiscardedInPDF: _includeDiscardedInPDF,
      addLogoToPDF: _addLogoToPDF,
      defaultFileFormats: _fileFormats,
      defaultEquipmentModels: _equipmentModels,
      quickNotes: _quickNotes,
      customLogoPath: _customLogoPath,
    );
    await widget.preferencesRepository.savePreferences(prefs);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('基本设置保存成功')),
      );
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _customLogoPath = result.files.single.path;
      });
    }
  }

  void _removeLogo() {
    setState(() {
      _customLogoPath = null;
    });
  }

  void _addFileFormat() {
    if (_fileFormatController.text.isNotEmpty) {
      setState(() {
        _fileFormats.add(_fileFormatController.text.trim());
        _fileFormatController.clear();
      });
    }
  }

  void _addEquipmentModel() {
    if (_equipmentModelController.text.isNotEmpty) {
      setState(() {
        _equipmentModels.add(_equipmentModelController.text.trim());
        _equipmentModelController.clear();
      });
    }
  }

  void _removeFileFormat(int index) {
    setState(() {
      _fileFormats.removeAt(index);
    });
  }

  void _removeEquipmentModel(int index) {
    setState(() {
      _equipmentModels.removeAt(index);
    });
  }

  void _addQuickNote() {
    if (_quickNoteController.text.isNotEmpty) {
      setState(() {
        _quickNotes.add(_quickNoteController.text.trim());
        _quickNoteController.clear();
      });
    }
  }

  void _removeQuickNote(int index) {
    setState(() {
      _quickNotes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('基本设置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('导出PDF时包含废弃条目'),
              value: _includeDiscardedInPDF,
              onChanged: (value) {
                setState(() {
                  _includeDiscardedInPDF = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('添加Logo到PDF'),
              value: _addLogoToPDF,
              onChanged: (value) {
                setState(() {
                  _addLogoToPDF = value;
                });
              },
            ),
            const Divider(),
            const Text('默认文件格式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fileFormatController,
                    decoration: const InputDecoration(
                      labelText: '添加文件格式',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addFileFormat(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addFileFormat,
                  child: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _fileFormats.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removeFileFormat(entry.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text('PDF LOGO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _customLogoPath != null
                      ? Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_customLogoPath!),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _customLogoPath!.split(Platform.pathSeparator).last,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : const Text('使用默认LOGO', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _pickLogo,
                  child: const Text('选择图片'),
                ),
                if (_customLogoPath != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _removeLogo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('恢复默认'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text('默认设备型号', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _equipmentModelController,
                    decoration: const InputDecoration(
                      labelText: '添加设备型号',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addEquipmentModel(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addEquipmentModel,
                  child: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _equipmentModels.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removeEquipmentModel(entry.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text('快捷备注', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quickNoteController,
                    decoration: const InputDecoration(
                      labelText: '添加快捷备注',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addQuickNote(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addQuickNote,
                  child: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickNotes.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removeQuickNote(entry.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _savePreferences,
              child: const Text('保存设置', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
