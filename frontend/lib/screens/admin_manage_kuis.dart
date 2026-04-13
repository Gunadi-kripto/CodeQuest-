import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminManageKuis extends StatefulWidget {
  const AdminManageKuis({super.key});

  @override
  _AdminManageKuisState createState() => _AdminManageKuisState();
}

class _AdminManageKuisState extends State<AdminManageKuis> {
  List<dynamic> modules = [];
  List<dynamic> quizzes = [];
  String? selectedModuleId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  // 1. Load Daftar Materi untuk Dropdown
  Future<void> _loadModules() async {
    setState(() => isLoading = true);
    final data = await ApiService.getModules();
    setState(() {
      modules = data;
      if (modules.isNotEmpty) {
        selectedModuleId = modules[0]['_id']; // Pilih modul pertama sebagai default
        _loadQuizzes(); // Langsung load kuisnya
      } else {
        isLoading = false;
      }
    });
  }

  // 2. Load Kuis berdasarkan Materi yang dipilih
  Future<void> _loadQuizzes() async {
    if (selectedModuleId == null) return;
    setState(() => isLoading = true);
    final data = await ApiService.getQuizzes(selectedModuleId!);
    setState(() {
      quizzes = data;
      isLoading = false;
    });
  }

  // FUNGSI FORM PINTAR (TAMBAH / EDIT KUIS)
  void _showQuizForm({Map<String, dynamic>? quiz}) {
    final bool isEdit = quiz != null;
    final TextEditingController tanyaController = TextEditingController(text: isEdit ? quiz['pertanyaan'] : '');
    final TextEditingController kunciController = TextEditingController(text: isEdit ? quiz['kunci_jawaban'] : '');
    final TextEditingController hintController = TextEditingController(text: isEdit ? quiz['hint'] : '');
    final TextEditingController xpController = TextEditingController(text: isEdit ? quiz['xp_reward'].toString() : '10');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEdit ? 'Edit Kuis' : 'Tambah Kuis Baru', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 20),
                  
                  TextField(controller: tanyaController, maxLines: 2, decoration: const InputDecoration(labelText: 'Pertanyaan', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  
                  TextField(controller: kunciController, decoration: const InputDecoration(labelText: 'Kunci Jawaban (Harus Persis)', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  
                  TextField(controller: hintController, decoration: const InputDecoration(labelText: 'Hint / Petunjuk (Opsional)', border: OutlineInputBorder())),
                  const SizedBox(height: 16),

                  TextField(controller: xpController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hadiah XP', border: OutlineInputBorder(), prefixIcon: Icon(Icons.star, color: Colors.orange))),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: isSaving ? null : () async {
                        if (tanyaController.text.isEmpty || kunciController.text.isEmpty) return;

                        setSheetState(() => isSaving = true);
                        int xpValue = int.tryParse(xpController.text) ?? 10;
                        
                        bool success;
                        if (isEdit) {
                          success = await ApiService.updateQuiz(quiz['_id'], tanyaController.text, kunciController.text, hintController.text, xpValue);
                        } else {
                          success = await ApiService.addQuiz(selectedModuleId!, tanyaController.text, kunciController.text, hintController.text, xpValue);
                        }
                        
                        if (success) {
                          Navigator.pop(context); 
                          _loadQuizzes(); 
                        }
                      },
                      child: isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Kuis', style: const TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  // FUNGSI HAPUS KUIS
  void _deleteQuiz(String id) async {
    bool success = await ApiService.deleteQuiz(id);
    if (success) _loadQuizzes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: selectedModuleId == null ? null : FloatingActionButton.extended(
        onPressed: () => _showQuizForm(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Kuis', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // DROPDOWN PILIH MATERI
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            width: double.infinity,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedModuleId,
                isExpanded: true,
                hint: const Text('Pilih Materi / Bab'),
                items: modules.map<DropdownMenuItem<String>>((mod) {
                  return DropdownMenuItem<String>(
                    value: mod['_id'],
                    child: Text(mod['judul_modul'] ?? 'Tanpa Judul', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedModuleId = newValue;
                    _loadQuizzes();
                  });
                },
              ),
            ),
          ),
          const Divider(height: 1, thickness: 2),
          
          // DAFTAR KUIS
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : quizzes.isEmpty
                    ? const Center(child: Text('Belum ada kuis untuk materi ini.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: quizzes.length,
                        itemBuilder: (context, index) {
                          final quiz = quizzes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: Colors.orange[100], child: Text('${quiz['xp_reward']}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                              title: Text(quiz['pertanyaan'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Jawaban: ${quiz['kunci_jawaban']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showQuizForm(quiz: quiz)),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteQuiz(quiz['_id'])),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}