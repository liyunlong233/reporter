import 'package:flutter/material.dart';
import 'package:reporter/data/repositories/local_preferences_repository.dart';
import 'package:reporter/repositories/recording_repository.dart';
import 'package:reporter/repositories/settings_repository.dart';

class HomePage extends StatefulWidget {
  final RecordingRepository recordingRepository;
  final SettingsRepository settingsRepository;
  final LocalPreferencesRepository preferencesRepository;

  const HomePage({
    super.key,
    required this.recordingRepository,
    required this.settingsRepository,
    required this.preferencesRepository,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _totalRecordings = 0;
  int _activeRecordings = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final recordings = await widget.recordingRepository.getAllRecordings();
    setState(() {
      _totalRecordings = recordings.length;
      _activeRecordings = recordings.where((r) => !r.isDiscarded).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('同期录音报告系统'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatisticsCard(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildMainMenu(),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'newRecording',
            onPressed: () => Navigator.pushNamed(context, '/recordings'),
            tooltip: '新建录音记录',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'clearData',
            backgroundColor: Colors.red,
            onPressed: _confirmClearAllData,
            tooltip: '清空所有数据',
            child: const Icon(Icons.delete_forever),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('数据统计', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('总录音数', _totalRecordings.toString(), Icons.mic),
                _buildStatItem('有效录音', _activeRecordings.toString(), Icons.check_circle),
                _buildStatItem('废弃录音', (_totalRecordings - _activeRecordings).toString(), Icons.delete),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('快速操作', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip('新建录音', Icons.add, () => Navigator.pushNamed(context, '/recordings')),
                _buildActionChip('生成报告', Icons.picture_as_pdf, () => Navigator.pushNamed(context, '/recordings')),
                _buildActionChip('项目设置', Icons.settings, () => Navigator.pushNamed(context, '/settings')),
                _buildActionChip('基本设置', Icons.tune, () => Navigator.pushNamed(context, '/basic-settings')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _buildMainMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('主菜单', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildSettingsCard('项目设置', Icons.settings, '/settings'),
        const SizedBox(height: 12),
        _buildSettingsCard('基本设置', Icons.tune, '/basic-settings'),
        const SizedBox(height: 12),
        _buildSettingsCard('录音记录', Icons.mic, '/recordings'),
      ],
    );
  }

  Widget _buildSettingsCard(String title, IconData icon, String route) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => Navigator.pushNamed(context, route),
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
      await widget.recordingRepository.deleteAllRecordings();
      await widget.settingsRepository.deleteSettings();
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有数据已成功清除')),
      );
    }
  }
}