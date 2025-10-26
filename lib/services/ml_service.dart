import 'dart:convert';
import 'package:http/http.dart' as http;

class MLService {
  // 🔥 GANTI DENGAN URL API KALIAN SETELAH DEPLOY!
  // Untuk testing, pakai fallback rule-based prediction
  static const String API_BASE_URL = 'https://your-api-url.com';
  static const bool USE_API = false; // Set true kalau API sudah ready

  Future<Map<String, dynamic>> predictDifficulty({
    required double previousScore,
    required double avgTime,
    required int correctStreak,
    required int totalAttempts,
    required int lastDifficulty,
  }) async {
    print('\n🤖 ===== ML PREDICTION =====');
    print('Input:');
    print('  Score: $previousScore');
    print('  Avg Time: ${avgTime.toStringAsFixed(1)}s');
    print('  Streak: $correctStreak');
    print('  Attempts: $totalAttempts');
    print('  Last Difficulty: $lastDifficulty');

    if (USE_API) {
      return await _predictFromAPI(
        previousScore: previousScore,
        avgTime: avgTime,
        correctStreak: correctStreak,
        totalAttempts: totalAttempts,
        lastDifficulty: lastDifficulty,
      );
    } else {
      return _predictRuleBased(
        previousScore: previousScore,
        avgTime: avgTime,
        correctStreak: correctStreak,
      );
    }
  }

  // Predict menggunakan REST API
  Future<Map<String, dynamic>> _predictFromAPI({
    required double previousScore,
    required double avgTime,
    required int correctStreak,
    required int totalAttempts,
    required int lastDifficulty,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$API_BASE_URL/predict'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'previous_score': previousScore,
              'avg_time': avgTime,
              'correct_streak': correctStreak,
              'total_attempts': totalAttempts,
              'last_difficulty': lastDifficulty,
            }),
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['success'] == true) {
          print('✅ API Prediction: ${result['difficulty_name']}');
          return {
            'difficulty': result['difficulty'],
            'difficulty_name': result['difficulty_name'],
            'confidence': result['confidence'],
          };
        }
      }

      print('⚠️ API failed, using fallback');
      return _predictRuleBased(
        previousScore: previousScore,
        avgTime: avgTime,
        correctStreak: correctStreak,
      );
    } catch (e) {
      print('❌ API Error: $e');
      return _predictRuleBased(
        previousScore: previousScore,
        avgTime: avgTime,
        correctStreak: correctStreak,
      );
    }
  }

  // Predict menggunakan rule-based (fallback / untuk testing)
  Map<String, dynamic> _predictRuleBased({
    required double previousScore,
    required double avgTime,
    required int correctStreak,
  }) {
    double performanceScore = 0.0;

    // Score factor (0-1)
    performanceScore += (previousScore / 100) * 0.5;

    // Streak factor (0-1)
    performanceScore += (correctStreak / 5).clamp(0, 1) * 0.3;

    // Time factor (0-1): faster = better
    double timeFactor = 1 - (avgTime / 60).clamp(0, 1);
    performanceScore += timeFactor * 0.2;

    // Determine difficulty
    int difficulty;
    String difficultyName;

    if (performanceScore < 0.4) {
      difficulty = 1;
      difficultyName = 'Easy';
    } else if (performanceScore < 0.7) {
      difficulty = 2;
      difficultyName = 'Medium';
    } else {
      difficulty = 3;
      difficultyName = 'Hard';
    }

    print(
      '🎯 Rule-based Prediction: $difficultyName (score: ${performanceScore.toStringAsFixed(2)})',
    );
    print('========================\n');

    return {
      'difficulty': difficulty,
      'difficulty_name': difficultyName,
      'confidence': {
        'easy': difficulty == 1 ? 0.8 : 0.1,
        'medium': difficulty == 2 ? 0.8 : 0.1,
        'hard': difficulty == 3 ? 0.8 : 0.1,
      },
    };
  }

  // Test API connection
  Future<bool> testConnection() async {
    if (!USE_API) return false;

    try {
      final response = await http
          .get(Uri.parse('$API_BASE_URL/health'))
          .timeout(Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
