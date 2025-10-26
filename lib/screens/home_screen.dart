import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> topicAttempts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    // Load topic attempts from saved performances
    final topics = await StorageService.getSavedTopics();

    for (var topic in topics) {
      final performance = await StorageService.loadPerformance(topic);
      topicAttempts[topic] = performance.totalAttempts;
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                SizedBox(height: 32),

                // Welcome Card
                _buildWelcomeCard(),
                SizedBox(height: 32),

                // Topics
                Text(
                  'Pilih Topik',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                _buildTopicsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎓 PANDAI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667EEA),
              ),
            ),
            Text(
              'Pembelajaran Adaptif dengan AI',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: Color(0xFF667EEA)),
          onPressed: () {
            setState(() => isLoading = true);
            _loadStats();
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Sistem akan menyesuaikan tingkat kesulitan soal berdasarkan performa Anda',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Adaptive Learning',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Icon(Icons.psychology, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                '',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsList() {
    final topics = [
      {
        'id': 'matematika',
        'name': 'Matematika',
        'icon': '📊',
        'description': 'Aljabar, Geometri, Kalkulus',
        'color': Color(0xFF4285F4),
      },
      {
        'id': 'fisika',
        'name': 'Fisika',
        'icon': '🔬',
        'description': 'Mekanika, Termodinamika, Optik',
        'color': Color(0xFF34A853),
      },
      {
        'id': 'pemrograman',
        'name': 'Pemrograman',
        'icon': '💻',
        'description': 'Python, JavaScript, Flutter',
        'color': Color(0xFFFBBC05),
      },
    ];

    return Column(
      children: topics.map((topic) {
        int attempts = topicAttempts[topic['id']] ?? 0;

        return _buildTopicCard(
          topicId: topic['id'] as String,
          name: topic['name'] as String,
          icon: topic['icon'] as String,
          description: topic['description'] as String,
          color: topic['color'] as Color,
          attempts: attempts,
        );
      }).toList(),
    );
  }

  Widget _buildTopicCard({
    required String topicId,
    required String name,
    required String icon,
    required String description,
    required Color color,
    required int attempts,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(topicId: topicId, topicName: name),
          ),
        ).then((_) => _loadStats()); // Refresh stats after quiz
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(icon, style: TextStyle(fontSize: 32))),
            ),
            SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (attempts > 0) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: color),
                        SizedBox(width: 4),
                        Text(
                          '$attempts kuis selesai',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Arrow
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
