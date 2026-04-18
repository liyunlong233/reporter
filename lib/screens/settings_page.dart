import 'package:flutter/material.dart';
import 'package:reporter/data/repositories/local_preferences_repository.dart';
import 'package:reporter/models/app_preferences.dart';
import 'package:reporter/models/app_settings.dart';
import 'package:reporter/repositories/settings_repository.dart';

class SettingsPage extends StatefulWidget {
  final SettingsRepository settingsRepository;
  final LocalPreferencesRepository preferencesRepository;

  const SettingsPage({
    super.key,
    required this.settingsRepository,
    required this.preferencesRepository,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedChannelCount = 8;
  List<String> _fileFormats = [];
  List<String> _equipmentModels = [];
  String? _selectedFileFormat;
  String? _selectedEquipmentModel;

  Future<void> _loadSettings() async {
    final settings = await widget.settingsRepository.getSettings();
    if (settings != null) {
      _projectNameController.text = settings.projectName;
      _companyController.text = settings.productionCompany;
      _engineerController.text = settings.soundEngineer;
      _boomOperatorController.text = settings.boomOperator;
      _equipmentController.text = settings.equipmentModel;
      _formatController.text = settings.fileFormat;
      _frameRateController.text = settings.frameRate.toString();
      _rollNumberController.text = settings.rollNumber;
      _selectedDate = settings.projectDate;
      _selectedChannelCount = settings.channelCount;
    }

    final prefs = await widget.preferencesRepository.getPreferences();
    if (prefs != null) {
      setState(() {
        _fileFormats = prefs.defaultFileFormats;
        _equipmentModels = prefs.defaultEquipmentModels;
        _selectedFileFormat = prefs.selectedFileFormat;
        _selectedEquipmentModel = prefs.selectedEquipmentModel;

        if (_selectedFileFormat != null && !_fileFormats.contains(_selectedFileFormat)) {
          _selectedFileFormat = null;
        }
        if (_selectedEquipmentModel != null && !_equipmentModels.contains(_selectedEquipmentModel)) {
          _selectedEquipmentModel = null;
        }

        if (_selectedFileFormat != null && _selectedFileFormat!.isNotEmpty) {
          _formatController.text = _selectedFileFormat!;
        }
        if (_selectedEquipmentModel != null && _selectedEquipmentModel!.isNotEmpty) {
          _equipmentController.text = _selectedEquipmentModel!;
        }
      });
    }
  }

  Future<void> _saveCurrentInput() async {
    final settings = AppSettings(
      projectName: _projectNameController.text,
      productionCompany: _companyController.text,
      soundEngineer: _engineerController.text,
      boomOperator: _boomOperatorController.text,
      equipmentModel: _equipmentController.text,
      fileFormat: _formatController.text,
      frameRate: double.tryParse(_frameRateController.text) ?? 24.0,
      rollNumber: _rollNumberController.text,
      projectDate: _selectedDate,
      channelCount: _selectedChannelCount,
    );
    await widget.settingsRepository.saveSettings(settings);

    final prefs = AppPreferences(
      selectedFileFormat: _formatController.text,
      selectedEquipmentModel: _equipmentController.text,
    );
    final existingPrefs = await widget.preferencesRepository.getPreferences();
    if (existingPrefs != null) {
      await widget.preferencesRepository.savePreferences(
        prefs.copyWith(
          defaultFileFormats: existingPrefs.defaultFileFormats,
          defaultEquipmentModels: existingPrefs.defaultEquipmentModels,
          includeDiscardedInPDF: existingPrefs.includeDiscardedInPDF,
        ),
      );
    }
  }

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _engineerController = TextEditingController();
  final TextEditingController _boomOperatorController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _formatController = TextEditingController();
  final TextEditingController _frameRateController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _saveCurrentInput();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text('项目设置'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildTextFormField('项目名称', _projectNameController, isRequired: true),
                _buildTextFormField('制作公司', _companyController),
                _buildTextFormField('录音师', _engineerController),
                _buildTextFormField('话筒员', _boomOperatorController),
                _buildEquipmentDropdown(),
                _buildFileFormatDropdown(),
                _buildTextFormField('项目帧率', _frameRateController),
                _buildDatePicker(),
                _buildChannelCountSelector(),
                _buildTextFormField('卷号', _rollNumberController),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('保存设置', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller, {bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: isRequired ? (value) => value!.isEmpty ? '请输入$label' : null : null,
    );
  }

  Widget _buildEquipmentDropdown() {
    if (_equipmentModels.isEmpty) {
      return _buildTextFormField('设备型号', _equipmentController);
    }

    final uniqueModels = _equipmentModels.toSet().toList();
    
    if (_selectedEquipmentModel != null && !uniqueModels.contains(_selectedEquipmentModel)) {
      _selectedEquipmentModel = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedEquipmentModel,
          decoration: const InputDecoration(labelText: '设备型号'),
          hint: const Text('选择设备型号'),
          items: uniqueModels.map((model) {
            return DropdownMenuItem(
              value: model,
              child: Text(model),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedEquipmentModel = value;
              if (value != null) {
                _equipmentController.text = value;
              }
            });
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _equipmentController,
          decoration: const InputDecoration(labelText: '或手动输入设备型号'),
        ),
      ],
    );
  }

  Widget _buildFileFormatDropdown() {
    if (_fileFormats.isEmpty) {
      return _buildTextFormField('文件格式', _formatController);
    }

    final uniqueFormats = _fileFormats.toSet().toList();
    
    if (_selectedFileFormat != null && !uniqueFormats.contains(_selectedFileFormat)) {
      _selectedFileFormat = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedFileFormat,
          decoration: const InputDecoration(labelText: '文件格式'),
          hint: const Text('选择文件格式'),
          items: uniqueFormats.map((format) {
            return DropdownMenuItem(
              value: format,
              child: Text(format),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedFileFormat = value;
              if (value != null) {
                _formatController.text = value;
              }
            });
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _formatController,
          decoration: const InputDecoration(labelText: '或手动输入文件格式'),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: const Text('项目日期'),
      subtitle: Text('${_selectedDate.toLocal()}'.split(' ')[0]),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null && picked != _selectedDate) {
          setState(() => _selectedDate = picked);
        }
      },
    );
  }

  Widget _buildChannelCountSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Text('通道数', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 16),
          ...[8, 16, 24].map((count) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _selectedChannelCount = count);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _selectedChannelCount == count ? Theme.of(context).primaryColor : null,
                    foregroundColor: _selectedChannelCount == count ? Colors.white : null,
                  ),
                  child: Text('$count'),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final settings = AppSettings(
      projectName: _projectNameController.text,
      productionCompany: _companyController.text.isEmpty ? '未输入' : _companyController.text,
      soundEngineer: _engineerController.text.isEmpty ? '未输入' : _engineerController.text,
      boomOperator: _boomOperatorController.text.isEmpty ? '未输入' : _boomOperatorController.text,
      equipmentModel: _equipmentController.text.isEmpty ? '未输入' : _equipmentController.text,
      fileFormat: _formatController.text.isEmpty ? '未输入' : _formatController.text,
      rollNumber: _rollNumberController.text.isEmpty ? '未输入' : _rollNumberController.text,
      frameRate: double.tryParse(_frameRateController.text) ?? 0,
      projectDate: _selectedDate,
      channelCount: _selectedChannelCount,
    );

    await widget.settingsRepository.saveSettings(settings);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置保存成功')),
      );
    }
  }
}
