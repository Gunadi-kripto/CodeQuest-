import 'package:flutter/material.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  final List<Map<String, dynamic>> achievements = const [
    {'title': 'First Step', 'desc': 'Selesaikan materi pertama', 'icon': Icons.rocket_launch, 'unlocked': true},
    {'title': 'Quiz Master', 'desc': 'Dapatkan nilai 100 di kuis', 'icon': Icons.star, 'unlocked': true},
    {'title': 'Socializer', 'desc': 'Tambah 5 teman baru', 'icon': Icons.people, 'unlocked': false},
    {'title': 'Hardcore Coder', 'desc': 'Capai Level 10', 'icon': Icons.terminal, 'unlocked': false},
    {'title': 'Fast Learner', 'desc': 'Selesaikan 3 materi dalam 1 hari', 'icon': Icons.timer, 'unlocked': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements', style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
        ),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final item = achievements[index];
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  content: Text(item['desc']),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: const Text('Tutup', style: TextStyle(color: Colors.green))
                    )
                  ],
                ),
              );
            },
            child: Opacity(
              opacity: item['unlocked'] ? 1.0 : 0.3, // Gelap jika belum didapat
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'], size: 50, color: item['unlocked'] ? Colors.orange : Colors.grey),
                    const SizedBox(height: 10),
                    Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (!item['unlocked']) 
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('Terkunci', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}