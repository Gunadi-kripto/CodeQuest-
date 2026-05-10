import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  final List<dynamic> leaderboard;

  const LeaderboardScreen({
    super.key,
    required this.leaderboard,
  });

  Color _getRankColor(int index) {
    if (index == 0) return Colors.amber;
    if (index == 1) return Colors.grey;
    if (index == 2) return const Color(0xFFCD7F32);

    return Colors.green.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,

        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: leaderboard.isEmpty
          ? const Center(
              child: Text(
                'Belum ada data leaderboard',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),

              itemCount: leaderboard.length,

              itemBuilder: (context, index) {
                final user = leaderboard[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(20),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                      ),
                    ],
                  ),

                  child: Row(
                    children: [

                      CircleAvatar(
                        backgroundColor: _getRankColor(index),

                        child: Text(
                          '${index + 1}',

                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            Text(
                              user['nama_lengkap'] ?? 'Anonim',

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              'Level ${user['level'] ?? 1} • ${user['total_xp'] ?? 0} XP',

                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      user['avatar_url'] != null &&
                              user['avatar_url'] != ""
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(
                                user['avatar_url'],
                              ),
                              radius: 18,
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.grey,
                            ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}