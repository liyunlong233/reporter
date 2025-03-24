import 'package:flutter/material.dart';
import 'package:reporter/database/database_helper.dart';
import 'package:reporter/models/track_config.dart';

class TracksPage extends StatefulWidget {
  const TracksPage({super.key});

  @override
  State<TracksPage> createState() => _TracksPageState();
}

class _TracksPageState extends State<TracksPage> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper.instance;
  final List<TextEditingController> _controllers = List.generate(8, (index) => TextEditingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('轨道配置')),
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
                    validator: (value) => value!.isEmpty ? '请输入轨道名称' : null,
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
    );
  }

  Future<void> _saveTrackConfig() async {
    if (_formKey.currentState!.validate()) {
      final config = TrackConfig(
        track1: _controllers[0].text,
        track2: _controllers[1].text,
        track3: _controllers[2].text,
        track4: _controllers[3].text,
        track5: _controllers[4].text,
        track6: _controllers[5].text,
        track7: _controllers[6].text,
        track8: _controllers[7].text,
      );

      await _dbHelper.saveTrackConfig(config);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('轨道配置保存成功')),
      );
      Navigator.pop(context);
    }
  }
}