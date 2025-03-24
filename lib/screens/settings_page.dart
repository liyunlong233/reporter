import 'package:flutter/material.dart';
import 'package:reporter/database/database_helper.dart';
import 'package:reporter/models/app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper.instance;

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
    return Scaffold(
      appBar: AppBar(title: const Text('基本设置')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextFormField('项目名称', _projectNameController),
              _buildTextFormField('制作公司', _companyController),
              _buildTextFormField('录音师', _engineerController),
              _buildTextFormField('话筒员', _boomOperatorController),
              _buildTextFormField('设备型号', _equipmentController),
              _buildTextFormField('文件格式', _formatController),
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
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) => value!.isEmpty ? '请输入$label' : null,
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
        productionCompany: _companyController.text,
        soundEngineer: _engineerController.text,
        boomOperator: _boomOperatorController.text,
        equipmentModel: _equipmentController.text,
        fileFormat: _formatController.text,
        frameRate: double.parse(_frameRateController.text),
        projectDate: _selectedDate,
        rollNumber: _rollNumberController.text,
      );

      await _dbHelper.saveAppSettings(settings);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置保存成功')),
      );
    }
  }
}