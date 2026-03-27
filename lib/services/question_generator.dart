import 'dart:math';
import '../models/question.dart';

class QuestionGenerator {
  final Random _random = Random();

  /// 生成10道题目：前5题中文，后5题英文
  List<Question> generateQuestions() {
    return List.generate(10, (index) => _generateSingle(index < 5));
  }

  Question _generateSingle(bool isChinese) {
    final operatorType = _random.nextInt(3); // 0=加, 1=减, 2=乘

    switch (operatorType) {
      case 0:
        return _generateAddition(isChinese);
      case 1:
        return _generateSubtraction(isChinese);
      case 2:
        return _generateMultiplication(isChinese);
      default:
        return _generateAddition(isChinese);
    }
  }

  /// 加法：a + b，a,b ∈ [1,100]，a+b ≤ 100
  Question _generateAddition(bool isChinese) {
    int a, b;
    do {
      a = _random.nextInt(100) + 1;
      b = _random.nextInt(100) + 1;
    } while (a + b > 100);

    return Question(
      num1: a,
      num2: b,
      operator: '+',
      correctAnswer: a + b,
      isChinese: isChinese,
    );
  }

  /// 减法：a - b，a,b ∈ [1,100]，a ≥ b
  Question _generateSubtraction(bool isChinese) {
    int a = _random.nextInt(100) + 1;
    int b = _random.nextInt(a) + 1;

    return Question(
      num1: a,
      num2: b,
      operator: '-',
      correctAnswer: a - b,
      isChinese: isChinese,
    );
  }

  /// 乘法：a × b，a,b ∈ [1,9]
  Question _generateMultiplication(bool isChinese) {
    final a = _random.nextInt(9) + 1;
    final b = _random.nextInt(9) + 1;

    return Question(
      num1: a,
      num2: b,
      operator: '×',
      correctAnswer: a * b,
      isChinese: isChinese,
    );
  }
}
