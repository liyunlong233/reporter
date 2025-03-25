import 'package:flutter/material.dart';
import 'package:reporter/database/database_helper.dart';
import 'package:reporter/models/track_config.dart';

class TracksPage extends StatefulWidget {
  const TracksPage({super.key});

  @override
  State<TracksPage> createState() => _TracksPageState();
}

class _TracksPageState extends State<TracksPage> {
  @override
  void initState() {
    super.initState();
    _loadTrackConfig();
    _loadLastTrackConfig();
  }

  Future<void> _loadTrackConfig() async {
    final config = await _dbHelper.getLatestTrackConfig();
    final trackNames = [
      config?.track1 ?? '',
      config?.track2 ?? '',
      config?.track3 ?? '',
      config?.track4 ?? '',
      config?.track5 ?? '',
      config?.track6 ?? '',
      config?.track7 ?? '',
      config?.track8 ?? '',
    ];
    for (var i = 0; i < 8; i++) {
      _controllers[i].text = trackNames[i];
    }
  }

  Future<void> _loadLastTrackConfig() async {
    final config = await _dbHelper.getLatestTrackConfig();
    final trackNames = [
      config?.track1 ?? '',
      config?.track2 ?? '',
      config?.track3 ?? '',
      config?.track4 ?? '',
      config?.track5 ?? '',
      config?.track6 ?? '',
      config?.track7 ?? '',
      config?.track8 ?? '',
    ];
    for (var i = 0; i < 8; i++) {
      _controllers[i].text = trackNames[i];
    }
  }

  Future<void> _saveTrackConfig() async {
    final trackNames = _controllers.map((c) => c.text).toList();
    final config = TrackConfig(
        track1: trackNames.isNotEmpty ? trackNames[0] : '',
        track2: trackNames.length > 1 ? trackNames[1] : '',
        track3: trackNames.length > 2 ? trackNames[2] : '',
        track4: trackNames.length > 3 ? trackNames[3] : '',
        track5: trackNames.length > 4 ? trackNames[4] : '',
        track6: trackNames.length > 5 ? trackNames[5] : '',
        track7: trackNames.length > 6 ? trackNames[6] : '',
        track8: trackNames.length > 7 ? trackNames[7] : '',
      );
    await _dbHelper.saveTrackConfig(config);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('轨道配置保存成功')),
    );
  }
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper.instance;
  final List<TextEditingController> _controllers = List.generate(8, (index) => TextEditingController());

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveTrackConfig();
        return true;
      },
      child:
    Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('轨道配置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              for (var i = 0; i < 8; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextFormField(
                    controller: _controllers[i],
                    decoration: InputDecoration(
                      labelText: '轨道 ${i + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    validator: null,
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveTrackConfig,
                child: const Text('保存配置', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    )
    );
  }


}