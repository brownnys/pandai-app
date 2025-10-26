import 'dart:convert';

class UserPerformance {
  double previousScore;
  double avgTimePerQuestion;
  int correctStreak;
  int totalAttempts;
  int lastDifficulty;

  UserPerformance({
    this.previousScore = 50.0,
    this.avgTimePerQuestion = 30.0,
    this.correctStreak = 0,
    this.totalAttempts = 0,
    this.lastDifficulty = 2, // Default: Medium
  });

  // Update setelah jawab soal
  void updateAfterAnswer({
    required bool isCorrect,
    required double timeSpent,
    required int currentDifficulty,
  }) {
    // Update streak
    if (isCorrect) {
      correctStreak++;
    } else {
      correctStreak = 0;
    }

    // Update average time (moving average)
    if (totalAttempts > 0) {
      avgTimePerQuestion =
          (avgTimePerQuestion * totalAttempts + timeSpent) /
          (totalAttempts + 1);
    } else {
      avgTimePerQuestion = timeSpent;
    }

    lastDifficulty = currentDifficulty;
    totalAttempts++;
  }

  // Update score setelah quiz selesai
  void updateScore(double newScore) {
    if (totalAttempts > 0) {
      // Weighted: 70% old, 30% new
      previousScore = (previousScore * 0.7) + (newScore * 0.3);
    } else {
      previousScore = newScore;
    }
  }

  // Reset untuk topic baru
  void reset() {
    previousScore = 50.0;
    avgTimePerQuestion = 30.0;
    correctStreak = 0;
    totalAttempts = 0;
    lastDifficulty = 2;
  }

  // Convert to Map untuk storage
  Map<String, dynamic> toMap() {
    return {
      'previousScore': previousScore,
      'avgTimePerQuestion': avgTimePerQuestion,
      'correctStreak': correctStreak,
      'totalAttempts': totalAttempts,
      'lastDifficulty': lastDifficulty,
    };
  }

  // Create from Map
  factory UserPerformance.fromMap(Map<String, dynamic> map) {
    return UserPerformance(
      previousScore: (map['previousScore'] ?? 50.0).toDouble(),
      avgTimePerQuestion: (map['avgTimePerQuestion'] ?? 30.0).toDouble(),
      correctStreak: map['correctStreak'] ?? 0,
      totalAttempts: map['totalAttempts'] ?? 0,
      lastDifficulty: map['lastDifficulty'] ?? 2,
    );
  }

  // JSON conversion
  String toJson() => json.encode(toMap());

  factory UserPerformance.fromJson(String source) =>
      UserPerformance.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Performance(score: ${previousScore.toStringAsFixed(1)}, '
        'time: ${avgTimePerQuestion.toStringAsFixed(1)}s, '
        'streak: $correctStreak, attempts: $totalAttempts)';
  }
}
