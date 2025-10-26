import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========================================================================
  // GET SINGLE QUESTION (AMAN DARI NULL)
  // ========================================================================
  Future<QuestionModel?> getQuestion({
    required String topicId,
    required int difficulty,
  }) async {
    try {
      final difficultyName = difficulty == 1
          ? 'easy'
          : difficulty == 2
          ? 'medium'
          : 'hard';

      print('📚 Fetching question: $topicId / $difficultyName');

      final snapshot = await _db
          .collection('questions')
          .doc(topicId)
          .collection(difficultyName)
          .get();

      // Cek apakah subcollection berisi data
      if (snapshot.docs.isEmpty) {
        print('⚠️ Tidak ada soal ditemukan di $topicId/$difficultyName');
        return null;
      }

      // Pilih acak 1 soal
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % snapshot.docs.length;
      final doc = snapshot.docs[randomIndex];
      final data = doc.data();

      // Pastikan data tidak kosong atau null
      if (data.isEmpty) {
        print('⚠️ Dokumen ${doc.id} kosong.');
        return null;
      }

      // Validasi field penting agar tidak null
      if (!data.containsKey('question') ||
          !data.containsKey('options') ||
          !data.containsKey('correctAnswer')) {
        print('⚠️ Field penting tidak lengkap di ${doc.id}');
        return null;
      }

      print('✅ Question loaded: ${doc.id}');
      return QuestionModel.fromMap(data, doc.id);
    } catch (e, st) {
      print('❌ Error getting question: $e');
      print(st);
      return null;
    }
  }

  // ========================================================================
  // GET MULTIPLE QUESTIONS (LIST)
  // ========================================================================
  Future<List<QuestionModel>> getQuestions({
    required String topicId,
    required int difficulty,
    int count = 1,
  }) async {
    try {
      final difficultyName = difficulty == 1
          ? 'easy'
          : difficulty == 2
          ? 'medium'
          : 'hard';

      final snapshot = await _db
          .collection('questions')
          .doc(topicId)
          .collection(difficultyName)
          .get();

      if (snapshot.docs.isEmpty) {
        print('⚠️ Tidak ada soal di Firestore untuk $topicId/$difficultyName');
        return [];
      }

      final allQuestions = snapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data.isEmpty) return null;
            return QuestionModel.fromMap(data, doc.id);
          })
          .whereType<QuestionModel>()
          .toList();

      if (allQuestions.isEmpty) {
        print('⚠️ Semua dokumen kosong.');
        return [];
      }

      allQuestions.shuffle();
      return allQuestions.take(count).toList();
    } catch (e, st) {
      print('❌ Error getting questions: $e');
      print(st);
      return [];
    }
  }

  // ========================================================================
  // QUIZ HISTORY (OPSIONAL)
  // ========================================================================
  Future<void> saveQuizHistory({
    required String topicId,
    required String topicName,
    required double score,
    required int totalQuestions,
    required int correctAnswers,
    required double avgTime,
    List<Map<String, dynamic>>? answers,
  }) async {
    try {
      await _db.collection('quiz_history').add({
        'topicId': topicId,
        'topicName': topicName,
        'score': score,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'avgTime': avgTime,
        'answers': answers ?? [],
        'date': FieldValue.serverTimestamp(),
      });

      print('✅ Quiz history saved');
    } catch (e, st) {
      print('❌ Error saving history: $e');
      print(st);
    }
  }

  Future<List<Map<String, dynamic>>> getQuizHistory({int limit = 10}) async {
    try {
      final snapshot = await _db
          .collection('quiz_history')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      if (snapshot.docs.isEmpty) {
        print('⚠️ Tidak ada riwayat kuis ditemukan');
        return [];
      }

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e, st) {
      print('❌ Error getting history: $e');
      print(st);
      return [];
    }
  }
}
