import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/game_state.dart';
import '../models/question.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../services/question_generator.dart';
import 'result_page.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  final TtsService _ttsService = TtsService();
  final SttService _sttService = SttService();
  final QuestionGenerator _questionGenerator = QuestionGenerator();

  GameState? _gameState;
  Timer? _timeoutTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    // 请求麦克风权限
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要麦克风权限才能使用语音功能')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    // 初始化TTS和STT
    await _ttsService.init();
    await _sttService.init();

    _sttService.onResult = _onSpeechResult;
    _sttService.onError = (error) {
      debugPrint('STT Error: $error');
    };

    // 开始游戏
    _startGame();
  }

  void _startGame() {
    final questions = _questionGenerator.generateQuestions();
    _gameState = GameState(
      questions: questions,
      phase: GamePhase.ready,
    );

    // 延迟开始，让用户准备好
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _gameState != null) {
        _speakStart();
      }
    });
  }

  Future<void> _speakStart() async {
    final isChinese = _gameState?.currentQuestion?.isChinese ?? true;
    if (isChinese) {
      await _ttsService.speakChinese('开始练习');
    } else {
      await _ttsService.speakEnglish("Let's start practice");
    }

    // 播报第一题
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _askCurrentQuestion();
      }
    });
  }

  Future<void> _askCurrentQuestion() async {
    if (_gameState == null) return;

    final question = _gameState!.currentQuestion;
    if (question == null) {
      _finishGame();
      return;
    }

    setState(() {
      _gameState = _gameState!.copyWith(phase: GamePhase.listening);
    });

    // 播报题目
    if (question.isChinese) {
      await _ttsService.speakChinese(question.questionTextChinese);
    } else {
      await _ttsService.speakEnglish(question.questionTextEnglish);
    }

    // 开始监听
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startListening();
      }
    });
  }

  void _startListening() {
    final question = _gameState?.currentQuestion;
    if (question == null) return;

    // 设置超时
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _gameState?.phase == GamePhase.listening) {
        _handleTimeout();
      }
    });

    _sttService.startListening(
      localeId: question.isChinese ? 'zh_CN' : 'en_US',
    );
  }

  void _handleTimeout() {
    _sttService.stopListening();
    _handleAnswer(null);
  }

  void _onSpeechResult(String text) {
    if (_isProcessing) return;
    _isProcessing = true;

    _sttService.stopListening();
    _timeoutTimer?.cancel();

    final number = extractNumber(text);
    _handleAnswer(number);
  }

  Future<void> _handleAnswer(int? number) async {
    if (_gameState == null || _isProcessing) return;

    final question = _gameState!.currentQuestion!;
    final isCorrect = number == question.correctAnswer;

    // 更新题目状态
    final updatedQuestions = List<Question>.from(_gameState!.questions);
    updatedQuestions[_gameState!.currentIndex] = Question(
      num1: question.num1,
      num2: question.num2,
      operator: question.operator,
      correctAnswer: question.correctAnswer,
      isChinese: question.isChinese,
      userAnswer: number,
      isCorrect: isCorrect,
    );

    setState(() {
      _gameState = _gameState!.copyWith(
        questions: updatedQuestions,
        phase: GamePhase.answering,
      );
    });

    // 播报结果
    await _speakResult(isCorrect, question);

    _isProcessing = false;

    // 下一题或结束
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  Future<void> _speakResult(bool isCorrect, Question question) async {
    if (isCorrect) {
      if (question.isChinese) {
        await _ttsService.speakChinese('正确！');
      } else {
        await _ttsService.speakEnglish('Correct!');
      }
    } else {
      if (question.isChinese) {
        await _ttsService.speakChinese('答案是${question.correctAnswer}');
      } else {
        await _ttsService.speakEnglish('The answer is ${question.correctAnswer}');
      }
    }
  }

  void _nextQuestion() {
    if (_gameState == null) return;

    final nextIndex = _gameState!.currentIndex + 1;

    if (nextIndex >= _gameState!.questions.length) {
      _finishGame();
    } else {
      setState(() {
        _gameState = _gameState!.copyWith(
          currentIndex: nextIndex,
          phase: GamePhase.ready,
        );
      });

      // 播报下一题
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _askCurrentQuestion();
        }
      });
    }
  }

  Future<void> _finishGame() async {
    if (_gameState == null) return;

    setState(() {
      _gameState = _gameState!.copyWith(phase: GamePhase.finished);
    });

    // 播报正确率
    final correct = _gameState!.correctCount;
    final total = _gameState!.totalCount;

    await Future.delayed(const Duration(seconds: 1));

    await _ttsService.speakChinese('你答对了$correct题，共$total题');
    await _ttsService.speakEnglish('You got $correct out of $total correct');

    // 跳转到结果页
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResultPage(
              questions: _gameState!.questions,
              onRestart: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const PracticePage(),
                  ),
                );
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _ttsService.dispose();
    _sttService.dispose();
    super.dispose();
  }

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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🎤',
                  style: TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 30),
                Text(
                  _getStatusText(),
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (_gameState != null)
                  Text(
                    '第 ${_gameState!.currentIndex + 1} / ${_gameState!.totalCount} 题',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                const SizedBox(height: 40),
                _buildAnimation(),
                const SizedBox(height: 30),
                if (_gameState?.phase == GamePhase.listening)
                  const Text(
                    '请回答...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white60,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    if (_gameState == null) return '准备中...';

    switch (_gameState!.phase) {
      case GamePhase.idle:
        return '准备中...';
      case GamePhase.ready:
        return '准备好了';
      case GamePhase.listening:
        final q = _gameState!.currentQuestion;
        if (q == null) return '';
        return q.isChinese ? q.questionTextChinese : q.questionTextEnglish;
      case GamePhase.answering:
        return '回答正确！';
      case GamePhase.finished:
        return '练习完成！';
    }
  }

  Widget _buildAnimation() {
    if (_gameState?.phase == GamePhase.listening) {
      return const SizedBox(
        width: 100,
        height: 100,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      );
    }

    return const SizedBox(
      width: 100,
      height: 100,
      child: Icon(
        Icons.mic,
        size: 80,
        color: Colors.white,
      ),
    );
  }
}
