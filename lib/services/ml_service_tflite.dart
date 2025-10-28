// ============================================================================
// ROBUST ML SERVICE - Dengan Multiple Fallback Strategies
// lib/services/ml_service_tflite.dart
// ============================================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class MLServiceTFLite {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  bool _useRuleBasedFallback = false;

  // Scaler parameters (dari scaler_params.json)
  List<double>? _scalerMean;
  List<double>? _scalerScale;

  /// Load TFLite model dan scaler parameters
  Future<void> loadModel() async {
    try {
      print('🔥 Memuat model TFLite...');

      // Cek apakah file model ada
      try {
        await rootBundle.load('assets/pandai_model_compatible.tflite');
        print('✅ Model file ditemukan');
      } catch (e) {
        print('❌ Model file tidak ditemukan: $e');
        _useRuleBasedFallback = true;
        print('⚠️ Will use rule-based fallback');
        return;
      }

      // Load scaler parameters dulu
      try {
        final String scalerJson = await rootBundle.loadString(
          'assets/scaler_paramss.json',
        );
        final Map<String, dynamic> scalerData = json.decode(scalerJson);

        _scalerMean = List<double>.from(scalerData['mean']);
        _scalerScale = List<double>.from(scalerData['scale']);

        print('✅ Scaler parameters loaded');
        print('   Mean: $_scalerMean');
        print('   Scale: $_scalerScale');
      } catch (e) {
        print('⚠️ Scaler parameters tidak ditemukan, using defaults: $e');
        // Default scaler untuk normalisasi dasar
        _scalerMean = [50.0, 10.0, 2.0, 50.0, 2.0];
        _scalerScale = [30.0, 5.0, 3.0, 30.0, 1.0];
      }

      // Coba load model dengan berbagai konfigurasi
      bool modelLoaded = false;

      // Try 1: Default options
      if (!modelLoaded) {
        try {
          print('🔄 Trying to load model with default options...');
          _interpreter = await Interpreter.fromAsset(
            'assets/pandai_model_compatible.tflite',
          );
          modelLoaded = true;
          print('✅ Model loaded with default options');
        } catch (e) {
          print('⚠️ Default load failed: $e');
        }
      }

      // Try 2: With custom options
      if (!modelLoaded) {
        try {
          print('🔄 Trying to load model with custom options...');
          final options = InterpreterOptions()
            ..threads = 2
            ..useNnApiForAndroid = false;
          
          _interpreter = await Interpreter.fromAsset(
            'assets/pandai_model_compatible.tflite',
            options: options,
          );
          modelLoaded = true;
          print('✅ Model loaded with custom options');
        } catch (e) {
          print('⚠️ Custom options load failed: $e');
        }
      }

      // Try 3: Single thread, no GPU
      if (!modelLoaded) {
        try {
          print('🔄 Trying to load model with minimal options...');
          final options = InterpreterOptions()
            ..threads = 1;
          
          _interpreter = await Interpreter.fromAsset(
            'assets/pandai_model_compatible.tflite',
            options: options,
          );
          modelLoaded = true;
          print('✅ Model loaded with minimal options');
        } catch (e) {
          print('⚠️ Minimal options load failed: $e');
        }
      }

      if (modelLoaded && _interpreter != null) {
        _isModelLoaded = true;
        print('✅ Model TFLite berhasil dimuat!');
        print('   Input shape: ${_interpreter!.getInputTensor(0).shape}');
        print('   Output shape: ${_interpreter!.getOutputTensor(0).shape}');
        print('   Input type: ${_interpreter!.getInputTensor(0).type}');
        print('   Output type: ${_interpreter!.getOutputTensor(0).type}');
      } else {
        throw Exception('All model loading attempts failed');
      }

    } catch (e) {
      print('❌ Gagal memuat model TFLite: $e');
      _isModelLoaded = false;
      _useRuleBasedFallback = true;
      print('⚠️ Will use rule-based fallback');
      // Jangan rethrow - biarkan app tetap jalan dengan fallback
    }
  }

  /// Prediksi kesulitan berikutnya menggunakan TFLite atau Fallback
  Future<Map<String, dynamic>> predictDifficulty({
    required double previousScore,
    required double avgTime,
    required int correctStreak,
    required int totalAttempts,
    required int lastDifficulty,
  }) async {
    // Jika model tidak loaded atau error, gunakan fallback
    if (_useRuleBasedFallback || !_isModelLoaded || _interpreter == null) {
      print('🎯 Using rule-based prediction (fallback)');
      return _fallbackPrediction(
        previousScore: previousScore,
        avgTime: avgTime,
        correctStreak: correctStreak,
        totalAttempts: totalAttempts,
        lastDifficulty: lastDifficulty,
      );
    }

    try {
      // Siapkan fitur input
      List<double> features = [
        previousScore,
        avgTime,
        correctStreak.toDouble(),
        totalAttempts.toDouble(),
        lastDifficulty.toDouble(),
      ];

      print('🔍 Raw features: $features');

      // Normalisasi fitur menggunakan parameter scaler
      List<double> normalizedFeatures = [];
      for (int i = 0; i < features.length; i++) {
        if (_scalerScale![i] == 0.0 || _scalerScale![i].isNaN) {
          normalizedFeatures.add(features[i]);
        } else {
          double normalized = (features[i] - _scalerMean![i]) / _scalerScale![i];
          // Clamp untuk menghindari nilai ekstrem
          normalized = normalized.clamp(-10.0, 10.0);
          normalizedFeatures.add(normalized);
        }
      }

      print('🔍 Normalized features: $normalizedFeatures');

      // Siapkan input dan output
      var inputShape = _interpreter!.getInputTensor(0).shape;
      var outputShape = _interpreter!.getOutputTensor(0).shape;

      // Input [1, 5]
      List<List<double>> input = [normalizedFeatures];
      
      // Output [1, 3]
      List<List<double>> output = List.generate(1, (_) => List.filled(3, 0.0));

      print('🔍 Running inference...');
      _interpreter!.run(input, output);

      List<double> probabilities = output[0];
      print('🔍 Raw probabilities: $probabilities');

      // Cek jika semua output 0 atau invalid
      double sum = probabilities.reduce((a, b) => a + b);
      
      if (sum < 0.001 || sum.isNaN || sum.isInfinite) {
        print('⚠️ Invalid model output, using fallback');
        _useRuleBasedFallback = true; // Switch to fallback permanently
        return _fallbackPrediction(
          previousScore: previousScore,
          avgTime: avgTime,
          correctStreak: correctStreak,
          totalAttempts: totalAttempts,
          lastDifficulty: lastDifficulty,
        );
      }

      // Normalize probabilities
      probabilities = probabilities.map((p) => p / sum).toList();

      // Tentukan kelas yang diprediksi
      double maxProb = probabilities.reduce((a, b) => a > b ? a : b);
      int predictedClass = probabilities.indexOf(maxProb);
      int difficulty = predictedClass + 1;

      String difficultyName = ['Easy', 'Medium', 'Hard'][predictedClass];

      print('✅ Prediksi TFLite: $difficultyName (Level $difficulty)');
      print('📊 Confidence: Easy=${(probabilities[0]*100).toStringAsFixed(1)}%, '
            'Medium=${(probabilities[1]*100).toStringAsFixed(1)}%, '
            'Hard=${(probabilities[2]*100).toStringAsFixed(1)}%');

      return {
        'difficulty': difficulty,
        'difficulty_name': difficultyName,
        'confidence': {
          'easy': probabilities[0],
          'medium': probabilities[1],
          'hard': probabilities[2],
        },
        'method': 'tflite',
      };
    } catch (e, stackTrace) {
      print('❌ TFLite prediction error: $e');
      print('Stack trace: $stackTrace');
      
      // Switch to fallback mode permanently
      _useRuleBasedFallback = true;
      
      return _fallbackPrediction(
        previousScore: previousScore,
        avgTime: avgTime,
        correctStreak: correctStreak,
        totalAttempts: totalAttempts,
        lastDifficulty: lastDifficulty,
      );
    }
  }

  /// Advanced rule-based prediction dengan adaptive logic
  Map<String, dynamic> _fallbackPrediction({
    required double previousScore,
    required double avgTime,
    required int correctStreak,
    required int totalAttempts,
    required int lastDifficulty,
  }) {
    int difficulty;
    String difficultyName;
    Map<String, double> confidence;

    // Advanced scoring system
    double performanceScore = 0.0;

    // Score component (40% weight)
    if (previousScore >= 80) {
      performanceScore += 4.0;
    } else if (previousScore >= 60) {
      performanceScore += 2.0;
    } else {
      performanceScore += 0.0;
    }

    // Time component (20% weight) - faster is better
    if (avgTime < 8) {
      performanceScore += 2.0;
    } else if (avgTime < 12) {
      performanceScore += 1.0;
    }

    // Streak component (30% weight)
    if (correctStreak >= 5) {
      performanceScore += 3.0;
    } else if (correctStreak >= 3) {
      performanceScore += 1.5;
    } else if (correctStreak <= -3) {
      performanceScore -= 2.0;
    }

    // Experience component (10% weight)
    if (totalAttempts > 100) {
      performanceScore += 1.0;
    } else if (totalAttempts > 50) {
      performanceScore += 0.5;
    }

    print('🎯 Performance Score: $performanceScore / 10.0');

    // Determine difficulty with smooth transitions
    if (performanceScore >= 7.0) {
      difficulty = 3; // Hard
      difficultyName = 'Hard';
      confidence = {'easy': 0.1, 'medium': 0.2, 'hard': 0.7};
    } else if (performanceScore >= 4.5) {
      difficulty = 2; // Medium
      difficultyName = 'Medium';
      confidence = {'easy': 0.2, 'medium': 0.6, 'hard': 0.2};
    } else {
      difficulty = 1; // Easy
      difficultyName = 'Easy';
      confidence = {'easy': 0.7, 'medium': 0.2, 'hard': 0.1};
    }

    // Prevent difficulty jumps (max +/-1 level)
    int maxDiff = lastDifficulty + 1;
    int minDiff = lastDifficulty - 1;
    difficulty = difficulty.clamp(minDiff.clamp(1, 3), maxDiff.clamp(1, 3));
    
    // Update difficulty name after clamping
    difficultyName = ['Easy', 'Medium', 'Hard'][difficulty - 1];

    print('🎯 Rule-based prediction: $difficultyName (Level $difficulty)');
    print('📊 Score: $previousScore, Time: ${avgTime}s, Streak: $correctStreak');

    return {
      'difficulty': difficulty,
      'difficulty_name': difficultyName,
      'confidence': confidence,
      'method': 'rule_based',
      'performance_score': performanceScore,
    };
  }

  /// Check if model is loaded
  bool get isModelLoaded => _isModelLoaded;

  /// Check if using fallback
  bool get isUsingFallback => _useRuleBasedFallback;

  /// Dispose interpreter
  void dispose() {
    _interpreter?.close();
    _isModelLoaded = false;
    print('🗑️ Interpreter TFLite dibersihkan');
  }
}