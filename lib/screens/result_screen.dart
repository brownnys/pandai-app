import 'package:flutter/material.dart';
import '../models/user_performance.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatelessWidget {
  final String topicName;
  final double score;
  final int correctAnswers;
  final int totalQuestions;
  final List<Map<String, dynamic>> answersHistory;
  final UserPerformance performance;

  ResultScreen({
    required this.topicName,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.answersHistory,
    required this.performance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Hasil Quiz'),
        backgroundColor: Color(0xFF667EEA),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              // Score Card
              _buildScoreCard(),
              SizedBox(height: 24),

              // Stats
              _buildStats(),
              SizedBox(height: 24),

              // Performance Analysis
              _buildPerformanceAnalysis(),
              SizedBox(height: 24),

              // AI Recommendation
              _buildRecommendation(),
              SizedBox(height: 24),

              // Answers Review
              _buildAnswersReview(),
              SizedBox(height: 32),

              // Buttons
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    Color scoreColor = score >= 80
        ? Colors.green
        : score >= 60
        ? Colors.orange
        : Colors.red;

    String emoji = score >= 80
        ? '🎉'
        : score >= 60
        ? '👍'
        : '💪';

    String message = score >= 80
        ? 'Luar Biasa!'
        : score >= 60
        ? 'Bagus!'
        : 'Tetap Semangat!';

    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            topicName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              '${score.toStringAsFixed(0)}%',
              style: TextStyle(
                color: scoreColor,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            '$correctAnswers dari $totalQuestions soal benar',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    double avgTime = performance.avgTimePerQuestion;
    int maxStreak = _calculateMaxStreak();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Statistik',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.timer_outlined,
                  label: 'Waktu Rata-rata',
                  value: '${avgTime.toStringAsFixed(1)}s',
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_fire_department,
                  label: 'Streak Terbaik',
                  value: '$maxStreak',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.quiz_outlined,
                  label: 'Total Percobaan',
                  value: '${performance.totalAttempts}',
                  color: Colors.purple,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.trending_up,
                  label: 'Skor Rata-rata',
                  value: '${performance.previousScore.toStringAsFixed(0)}%',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceAnalysis() {
    Map<String, int> difficultyCount = {'Easy': 0, 'Medium': 0, 'Hard': 0};

    for (var answer in answersHistory) {
      String difficulty = answer['difficultyName'];
      difficultyCount[difficulty] = (difficultyCount[difficulty] ?? 0) + 1;
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Analisis Performa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildDifficultyBar('Easy', difficultyCount['Easy']!, Colors.green),
          SizedBox(height: 8),
          _buildDifficultyBar(
            'Medium',
            difficultyCount['Medium']!,
            Colors.orange,
          ),
          SizedBox(height: 8),
          _buildDifficultyBar('Hard', difficultyCount['Hard']!, Colors.red),
        ],
      ),
    );
  }

  Widget _buildDifficultyBar(String label, int count, Color color) {
    double percentage = (count / totalQuestions) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              '$count soal (${percentage.toStringAsFixed(0)}%)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: count / totalQuestions,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendation() {
    String recommendation = _getRecommendation();
    IconData icon = score >= 80
        ? Icons.emoji_events
        : score >= 60
        ? Icons.lightbulb_outline
        : Icons.fitness_center;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎯 Rekomendasi AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  recommendation,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswersReview() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📝 Review Jawaban',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ...answersHistory.asMap().entries.map((entry) {
            int index = entry.key;
            var answer = entry.value;
            return _buildAnswerItem(index + 1, answer);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAnswerItem(int number, Map<String, dynamic> answer) {
    bool isCorrect = answer['isCorrect'];
    Color color = isCorrect ? Colors.green : Colors.red;
    IconData icon = isCorrect ? Icons.check_circle : Icons.cancel;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    SizedBox(width: 6),
                    Text(
                      isCorrect ? 'Benar' : 'Salah',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(answer),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        answer['difficultyName'],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  answer['question'],
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                if (!isCorrect) ...[
                  SizedBox(height: 8),
                  Text(
                    'Jawaban yang benar: ${answer['correctAnswer']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF667EEA),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Kembali ke Home',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // Restart quiz dengan topic yang sama
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(
                    topicId: topicName.toLowerCase(),
                    topicName: topicName,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Color(0xFF667EEA), width: 2),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Ulangi Quiz',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667EEA),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  int _calculateMaxStreak() {
    int maxStreak = 0;
    int currentStreak = 0;

    for (var answer in answersHistory) {
      if (answer['isCorrect']) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }

    return maxStreak;
  }

  String _getRecommendation() {
    if (score >= 80) {
      return 'Performa Anda sangat baik! Sistem akan memberikan soal dengan tingkat kesulitan yang lebih tinggi pada quiz berikutnya untuk terus mengasah kemampuan Anda.';
    } else if (score >= 60) {
      return 'Performa Anda cukup baik. Sistem akan menyesuaikan tingkat kesulitan soal agar sesuai dengan kemampuan Anda saat ini. Terus berlatih!';
    } else {
      return 'Tetap semangat! Sistem akan memberikan soal dengan tingkat kesulitan yang lebih sesuai untuk membantu Anda memahami materi dengan lebih baik. Latihan membuat sempurna!';
    }
  }

  Color _getDifficultyColor(Map<String, dynamic> answer) {
    int difficulty = answer['difficulty'];
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
