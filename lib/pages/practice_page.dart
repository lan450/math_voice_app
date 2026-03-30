import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/question.dart';
import '../services/tts_service.dart';
import '../services/question_generator.dart';
import '../services/settings_service.dart';
import '../widgets/numeric_keypad.dart';
import 'result_page.dart';

class PracticePage extends StatefulWidget {
  final bool showSubtitles;
  final double englishSpeechRate;
  final SettingsService settingsService;

  const PracticePage({
    super.key,
    this.showSubtitles = false,
    this.englishSpeechRate = 0.5,
    required this.settingsService,
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

  // 计时相关
  Timer? _timer;
  int _remainingSeconds = 30;
  static const int _timerDuration = 30;

  // 设置相关
  bool get _timerEnabled => widget.settingsService.timerEnabled;
  bool get _voiceOnlyMode => widget.settingsService.voiceOnlyMode;
  bool get _showQuestionText => widget.settingsService.showQuestionText;

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

  void _startTimer() {
    _cancelTimer();
    _remainingSeconds = _timerDuration;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onTimerTimeout();
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTimerTimeout() {
    if (_gameState == null || _gameState!.phase != GamePhase.listening) return;
    if (_isProcessing) return;

    debugPrint('Timer timeout reached');

    if (_voiceOnlyMode) {
      // 纯语音模式：播报正确答案，不记对错
      _isProcessing = true;
      _speakCorrectAnswer();
    } else {
      // 计时模式：标记为错误，继续下一题
      _isProcessing = true;
      _handleTimeoutAsWrong();
    }
  }

  Future<void> _speakCorrectAnswer() async {
    final question = _gameState!.currentQuestion!;
    final answer = question.correctAnswer;

    if (question.isChinese) {
      await _ttsService.speakChinese('时间到，答案是$answer');
    } else {
      await _ttsService.speakEnglish("Time's up. The answer is $answer");
    }

    // 纯语音模式不记录对错，直接跳到下一题
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _isProcessing = false;
        _currentInput = '';
        _nextQuestion();
      }
    });
  }

  void _handleTimeoutAsWrong() {
    final question = _gameState!.currentQuestion!;

    // 更新题目状态为错误
    final updatedQuestions = List<Question>.from(_gameState!.questions);
    updatedQuestions[_gameState!.currentIndex] = Question(
      num1: question.num1,
      num2: question.num2,
      operator: question.operator,
      correctAnswer: question.correctAnswer,
      isChinese: question.isChinese,
      userAnswer: null,
      isCorrect: false,
    );

    setState(() {
      _gameState = _gameState!.copyWith(
        questions: updatedQuestions,
        phase: GamePhase.answering,
      );
    });

    // 播报超时
    _speakTimeout(question);

    Future.delayed(const Duration(seconds: 2), () {
      debugPrint('handleTimeoutAsWrong: moving to next question');
      if (mounted) {
        _isProcessing = false;
        _currentInput = '';
        _nextQuestion();
      }
    });
  }

