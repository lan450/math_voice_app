import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SttService {
  final SpeechToText _speechToText = SpeechToText();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Function(String)? onResult;
  Function(String)? onError;

  Future<bool> init() async {
    if (_isInitialized) return true;

    _isInitialized = await _speechToText.initialize(
      onError: (error) {
        onError?.call(error.errorMsg);
      },
    );

    return _isInitialized;
  }

  Future<void> startListening({String localeId = 'zh_CN'}) async {
    if (!_isInitialized) {
      final success = await init();
      if (!success) return;
    }

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult?.call(result.recognizedWords);
      },
      localeId: localeId,
      listenMode: ListenMode.confirmation,
      cancelOnError: false,
      partialResults: false,
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  void dispose() {
    _speechToText.stop();
  }
}

/// 从识别文本中提取数字
int? extractNumber(String text) {
  // 中文数字映射
  const chineseDigits = {
    '零': 0, '一': 1, '二': 2, '三': 3, '四': 4,
    '五': 5, '六': 6, '七': 7, '八': 8, '九': 9, '十': 10,
    '壹': 1, '贰': 2, '叁': 3, '肆': 4, '伍': 5,
    '陆': 6, '柒': 7, '捌': 8, '玖': 9,
  };

  // 清理文本
  final cleanText = text.replaceAll(RegExp(r'[^\w\s十零一二三四五六七八九壹贰叁肆伍陆柒捌玖]'), '');

  // 先尝试直接解析阿拉伯数字
  final arabicMatch = RegExp(r'-?\d+').firstMatch(cleanText);
  if (arabicMatch != null) {
    return int.tryParse(arabicMatch.group(0)!);
  }

  // 尝试解析中文数字
  if (cleanText.contains('十')) {
    // 处理十相关的数字
    if (cleanText == '十') return 10;
    if (cleanText == '十几') return null; // 不确定

    int result = 0;
    bool hasValue = false;

    for (var i = 0; i < cleanText.length; i++) {
      final char = cleanText[i];
      if (char == '十') {
        if (result == 0) result = 10;
        hasValue = true;
      } else if (chineseDigits.containsKey(char)) {
        final digit = chineseDigits[char]!;
        if (digit == 10) {
          result = result == 0 ? 10 : result * 10;
        } else {
          if (result == 0 || result == 10) {
            result = digit * (result == 10 ? 10 : 1);
          } else {
            result = result * 10 + digit;
          }
        }
        hasValue = true;
      }
    }

    if (hasValue) return result;
  }

  // 逐字解析
  for (var char in cleanText.runes) {
    final digit = chineseDigits[String.fromCharCode(char)];
    if (digit != null && digit < 10) {
      return digit;
    }
  }

  return null;
}
