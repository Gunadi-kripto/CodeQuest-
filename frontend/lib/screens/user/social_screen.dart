// lib/user/social_screen.dart

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'chat_screen.dart';

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
  int _currentTab = 0; 

  @override
  void initState() {
    super.initState();
    _loadSocialData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
    if (_currentTab != 2) setState(() => _currentTab = 2); 
    final results = await ApiService.searchUsers(query, widget.currentUserId);
    setState(() => searchResults = results);
  }

  void _sendRequest(String targetId) async {
    final res = await ApiService.sendFriendRequest(widget.currentUserId, targetId);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
  }

  void _acceptRequest(String senderId) async {
    final res = await ApiService.acceptFriendRequest(widget.currentUserId, senderId);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
    _loadSocialData();
  }

  void _rejectRequest(String senderId) async {
    final res = await ApiService.rejectFriendRequest(widget.currentUserId, senderId);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
    _loadSocialData();
  }

  void _confirmRemoveFriend(String friendId, String friendName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Hapus Pertemanan?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus $friendName dari daftar temanmu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Batal', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final res = await ApiService.removeFriend(widget.currentUserId, friendId);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
              _loadSocialData();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              icon: const Icon(Icons.chat, color: Colors.white),
              label: const Text('Chat Sekarang', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen(
                    currentUserId: widget.currentUserId,
                    friendId: user['_id'],
                    friendName: user['nama_lengkap'] ?? 'Anonim',
                  )),
                );
              },
            ),
            const SizedBox(height: 10),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F6), 
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Teman & Jejaring', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)
        ),
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset('assets/coding_bg.png', fit: BoxFit.cover),
          ),
          Container(
            color: const Color(0xFFFAF9F6).withOpacity(0.92), 
          ),
          Column(
            children: [
              const SizedBox(height: 10),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildCustomToggle(),
              const SizedBox(height: 10),
              Expanded(
                child: isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : _buildTabContent(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 45,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
        child: TextField(
          controller: searchController,
          onChanged: _searchUsers, 
          decoration: const InputDecoration(
            hintText: 'Cari nama atau username...',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]
        ),
        child: Row(
          children: [
            _buildTabButton('Teman', 0),
            _buildTabButton('Permintaan', 1),
            _buildTabButton('Cari', 2),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_currentTab == 0) {
      return friends.isEmpty
        ? _buildEmptyState('Belum ada teman!', 'Tambahkan dari pencarian untuk mabar coding bareng!')
        : RefreshIndicator(
            onRefresh: _loadSocialData,
            color: Colors.green,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return _buildModernUserCard(
                  friend,
                  trailingAction: IconButton(
                    icon: const Icon(Icons.person_remove, color: Colors.red),
                    onPressed: () => _confirmRemoveFriend(friend['_id'], friend['nama_lengkap']),
                    tooltip: 'Hapus Teman',
                  ),
                );
              },
            ),
          );
    } else if (_currentTab == 1) {
      return requests.isEmpty
        ? _buildEmptyState('Tidak ada permintaan.', 'Belum ada yang mengirim permintaan pertemanan.')
        : RefreshIndicator(
            onRefresh: _loadSocialData,
            color: Colors.green,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final reqUser = requests[index];
                return _buildModernUserCard(
                  reqUser,
                  trailingAction: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _rejectRequest(reqUser['_id']),
                      ),
                      ElevatedButton(
                        onPressed: () => _acceptRequest(reqUser['_id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                        child: const Text('Terima', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
    } else {
      return searchResults.isEmpty
        ? _buildEmptyState('Cari Teman Baru', 'Ketik nama di kolom pencarian di atas.')
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final searchUser = searchResults[index];
              return _buildModernUserCard(
                searchUser,
                trailingAction: IconButton(
                  icon: const Icon(Icons.person_add_alt_1, color: Colors.green),
                  onPressed: () => _sendRequest(searchUser['_id']),
                  tooltip: 'Tambah Teman',
                )
              );
            },
          );
    }
  }

  Widget _buildModernUserCard(Map<String, dynamic> user, {Widget? trailingAction}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[200],
          backgroundImage: user['avatar_url'] != null && user['avatar_url'] != "" ? NetworkImage(user['avatar_url']) : null,
          child: user['avatar_url'] == null || user['avatar_url'] == "" ? const Icon(Icons.person, color: Colors.grey) : null,
        ),
        title: Text(user['nama_lengkap'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('Level ${user['level'] ?? 1} • ${user['total_xp'] ?? 0} XP', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        trailing: trailingAction,
        onTap: () => _showFriendProfile(user), 
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), 
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.smartphone, size: 80, color: Colors.grey[400]),
                Positioned(
                  bottom: 20, right: 15,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), 
                    child: const Icon(Icons.people, color: Colors.white, size: 20),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 25),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4)),
          ),
        ],
      ),
    );
  }
}