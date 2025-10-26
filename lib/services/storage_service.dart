import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_performance.dart';

class StorageService {
  static const String KEY_PREFIX = 'performance_';

  /// Save performance untuk topic
  static Future<void> savePerformance(
    String topicId,
    UserPerformance performance,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$KEY_PREFIX$topicId';
      await prefs.setString(key, performance.toJson());
      print('💾 Performance saved: $topicId');
    } catch (e) {
      print('❌ Error saving performance: $e');
    }
  }

  /// Load performance untuk topic
  static Future<UserPerformance> loadPerformance(String topicId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$KEY_PREFIX$topicId';
      final jsonString = prefs.getString(key);

      if (jsonString != null) {
        print('📂 Performance loaded: $topicId');
        return UserPerformance.fromJson(jsonString);
      }
    } catch (e) {
      print('❌ Error loading performance: $e');
    }

    print('🆕 Creating new performance for: $topicId');
    return UserPerformance();
  }

  /// Clear performance untuk topic
  static Future<void> clearPerformance(String topicId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$KEY_PREFIX$topicId';
      await prefs.remove(key);
      print('🗑️ Performance cleared: $topicId');
    } catch (e) {
      print('❌ Error clearing performance: $e');
    }
  }

  /// Get all saved topics
  static Future<List<String>> getSavedTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      return keys
          .where((key) => key.startsWith(KEY_PREFIX))
          .map((key) => key.replaceFirst(KEY_PREFIX, ''))
          .toList();
    } catch (e) {
      print('❌ Error getting saved topics: $e');
      return [];
    }
  }

  /// Clear all data
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('🗑️ All data cleared');
    } catch (e) {
      print('❌ Error clearing data: $e');
    }
  }
}
