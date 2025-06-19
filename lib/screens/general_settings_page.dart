import 'package:flutter/material.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  // 自动填充选项
  final List<String> _deviceModels = [];
  final List<String> _fileFormats = [];

  // 主题模式
  ThemeMode _themeMode = ThemeMode.system;

  // 作者与鸣谢信息
  final String _author = '刘哲麟@北京电影学院';
  final String _thanks = '@北京电影学院声音学院';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('应用设置')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('自动填充设置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAutoFillDialog(context),
          ),
          ListTile(
            title: const Text('主题模式'),
            subtitle: Text(_themeMode == ThemeMode.system
                ? '跟随系统'
                : _themeMode == ThemeMode.light
                    ? '白天模式'
                    : '夜间模式'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context),
          ),
          ListTile(
            title: const Text('关于'),
            trailing: const Icon(Icons.info_outline),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  // 自动填充设置弹窗
  void _showAutoFillDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('自动填充设置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditableList('设备型号', _deviceModels),
              const SizedBox(height: 16),
              _buildEditableList('文件格式', _fileFormats),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  // 可编辑列表组件
  Widget _buildEditableList(String label, List<String> items) {
    final controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: items
              .map((item) => Chip(
                    label: Text(item),
                    onDeleted: () {
                      setState(() => items.remove(item));
                    },
                  ))
              .toList(),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: '添加$label'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() => items.add(controller.text.trim()));
                  controller.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  // 主题切换弹窗
  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('选择主题模式'),
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('白天模式'),
              value: ThemeMode.light,
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('夜间模式'),
              value: ThemeMode.dark,
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // 关于弹窗
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('作者：$_author'),
            const SizedBox(height: 8),
            Text('特别鸣谢：$_thanks'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
} 