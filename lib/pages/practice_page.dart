import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/question.dart';
import '../services/tts_service.dart';
import '../services/question_generator.dart';
import '../widgets/numeric_keypad.dart';
import 'result_page.dart';

class PracticePage extends StatefulWidget {
  final bool showSubtitles;
  final double englishSpeechRate;

  const PracticePage({
    super.key,
    this.showSubtitles = false,
    this.englishSpeechRate = 0.5,
  });

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  final TtsService _ttsService = TtsService();
  final QuestionGenerator _questionGenerator = QuestionGenerator();

  GameState? _gameState;
  bool _isProcessing = false;
  String _currentInput = '';
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    debugPrint('_initServices: starting');

    // 初始化TTS
    _initInBackground();
  }

  Future<void> _initInBackground() async {
    debugPrint('_initInBackground: starting');
    try {
      await _ttsService.init();

      // 设置英文语速
      _ttsService.setEnglishSpeechRate(widget.englishSpeechRate);

      _servicesInitialized = true;
      debugPrint('_initInBackground: TTS initialized');

      // 立即开始游戏
      _startGame();
    } catch (e) {
      debugPrint('_initInBackground: error: $e');
      // 即使失败也继续开始游戏
      _servicesInitialized = true;
      _startGame();
    }
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

    debugPrint('askCurrentQuestion: index=${_gameState!.currentIndex}, question=${question.questionTextChinese}');

    // 重置输入
    _currentInput = '';
    _isProcessing = false;

    setState(() {
      _gameState = _gameState!.copyWith(phase: GamePhase.listening);
    });

    // 播报题目
    if (question.isChinese) {
      await _ttsService.speakChinese(question.questionTextChinese);
    } else {
      await _ttsService.speakEnglish(question.questionTextEnglish);
    }
  }

  void _onKeypadInput(String value) {
    if (_isProcessing) return;
    if (_gameState?.phase != GamePhase.listening) return;

    setState(() {
      _currentInput = value;
    });
  }

  void _onSubmit() {
    if (_isProcessing) return;
    if (_gameState?.phase != GamePhase.listening) return;
    if (_currentInput.isEmpty) return;

    final number = int.tryParse(_currentInput);
    if (number == null) return;

    _isProcessing = true;
    _handleAnswer(number);
  }

  Future<void> _handleAnswer(int number) async {
    if (_gameState == null) {
      debugPrint('handleAnswer: no game state');
      _isProcessing = false;
      return;
    }

    final question = _gameState!.currentQuestion!;
    final isCorrect = number == question.correctAnswer;

    debugPrint('handleAnswer: number=$number, correctAnswer=${question.correctAnswer}, isCorrect=$isCorrect');

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

    // 标记处理完成，准备下一题
    Future.delayed(const Duration(seconds: 1), () {
      debugPrint('handleAnswer: moving to next question');
      if (mounted) {
        _isProcessing = false;
        _currentInput = '';
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
    if (_gameState == null) {
      debugPrint('nextQuestion: no game state');
      return;
    }

    debugPrint('nextQuestion: currentIndex=${_gameState!.currentIndex}, total=${_gameState!.questions.length}');

    final nextIndex = _gameState!.currentIndex + 1;

    if (nextIndex >= _gameState!.questions.length) {
      debugPrint('nextQuestion: all questions done, finishing');
      _finishGame();
    } else {
      debugPrint('nextQuestion: moving to index $nextIndex');

      setState(() {
        _gameState = _gameState!.copyWith(
          currentIndex: nextIndex,
          phase: GamePhase.ready,
        );
      });

      // 播报下一题
      Future.delayed(const Duration(seconds: 1), () {
        debugPrint('nextQuestion: asking next question');
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
                    builder: (context) => PracticePage(
                      showSubtitles: widget.showSubtitles,
                      englishSpeechRate: widget.englishSpeechRate,
                    ),
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
    _ttsService.dispose();
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
          child: Column(
            children: [
              // 顶部进度
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    if (_gameState != null)
                      Text(
                        '第 ${_gameState!.currentIndex + 1} / ${_gameState!.totalCount} 题',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // 题目显示区域
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🧮',
                        style: TextStyle(fontSize: 60),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _getStatusText(),
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // 输入显示
                      Container(
                        width: 200,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Center(
                          child: Text(
                            _currentInput.isEmpty ? '?' : _currentInput,
                            style: TextStyle(
                              fontSize: 36,
                              color: _currentInput.isEmpty
                                  ? Colors.white54
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '输入答案',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 数字键盘
              if (_gameState?.phase == GamePhase.listening)
                NumericKeypad(
                  onInput: _onKeypadInput,
                  onSubmit: _onSubmit,
                ),

              // 结果提示
              if (_gameState?.phase == GamePhase.answering)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _getResultText(),
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    if (_gameState == null) return '准备中...';

    if (!_servicesInitialized && _gameState!.phase == GamePhase.ready) {
      return '即将开始...';
    }

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
        final q = _gameState!.currentQuestion;
        if (q == null) return '';
        if (q.isCorrect == true) {
          return q.isChinese ? '回答正确！' : 'Correct!';
        } else {
          return q.isChinese
              ? '回答错误，正确答案是${q.correctAnswer}'
              : 'Wrong! The answer is ${q.correctAnswer}';
        }
      case GamePhase.finished:
        return '练习完成！';
    }
  }

  String _getResultText() {
    final q = _gameState?.currentQuestion;
    if (q == null) return '';
    if (q.isCorrect == true) {
      return q.isChinese ? '✓ 正确！' : '✓ Correct!';
    } else {
      return q.isChinese
          ? '✗ 答案是 ${q.correctAnswer}'
          : '✗ The answer is ${q.correctAnswer}';
    }
  }
}
