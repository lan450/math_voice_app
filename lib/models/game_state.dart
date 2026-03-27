import 'question.dart';

enum GamePhase {
  idle,
  ready,
  listening,
  answering,
  finished,
}

class GameState {
  final List<Question> questions;
  final int currentIndex;
  final GamePhase phase;

  const GameState({
    required this.questions,
    this.currentIndex = 0,
    this.phase = GamePhase.idle,
  });

  Question? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get correctCount => questions.where((q) => q.isCorrect == true).length;

  int get totalCount => questions.length;

  bool get isFinished => phase == GamePhase.finished;

  GameState copyWith({
    List<Question>? questions,
    int? currentIndex,
    GamePhase? phase,
  }) {
    return GameState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      phase: phase ?? this.phase,
    );
  }
}
