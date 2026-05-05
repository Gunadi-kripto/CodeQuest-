import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SocialScreen extends StatefulWidget {
  final String currentUserId;

  const SocialScreen({super.key, required this.currentUserId});

  @override
  _SocialScreenState createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  List<dynamic> friends = [];
  List<dynamic> requests = [];
  List<dynamic> searchResults = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSocialData();
  }

  Future<void> _loadSocialData() async {
    setState(() => isLoading = true);
    final data = await ApiService.getSocialData(widget.currentUserId);
    if (data != null) {
      setState(() {
        friends = data['friends'] ?? [];
        requests = data['friendRequests'] ?? [];
      });
    }
    setState(() => isLoading = false);
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }
    final results = await ApiService.searchUsers(query, widget.currentUserId);
    setState(() => searchResults = results);
  }

  void _sendRequest(String targetId) async {
    final res = await ApiService.sendFriendRequest(widget.currentUserId, targetId);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
  }

  void _acceptRequest(String senderId) async {
    final res = await ApiService.acceptFriendRequest(widget.currentUserId, senderId);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
    _loadSocialData(); // Refresh list setelah menerima
  }

  // === FUNGSI MENAMPILKAN POPUP DETAIL TEMAN (TARGET 2) ===
  void _showFriendProfile(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green[100],
              backgroundImage: user['avatar_url'] != null && user['avatar_url'] != "" ? NetworkImage(user['avatar_url']) : null,
              child: user['avatar_url'] == null || user['avatar_url'] == "" ? const Icon(Icons.person, size: 50, color: Colors.green) : null,
            ),
            const SizedBox(height: 16),
            Text(user['nama_lengkap'] ?? 'Anonim', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(user['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.orange, size: 30),
                    const SizedBox(height: 4),
                    Text('Level ${user['level'] ?? 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.bolt_rounded, color: Colors.blue, size: 30),
                    const SizedBox(height: 4),
                    Text('${user['total_xp'] ?? 0} XP', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            
            const Text('Bio Singkat', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 8),
            Text(
              user['bio'] == null || user['bio'].toString().trim().isEmpty ? 'User ini belum menuliskan bio.' : user['bio'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }

  // Desain Kartu User Standar (Diupdate dengan fitur klik)
  Widget _buildUserCard(Map<String, dynamic> user, {Widget? trailingAction}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          backgroundImage: user['avatar_url'] != null && user['avatar_url'] != "" ? NetworkImage(user['avatar_url']) : null,
          child: user['avatar_url'] == null || user['avatar_url'] == "" ? const Icon(Icons.person, color: Colors.green) : null,
        ),
        title: Text(user['nama_lengkap'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Level ${user['level'] ?? 1} • ${user['total_xp'] ?? 0} XP'),
        trailing: trailingAction,
        onTap: () => _showFriendProfile(user), // Memicu popup saat kartu diklik
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Teman & Jejaring', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Teman'),
              Tab(icon: Icon(Icons.person_add), text: 'Permintaan'),
              Tab(icon: Icon(Icons.search), text: 'Cari'),
            ],
          ),
        ),
        body: isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : TabBarView(
                children: [
                  // TAB 1: DAFTAR TEMAN
                  friends.isEmpty
                    ? const Center(child: Text('Belum ada teman. Yuk cari!'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: friends.length,
                        itemBuilder: (context, index) => _buildUserCard(friends[index]),
                      ),
                  
                  // TAB 2: PERMINTAAN MASUK
                  requests.isEmpty
                    ? const Center(child: Text('Tidak ada permintaan pertemanan.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final reqUser = requests[index];
                          return _buildUserCard(
                            reqUser,
                            trailingAction: ElevatedButton(
                              onPressed: () => _acceptRequest(reqUser['_id']),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Terima', style: TextStyle(color: Colors.white)),
                            )
                          );
                        },
                      ),

                  // TAB 3: CARI TEMAN
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: searchController,
                          onChanged: _searchUsers,
                          decoration: InputDecoration(
                            hintText: 'Cari nama teman...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: searchResults.isEmpty
                            ? const Center(child: Text('Ketik nama untuk mencari...', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  final searchUser = searchResults[index];
                                  return _buildUserCard(
                                    searchUser,
                                    trailingAction: IconButton(
                                      icon: const Icon(Icons.person_add_alt_1, color: Colors.green),
                                      onPressed: () => _sendRequest(searchUser['_id']),
                                    )
                                  );
                                },
                              ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}