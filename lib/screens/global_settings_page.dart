import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../global/app_state.dart';

class GlobalSettingsPage extends StatefulWidget {
  const GlobalSettingsPage({super.key});

  @override
  State<GlobalSettingsPage> createState() => _GlobalSettingsPageState();
}

class _GlobalSettingsPageState extends State<GlobalSettingsPage> {
  final TextEditingController _deviceModelController = TextEditingController();
  final TextEditingController _fileFormatController = TextEditingController();

  @override
  void dispose() {
    _deviceModelController.dispose();
    _fileFormatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('全局设置')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('自动填充设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildEditableList('设备型号', appState.deviceModels, _deviceModelController, (list) => appState.setDeviceModels(list)),
          const SizedBox(height: 16),
          _buildEditableList('文件格式', appState.fileFormats, _fileFormatController, (list) => appState.setFileFormats(list)),
          const Divider(height: 32),
          const Text('主题模式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<ThemeMode>(
                  title: const Text('跟随系统'),
                  value: ThemeMode.system,
                  groupValue: appState.themeMode,
                  onChanged: (mode) => appState.setThemeMode(mode!),
                ),
              ),
              Expanded(
                child: RadioListTile<ThemeMode>(
                  title: const Text('白天'),
                  value: ThemeMode.light,
                  groupValue: appState.themeMode,
                  onChanged: (mode) => appState.setThemeMode(mode!),
                ),
              ),
              Expanded(
                child: RadioListTile<ThemeMode>(
                  title: const Text('夜间'),
                  value: ThemeMode.dark,
                  groupValue: appState.themeMode,
                  onChanged: (mode) => appState.setThemeMode(mode!),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text('关于', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const ListTile(
            title: Text('作者'),
            subtitle: Text('刘哲麟@北京电影学院'),
          ),
          const ListTile(
            title: Text('特别鸣谢'),
            subtitle: Text('@北京电影学院声音学院'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableList(String label, List<String> items, TextEditingController controller, void Function(List<String>) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: items.map((item) => Chip(
            label: Text(item),
            onDeleted: () {
              final newList = List<String>.from(items)..remove(item);
              onChanged(newList);
            },
          )).toList(),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: '添加新$label'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty && !items.contains(text)) {
                  final newList = List<String>.from(items)..add(text);
                  onChanged(newList);
                  controller.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
} 