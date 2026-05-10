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
              'Untuk menjaga kondusivitas belajar, fitur chat ini dibatasi maksimal 15 pesan per hari.\n\nSelain itu, sistem hanya menyimpan 20 pesan terbaru. Pesan yang paling lama akan otomatis terhapus dan diganti dengan pesan baru.',
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

  Future<void> _loadMessages({bool isRefresh = false}) async {
    final data = await ApiService.getChats(widget.currentUserId, widget.friendId);
    if (mounted) {
      setState(() {
        messages = data['messages'] ?? [];
        canChat = data['canChat'] ?? true;
        dailyCount = data['dailyCount'] ?? 0;
      });
      // Scroll otomatis ke bawah pas pertama kali load atau kalau kita habis ngirim
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
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(widget.friendName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Banner Info
          Container(
            width: double.infinity,
            color: Colors.orange[100],
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Limit Hari Ini: $dailyCount/15 Chat Terkirim',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Daftar Chat
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('Belum ada pesan. Mulai obrolan!', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      bool isMe = msg['senderId'] == widget.currentUserId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.green[100] : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(15),
                              topRight: const Radius.circular(15),
                              bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(0),
                              bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(15),
                            ),
                          ),
                          child: Text(msg['text'], style: const TextStyle(fontSize: 16)),
                        ),
                      );
                    },
                  ),
          ),
          
          // Area Ngetik
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    enabled: canChat, // KUNCI KALAU LIMIT HABIS
                    decoration: InputDecoration(
                      hintText: canChat 
                        ? 'Ketik pesan...' 
                        : 'Limit harian chat telah Habis silakan tunggu besok hari',
                      hintStyle: TextStyle(color: canChat ? Colors.grey : Colors.red, fontSize: 13),
                      filled: true,
                      fillColor: canChat ? Colors.grey[100] : Colors.red[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: canChat ? Colors.green : Colors.grey,
                  child: IconButton(
                    icon: isSending 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.white),
                    onPressed: canChat ? _sendMessage : null,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}