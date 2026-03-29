import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  double _englishSpeechRate = 0.5;

  bool _isInitialized = false;
  bool _initStarted = false;
  final List<Completer<void>> _initWaiters = [];

  Future<void> init({Duration timeout = const Duration(seconds: 3)}) async {
    if (_initStarted) {
      // 如果已经在初始化中，等待它完成
      await Future.any([
        Future(() async {
          while (!_isInitialized) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }),
        Future.delayed(timeout),
      ]);
      return;
    }
    _initStarted = true;

    debugPrint('TTS: init started');

    try {
      await Future.wait([
        _flutterTts.setLanguage('zh-CN'),
        _flutterTts.setSpeechRate(1.0),
        _flutterTts.setVolume(1.0),
        _flutterTts.setPitch(1.0),
      ]).timeout(timeout);

      _isInitialized = true;
      debugPrint('TTS: init completed successfully');
    } catch (e) {
      debugPrint('TTS: init error or timeout: $e');
      // 即使超时也标记为已初始化，继续运行
      _isInitialized = true;
    }
  }

  /// 等待TTS初始化完成（如果正在初始化或尚未初始化）
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await init();
  }

  void setEnglishSpeechRate(double rate) {
    _englishSpeechRate = rate.clamp(0.3, 1.0);
  }

  double get englishSpeechRate => _englishSpeechRate;

  Future<void> speakChinese(String text) async {
    await _ensureInitialized();
    await _flutterTts.setLanguage('zh-CN');
    await _flutterTts.speak(text);
  }

  Future<void> speakEnglish(String text) async {
    await _ensureInitialized();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(_englishSpeechRate);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  void dispose() {
    _flutterTts.stop();
  }
}
