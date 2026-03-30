import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyTimerEnabled = 'timer_enabled';
  static const String _keyVoiceOnlyMode = 'voice_only_mode';
  static const String _keyShowQuestionText = 'show_question_text';
  static const String _keyShowSubtitles = 'show_subtitles';
  static const String _keyEnglishSpeechRate = 'english_speech_rate';

  SharedPreferences? _prefs;

  SettingsService();

  static Future<SettingsService> create() async {
    final service = SettingsService();
    service._prefs = await SharedPreferences.getInstance();
    return service;
  }

  // 计时模式
  bool get timerEnabled => _prefs!.getBool(_keyTimerEnabled) ?? false;
  Future<void> setTimerEnabled(bool value) async {
    await _prefs!.setBool(_keyTimerEnabled, value);
  }

  // 纯语音模式
  bool get voiceOnlyMode => _prefs!.getBool(_keyVoiceOnlyMode) ?? false;
  Future<void> setVoiceOnlyMode(bool value) async {
    await _prefs!.setBool(_keyVoiceOnlyMode, value);
  }

  // 显示题目文字
  bool get showQuestionText => _prefs!.getBool(_keyShowQuestionText) ?? true;
  Future<void> setShowQuestionText(bool value) async {
    await _prefs!.setBool(_keyShowQuestionText, value);
  }

  // 显示字幕 (原有功能)
  bool get showSubtitles => _prefs!.getBool(_keyShowSubtitles) ?? false;
  Future<void> setShowSubtitles(bool value) async {
    await _prefs!.setBool(_keyShowSubtitles, value);
  }

  // 英文语速 (原有功能)
  double get englishSpeechRate => _prefs!.getDouble(_keyEnglishSpeechRate) ?? 0.5;
  Future<void> setEnglishSpeechRate(double value) async {
    await _prefs!.setDouble(_keyEnglishSpeechRate, value);
  }
}