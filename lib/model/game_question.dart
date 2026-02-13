class GameQuestion {
  final String id;
  final String gameType;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String difficulty;
  final Map<String, dynamic> meta;

  GameQuestion({
    required this.id,
    required this.gameType,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
    this.meta = const {},
  });

  factory GameQuestion.fromJson(Map<String, dynamic> json) {
    return GameQuestion(
      id: json['_id'] ?? '',
      gameType: json['gameType'] ?? '',
      questionText: json['questionText'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
      difficulty: json['difficulty'] ?? 'Medium',
      meta: json['meta'] ?? {},
    );
  }
}
