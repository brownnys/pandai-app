import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user_performance.dart';
import '../models/question_model.dart';
import '../services/ml_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String topicId;
  final String topicName;

  QuizScreen({required this.topicId, required this.topicName});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // Services
  final MLService mlService = MLService();
  final FirestoreService firestoreService = FirestoreService();

  // Performance tracking
  late UserPerformance performance;

  // Quiz state
  bool isLoading = true;
  int currentQuestionIndex = 0;
  int currentDifficulty = 2; // Start with Medium
  DateTime questionStartTime = DateTime.now();

  // Current question
  QuestionModel? currentQuestion;
  int? selectedOption;

  // Results
  int correctAnswers = 0;
  final int totalQuestions = 10;
  List<Map<String, dynamic>> answersHistory = [];

  // Timer
  Timer? _timer;
  int _secondsElapsed = 0;
  int _questionSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initQuiz();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ========================================================================
  // INITIALIZATION
  // ========================================================================

  Future<void> _initQuiz() async {
    try {
      // Load performance
      performance = await StorageService.loadPerformance(widget.topicId);

      print('📊 ===== QUIZ STARTED =====');
      print('Topic: ${widget.topicName}');
      print('Performance: ${performance.toString()}');
      print('========================\n');

      // Load first question
      await _loadNextQuestion();

      setState(() => isLoading = false);
    } catch (e) {
      print('❌ Error init quiz: $e');
      _showError('Gagal memuat kuis. Pastikan sudah ada soal di Firestore.');
    }
  }

  // ========================================================================
  // ML PREDICTION & QUESTION LOADING
  // ========================================================================

  Future<void> _loadNextQuestion() async {
    setState(() => isLoading = true);

    try {
      // 🤖 ML PREDICTION - Predict next difficulty
      if (currentQuestionIndex > 0) {
        final prediction = await mlService.predictDifficulty(
          previousScore: performance.previousScore,
          avgTime: performance.avgTimePerQuestion,
          correctStreak: performance.correctStreak,
          totalAttempts: performance.totalAttempts,
          lastDifficulty: performance.lastDifficulty,
        );

        currentDifficulty = prediction['difficulty'];

        // Show feedback
        _showPredictionSnackbar(prediction);
      }

      // Fetch question from Firestore
      currentQuestion = await firestoreService.getQuestion(
        topicId: widget.topicId,
        difficulty: currentDifficulty,
      );

      if (currentQuestion == null) {
        throw Exception('No questions available for this difficulty');
      }

      // Reset state
      selectedOption = null;
      questionStartTime = DateTime.now();
      _questionSeconds = 0;

      setState(() => isLoading = false);
    } catch (e) {
      print('❌ Error loading question: $e');
      setState(() => isLoading = false);
      _showError('Gagal memuat soal. Pastikan soal tersedia di Firestore.');
    }
  }

  // ========================================================================
  // ANSWER SUBMISSION
  // ========================================================================

  void _submitAnswer() {
    if (selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Pilih jawaban terlebih dahulu!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Calculate time spent
    double timeSpent = DateTime.now()
        .difference(questionStartTime)
        .inSeconds
        .toDouble();

    // Check if correct
    bool isCorrect = selectedOption == currentQuestion!.correctAnswerIndex;

    // Update performance
    performance.updateAfterAnswer(
      isCorrect: isCorrect,
      timeSpent: timeSpent,
      currentDifficulty: currentDifficulty,
    );

    // Save answer history
    answersHistory.add({
      'questionIndex': currentQuestionIndex,
      'difficulty': currentDifficulty,
      'difficultyName': currentQuestion!.difficultyName,
      'isCorrect': isCorrect,
      'timeSpent': timeSpent,
      'question': currentQuestion!.question,
      'selectedAnswer': currentQuestion!.options[selectedOption!],
      'correctAnswer':
          currentQuestion!.options[currentQuestion!.correctAnswerIndex],
    });

    if (isCorrect) correctAnswers++;

    // Save performance
    StorageService.savePerformance(widget.topicId, performance);

    // Show feedback
    _showAnswerFeedback(isCorrect);

    // Move to next question
    Future.delayed(Duration(seconds: 2), () {
      currentQuestionIndex++;

      if (currentQuestionIndex < totalQuestions) {
        _loadNextQuestion();
      } else {
        _finishQuiz();
      }
    });
  }

  // ========================================================================
  // QUIZ COMPLETION
  // ========================================================================

  Future<void> _finishQuiz() async {
    _timer?.cancel();

    // Calculate final score
    double finalScore = (correctAnswers / totalQuestions) * 100;

    // Update performance score
    performance.updateScore(finalScore);

    // Save to storage
    await StorageService.savePerformance(widget.topicId, performance);

    // Save to Firestore (optional - untuk history)
    await firestoreService.saveQuizHistory(
      topicId: widget.topicId,
      topicName: widget.topicName,
      score: finalScore,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      avgTime: performance.avgTimePerQuestion,
      answers: answersHistory,
    );

    print('\n📊 ===== QUIZ COMPLETED =====');
    print('Score: ${finalScore.toStringAsFixed(1)}%');
    print('Correct: $correctAnswers/$totalQuestions');
    print('Updated Performance: ${performance.toString()}');
    print('========================\n');

    // Navigate to results
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          topicName: widget.topicName,
          score: finalScore,
          correctAnswers: correctAnswers,
          totalQuestions: totalQuestions,
          answersHistory: answersHistory,
          performance: performance,
        ),
      ),
    );
  }

  // ========================================================================
  // TIMER
  // ========================================================================

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
        _questionSeconds++;
      });
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // ========================================================================
  // UI HELPERS
  // ========================================================================

  Color _getDifficultyColor(int difficulty) {
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

  String _getDifficultyName(int difficulty) {
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

  void _showPredictionSnackbar(Map<String, dynamic> prediction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text('🎯 '),
            Text('Next difficulty: ${prediction['difficulty_name']}'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: _getDifficultyColor(prediction['difficulty']),
      ),
    );
  }

  void _showAnswerFeedback(bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isCorrect ? Colors.green[50] : Colors.red[50],
        title: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
              size: 32,
            ),
            SizedBox(width: 12),
            Text(
              isCorrect ? 'Benar!' : 'Salah!',
              style: TextStyle(
                color: isCorrect ? Colors.green[900] : Colors.red[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Penjelasan:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              currentQuestion!.explanation,
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'Waktu: ${_questionSeconds}s',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Lanjut',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to home
            },
            child: Text('Kembali'),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // BUILD UI
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.topicName),
          backgroundColor: Color(0xFF667EEA),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
              ),
              SizedBox(height: 20),
              Text(
                'Memuat soal...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.topicName),
        backgroundColor: Color(0xFF667EEA),
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, size: 20),
                  SizedBox(width: 4),
                  Text(
                    _formatTime(_secondsElapsed),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: currentQuestionIndex / totalQuestions,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
            minHeight: 8,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question counter & difficulty
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Soal ${currentQuestionIndex + 1}/$totalQuestions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(currentDifficulty),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getDifficultyName(currentDifficulty),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Question box
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                    child: Text(
                      currentQuestion!.question,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Options
                  Text(
                    'Pilih Jawaban:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 16),
                  ...List.generate(
                    currentQuestion!.options.length,
                    (index) => _buildOption(
                      index: index,
                      text: currentQuestion!.options[index],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submit button
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedOption == null ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF667EEA),
                  disabledBackgroundColor: Colors.grey[300],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Submit Jawaban',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({required int index, required String text}) {
    bool isSelected = selectedOption == index;
    String letter = ['A', 'B', 'C', 'D'][index];

    return GestureDetector(
      onTap: () {
        setState(() => selectedOption = index);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF667EEA).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF667EEA) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF667EEA) : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Color(0xFF667EEA), size: 24),
          ],
        ),
      ),
    );
  }
}
