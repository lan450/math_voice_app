import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsPage({super.key, required this.settingsService});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _timerEnabled;
  late bool _voiceOnlyMode;
  late bool _showQuestionText;

  @override
  void initState() {
    super.initState();
    _timerEnabled = widget.settingsService.timerEnabled;
    _voiceOnlyMode = widget.settingsService.voiceOnlyMode;
    _showQuestionText = widget.settingsService.showQuestionText;
  }

  Future<void> _updateTimerEnabled(bool value) async {
    await widget.settingsService.setTimerEnabled(value);
    setState(() {
      _timerEnabled = value;
    });
  }

  Future<void> _updateVoiceOnlyMode(bool value) async {
    await widget.settingsService.setVoiceOnlyMode(value);
    setState(() {
      _voiceOnlyMode = value;
    });
  }

  Future<void> _updateShowQuestionText(bool value) async {
    await widget.settingsService.setShowQuestionText(value);
    setState(() {
      _showQuestionText = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 计时模式
              _buildSettingCard(
                icon: Icons.timer,
                title: '计时模式',
                subtitle: '每题30秒倒计时，超时自动标记错误',
                value: _timerEnabled,
                onChanged: _updateTimerEnabled,
              ),
              const SizedBox(height: 16),

              // 纯语音模式
              _buildSettingCard(
                icon: Icons.record_voice_over,
                title: '纯语音模式',
                subtitle: '不记对错，超时自动播报答案',
                value: _voiceOnlyMode,
                onChanged: _updateVoiceOnlyMode,
              ),
              const SizedBox(height: 16),

              // 显示题目文字
              _buildSettingCard(
                icon: Icons.text_fields,
                title: '显示题目文字',
                subtitle: '开启时显示文字，关闭时只语音播题',
                value: _showQuestionText,
                onChanged: _updateShowQuestionText,
              ),
              const SizedBox(height: 32),

              // 提示说明
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 模式说明',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTip('计时模式开启时，每题有30秒答题时间'),
                    _buildTip('纯语音模式不记录正确率，适合听力练习'),
                    _buildTip('两个模式可同时开启，优先响应先满足的条件'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.all(Colors.white),
            trackColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}