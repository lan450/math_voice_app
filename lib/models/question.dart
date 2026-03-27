/// 题目模型
class Question {
  final int num1;
  final int num2;
  final String operator; // "+", "-", "×"
  final int correctAnswer;
  int? userAnswer;
  bool? isCorrect;
  final bool isChinese;

  Question({
    required this.num1,
    required this.num2,
    required this.operator,
    required this.correctAnswer,
    required this.isChinese,
    this.userAnswer,
    this.isCorrect,
  });

  String get questionTextChinese {
    final opText = switch (operator) {
      '+' => '加',
      '-' => '减',
      '×' => '乘',
      _ => '',
    };
    return '$num1$opText$num2等于多少？';
  }

  String get questionTextEnglish {
    final opText = switch (operator) {
      '+' => 'plus',
      '-' => 'minus',
      '×' => 'times',
      _ => '',
    };
    return 'What is $num1 $opText $num2?';
  }

  String get answerTextChinese => '$correctAnswer';
  String get answerTextEnglish => '$correctAnswer';
}
