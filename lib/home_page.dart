import 'package:flutter/material.dart';
import 'package:reporter/database/database_helper.dart';
import 'package:reporter/models/app_settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _dbHelper = DatabaseHelper.instance;
  AppSettings? _appSettings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _dbHelper.getAppSettings();
    setState(() => _appSettings = settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('同期录音报告系统')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSettingsCard('基本设置', Icons.settings, '/settings'),
            const SizedBox(height: 20),
            _buildSettingsCard('轨道配置', Icons.audiotrack, '/tracks'),
            const SizedBox(height: 20),
            _buildSettingsCard('录音记录', Icons.mic, '/recordings'),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.delete_forever, color: Colors.white),
          label: const Text('清空所有数据', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          onPressed: _confirmClearAllData,
        ),
      ),
    );
  }

  Future<void> _confirmClearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空数据'),
        content: const Text('这将永久删除所有项目设置、轨道配置和录音记录！\n确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteAllData();
      _loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有数据已成功清除')),
      );
    }
  }

  Widget _buildSettingsCard(String title, IconData icon, String route) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontSize: 20)),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}