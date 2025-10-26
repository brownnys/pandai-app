class QuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer; // A, B, C, or D
  final String explanation;
  final int difficulty; // 1=Easy, 2=Medium, 3=Hard
  final String topic;

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
    required this.topic,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map, String id) {
    return QuestionModel(
      id: id,
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? 'A',
      explanation: map['explanation'] ?? '',
      difficulty: map['difficulty'] ?? 2,
      topic: map['topic'] ?? '',
    );
  }

  int get correctAnswerIndex {
    return {'A': 0, 'B': 1, 'C': 2, 'D': 3}[correctAnswer] ?? 0;
  }

  String get difficultyName {
    switch (difficulty) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      default:
        return 'Medium';
    }
  }
}
