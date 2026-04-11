import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER PROFIL ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30, top: 20),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: Colors.green),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Gunadi Setiawan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Level 8 | Peringkat: Serigala Jackal',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- KOTAK STATISTIK ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem("XP", "2400"),
                  _buildStatItem("Kuis Selesai", "25"),
                  _buildStatItem("Rekor Harian", "17"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- BADGE SHOWCASE ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Badge Showcase',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBadge(Icons.code, Colors.blue, "Python"),
                  _buildBadge(Icons.bug_report, Colors.red, "Debugger"),
                  _buildBadge(Icons.military_tech, Colors.orange, "Veteran"),
                  _buildBadge(Icons.local_fire_department, Colors.redAccent, "Streak"),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- TOMBOL GANTI AVATAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    // Logika ke Cloudinary nantinya ditaruh di sini
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur ganti avatar via Cloudinary akan segera hadir!')),
                    );
                  },
                  child: const Text('Ganti Avatar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Fungsi pembantu untuk angka statistik
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  // Fungsi pembantu untuk desain Badge
  Widget _buildBadge(IconData icon, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}