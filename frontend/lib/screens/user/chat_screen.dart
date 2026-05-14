import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String friendId;
  final String friendName;

  const ChatScreen({super.key, required this.currentUserId, required this.friendId, required this.friendName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> messages = [];
  bool canChat = true;
  int dailyCount = 0;
  bool isSending = false;
  Timer? _timer;

  final Color bgColor = const Color(0xFFF4F3ED); // Krem muda

  @override
  void initState() {
    super.initState();
    _checkFirstTimeWarning();
    _loadMessages();
    // Auto-refresh tiap 2 detik (Polling)
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) => _loadMessages(isRefresh: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTimeWarning() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeen = prefs.getBool('has_seen_chat_warning') ?? false;

    if (!hasSeen) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
                SizedBox(width: 10),
                Text('Peringatan Chat!', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Untuk menjaga kondusivitas belajar, fitur chat ini dibatasi maksimal 15 pesan per hari.\n\nSelain itu, sistem hanya menyimpan 20 pesan terbaru. Pesan yang paling lama otomatis terhapus.',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  prefs.setBool('has_seen_chat_warning', true);
                  Navigator.pop(context);
                },
                child: const Text('Saya Mengerti', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        );
      }
    }
  }

  // --- MENU INFO
  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text('Info Fitur Chat', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Batas maksimal pengiriman pesan adalah 15 pesan per hari.\n\nSistem hanya menyimpan 20 pesan terbaru. Pesan lama akan otomatis terhapus.',
          style: TextStyle(fontSize: 15),
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

  Future<void> _loadMessages({bool isRefresh = false}) async {
    final data = await ApiService.getChats(widget.currentUserId, widget.friendId);
    if (mounted) {
      setState(() {
        messages = data['messages'] ?? [];
        canChat = data['canChat'] ?? true;
        dailyCount = data['dailyCount'] ?? 0;
      });
      // Scroll otomatis ke bawah
      if (!isRefresh && messages.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    }
  }

  void _sendMessage() async {
    if (_msgController.text.trim().isEmpty || !canChat) return;

    setState(() => isSending = true);
    String textToSend = _msgController.text;
    _msgController.clear();

    bool success = await ApiService.sendMessage(widget.currentUserId, widget.friendId, textToSend);
    
    if (success) {
      await _loadMessages();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    }
    setState(() => isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      
      // --- HEADER MODERN ---
      appBar: AppBar(
        backgroundColor: bgColor.withOpacity(0.95), 
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Text(
                widget.friendName.isNotEmpty ? widget.friendName[0].toUpperCase() : '?', 
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friendName, 
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)
                ),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6, 
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)
                    ),
                    const SizedBox(width: 4),
                    const Text('Online', style: TextStyle(color: Colors.green, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            onSelected: (String result) {
              if (result == 'info') {
                _showChatInfo();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green, size: 20),
                    SizedBox(width: 10),
                    Text('Info Chat'),
                  ],
                ),
              ),
            ],
          )
        ],
      ),

      // --- BODY CHAT DENGAN BACKGROUND ---
      body: Stack(
        children: [
          // 1. LAYER BACKGROUND GAMBAR
          SizedBox.expand(
            child: Image.asset(
              'assets/coding_bg.png', // Background sama seperti halaman Profile
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // 2. LAYER OVERLAY TRANSPARAN
          Container(
            color: bgColor.withOpacity(0.85), 
          ),

          // 3. KONTEN CHAT UTAMA
          Column(
            children: [
              // Banner Limit Harian
              Container(
                width: double.infinity,
                color: Colors.green[100]?.withOpacity(0.9), 
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Limit Hari Ini: $dailyCount/15 Chat Terkirim',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              
              // Daftar Chat
              Expanded(
                child: messages.isEmpty
                    ? Center(child: Text('Mulai sapa ${widget.friendName}!', style: TextStyle(color: Colors.grey[700])))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          bool isMe = msg['senderId'] == widget.currentUserId;
                          
                          // Cek status isRead dari database (default false jika belum ada)
                          bool isRead = msg['isRead'] == true;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Avatar Teman (Di Kiri)
                                if (!isMe) ...[
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.white, 
                                    child: Text(widget.friendName[0].toUpperCase(), style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                ],

                                // Gelembung Chat
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe ? Colors.green : Colors.white, 
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(20),
                                        topRight: const Radius.circular(20),
                                        bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(5),
                                        bottomRight: isMe ? const Radius.circular(5) : const Radius.circular(20),
                                      ),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))
                                      ]
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min, // Agar gelembung fit dengan teks
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            msg['text'], 
                                            style: TextStyle(fontSize: 15, color: isMe ? Colors.white : Colors.black87) 
                                          ),
                                        ),
                                        // --- ICON CENTANG WHATSAPP (Hanya untuk pesan yang kita kirim) ---
                                        if (isMe) ...[
                                          const SizedBox(width: 8), // Jarak antara teks dan centang
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 2), // Biar sejajar dengan bawah teks
                                            child: Icon(
                                              isRead ? Icons.done_all : Icons.done, 
                                              color: isRead ? Colors.lightBlueAccent : Colors.white70, 
                                              size: 16
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ),

                                // Avatar Saya (Di Kanan)
                                if (isMe) ...[
                                  const SizedBox(width: 8),
                                  const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.black87,
                                    child: Icon(Icons.person, size: 16, color: Colors.white),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
              
              // --- BOTTOM INPUT BAR MODERN ---
              Container(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
                color: Colors.transparent, // Transparan agar gambar belakang terlihat
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))
                          ]
                        ),
                        child: TextField(
                          controller: _msgController,
                          enabled: canChat,
                          minLines: 1,
                          maxLines: 4, 
                          decoration: InputDecoration(
                            hintText: canChat ? 'Enter your message' : 'Limit harian habis',
                            hintStyle: TextStyle(color: canChat ? Colors.grey[400] : Colors.red, fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(left: 20, top: 14, bottom: 14, right: 10),
                            
                            // Tombol Send Menyatu di Kanan
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: canChat ? Colors.green : Colors.grey[300], 
                                child: IconButton(
                                  icon: isSending 
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20), 
                                  onPressed: canChat ? _sendMessage : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}