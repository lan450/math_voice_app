import 'package:flutter/material.dart';
import '../models/question.dart';

class ResultPage extends StatelessWidget {
  final List<Question> questions;
  final VoidCallback onRestart;

  const ResultPage({
    super.key,
    required this.questions,
    required this.onRestart,
  });

  int get correctCount => questions.where((q) => q.isCorrect == true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                '🎉',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 10),
              const Text(
                '练习完成！',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '你答对 $correctCount / ${questions.length} 题',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      return _buildQuestionCard(index, questions[index]);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRestart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF667eea),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  '再来一次',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, Question question) {
    final isCorrect = question.isCorrect;
    final userAnswer = question.userAnswer;
    final isNotJudged = isCorrect == null;

    Color backgroundColor;
    Color iconColor;
    IconData icon;
    String answerText;

    if (isNotJudged) {
      backgroundColor = Colors.orange.withValues(alpha: 0.8);
      iconColor = Colors.orange.shade300;
      icon = Icons.help;
      answerText = '（未评判）';
    } else if (isCorrect) {
      backgroundColor = Colors.green.withValues(alpha: 0.8);
      iconColor = Colors.green.shade300;
      icon = Icons.check_circle;
      answerText = '你的答案: $userAnswer ✓';
    } else {
      backgroundColor = Colors.red.withValues(alpha: 0.8);
      iconColor = Colors.red.shade300;
      icon = Icons.cancel;
      answerText = '正确答案: ${question.correctAnswer} (你的: $userAnswer)';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${question.num1} ${question.operator} ${question.num2} = ?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  answerText,
                  style: TextStyle(
                    color: isNotJudged ? Colors.orange.shade200 : (isCorrect ? Colors.green.shade200 : Colors.orange.shade200),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
        ],
      ),
    );
  }
}