  Future<void> _speakTimeout(Question question) async {
    if (question.isChinese) {
      await _ttsService.speakChinese('时间到！答案是${question.correctAnswer}');
    } else {
      await _ttsService.speakEnglish("Time's up! The answer is ${question.correctAnswer}");
    }
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

    // 纯语音模式：播报题目后等待3秒，然后自动播报正确答案
    if (_voiceOnlyMode) {
      // 启动计时器用于UI进度显示
      if (_timerEnabled) {
        _startTimer();
      }

      // 播报题目
      if (question.isChinese) {
        await _ttsService.speakChinese(question.questionTextChinese);
      } else {
        await _ttsService.speakEnglish(question.questionTextEnglish);
      }

      // 等待3秒
      await Future.delayed(const Duration(seconds: 3));

      // 自动播报正确答案
      await _autoSpeakAnswer(question);

      // 取消计时器
      _cancelTimer();

      // 标记问题为未评判（纯语音模式不记录对错）
      final updatedQuestions = List<Question>.from(_gameState!.questions);
      updatedQuestions[_gameState!.currentIndex] = Question(
        num1: question.num1,
        num2: question.num2,
        operator: question.operator,
        correctAnswer: question.correctAnswer,
        isChinese: question.isChinese,
        userAnswer: null,
        isCorrect: null, // 纯语音模式不记录对错
      );

      setState(() {
        _gameState = _gameState!.copyWith(
          questions: updatedQuestions,
          phase: GamePhase.answering,
        );
      });

      // 自动进入下一题
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _isProcessing = false;
          _nextQuestion();
        }
      });

      return;
    }

    // 非纯语音模式：正常流程
    // 启动计时器（如果开启）
    if (_timerEnabled) {
      _startTimer();
    }

    // 播报题目
    if (question.isChinese) {
      await _ttsService.speakChinese(question.questionTextChinese);
    } else {
      await _ttsService.speakEnglish(question.questionTextEnglish);
    }
  }

  Future<void> _autoSpeakAnswer(Question question) async {
    if (question.isChinese) {
      await _ttsService.speakChinese('答案是${question.correctAnswer}');
    } else {
      await _ttsService.speakEnglish('The answer is ${question.correctAnswer}');
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
    _cancelTimer(); // 取消计时器
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
      isCorrect: _voiceOnlyMode ? null : isCorrect,
    );

    setState(() {
      _gameState = _gameState!.copyWith(
        questions: updatedQuestions,
        phase: GamePhase.answering,
      );
    });

    // 播报结果
    if (_voiceOnlyMode) {
      // 纯语音模式不播报对错，只播报正确答案
      await _speakResultVoiceOnly(question);
    } else {
      await _speakResult(isCorrect, question);
    }

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

  Future<void> _speakResultVoiceOnly(Question question) async {
    // 纯语音模式只播报正确答案
    if (question.isChinese) {
      await _ttsService.speakChinese('答案是${question.correctAnswer}');
    } else {
      await _ttsService.speakEnglish('The answer is ${question.correctAnswer}');
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

    // 纯语音模式不播报正确率
    if (_voiceOnlyMode) {
      await Future.delayed(const Duration(seconds: 1));
      await _ttsService.speakChinese('练习结束');
      await _ttsService.speakEnglish('Practice finished');
    } else {
      // 播报正确率
      final correct = _gameState!.correctCount;
      final total = _gameState!.totalCount;

      await Future.delayed(const Duration(seconds: 1));

      await _ttsService.speakChinese('你答对了$correct题，共$total题');
      await _ttsService.speakEnglish('You got $correct out of $total correct');
    }

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
                      settingsService: widget.settingsService,
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
    _cancelTimer();
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

              // 计时条（如果开启计时模式且非纯语音模式）
              if (_timerEnabled && !_voiceOnlyMode && _gameState?.phase == GamePhase.listening)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _remainingSeconds / _timerDuration,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _remainingSeconds <= 5
                              ? Colors.red
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_remainingSeconds 秒',
                        style: TextStyle(
                          fontSize: 14,
                          color: _remainingSeconds <= 5
                              ? Colors.red.shade300
                              : Colors.white70,
                        ),
                      ),
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
                      if (_showQuestionText || !_isQuestionPhase)
                        Text(
                          _getStatusText(),
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        )
                      else
                        const Text(
                          '...',
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 30),

                      // 纯语音模式显示自动播报提示
                      if (_voiceOnlyMode)
                        const Text(
                          '自动播报中...',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        )
                      else ...[
                        // 输入显示（非纯语音模式）
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
                    ],
                  ),
                ),
              ),

              // 数字键盘（非纯语音模式）
              if (_gameState?.phase == GamePhase.listening && !_voiceOnlyMode)
                NumericKeypad(
                  onInput: _onKeypadInput,
                  onSubmit: _onSubmit,
                ),

              // 结果提示（只在非纯语音模式显示）
              if (_gameState?.phase == GamePhase.answering && !_voiceOnlyMode)
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

  bool get _isQuestionPhase {
    if (_gameState == null) return false;
    return _gameState!.phase == GamePhase.listening;
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
        } else if (q.isCorrect == null) {
          // 纯语音模式：只显示正确答案
          return q.isChinese
              ? '正确答案是${q.correctAnswer}'
              : 'The answer is ${q.correctAnswer}';
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