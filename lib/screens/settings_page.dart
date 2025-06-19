import 'package:flutter/material.dart';
import 'package:reporter/database/database_helper.dart';
import 'package:reporter/models/app_settings.dart';
import 'package:provider/provider.dart';
import '../global/app_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    _clearAllFields();
    _loadSettings();
  }

  final _dbHelper = DatabaseHelper.instance;

  void _clearAllFields() {
    _projectNameController.clear();
    _companyController.clear();
    _engineerController.clear();
    _boomOperatorController.clear();
    _equipmentController.clear();
    _formatController.clear();
    _frameRateController.clear();
    _rollNumberController.clear();
    _selectedDate = DateTime.now();
  }

  Future<void> _loadSettings() async {
    final settings = await _dbHelper.getAppSettings();
    if (settings != null) {
      setState(() {
        _projectNameController.text = settings.projectName;
        _companyController.text = settings.productionCompany;
        _engineerController.text = settings.soundEngineer;
        _boomOperatorController.text = settings.boomOperator;
        _equipmentController.text = settings.equipmentModel;
        _formatController.text = settings.fileFormat;
        _frameRateController.text = settings.frameRate.toString();
        _rollNumberController.text = settings.rollNumber;
        _selectedDate = settings.projectDate;
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
    );
    await _dbHelper.saveAppSettings(settings);
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
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return WillPopScope(
      onWillPop: () async {
        await _saveCurrentInput();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: const Text('基本设置'),
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
                _buildTextFormField('设备型号', _equipmentController, options: appState.deviceModels),
                _buildTextFormField('文件格式', _formatController, options: appState.fileFormats),
                _buildTextFormField('项目帧率', _frameRateController),
                _buildDatePicker(),
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
      ),
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller, {bool isRequired = false, List<String>? options}) {
    if (options != null && options.isNotEmpty) {
      return DropdownButtonFormField<String>(
        value: controller.text.isNotEmpty ? controller.text : null,
        decoration: InputDecoration(labelText: label),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (value) {
          controller.text = value ?? '';
        },
        onSaved: (value) {
          controller.text = value ?? '';
        },
        selectedItemBuilder: (context) => options.map((e) => Text(e)).toList(),
      );
    }
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: isRequired ? (value) => value!.isEmpty ? '请输入$label' : null : null,
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

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
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
      );

      await _dbHelper.saveAppSettings(settings);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置保存成功')),
      );
    }
  }
}