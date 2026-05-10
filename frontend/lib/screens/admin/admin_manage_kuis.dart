import 'package:flutter/material.dart';
import '../../services/api_service.dart';

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

  Future<void> _loadModules() async {
    setState(() => isLoading = true);
    final data = await ApiService.getModules();
    setState(() {
      modules = data;
      if (modules.isNotEmpty) {
        selectedModuleId = modules[0]['_id'];
        _loadQuizzes();
      } else {
        isLoading = false;
      }
    });
  }

  Future<void> _loadQuizzes() async {
    if (selectedModuleId == null) return;
    setState(() => isLoading = true);
    final data = await ApiService.getQuizzes(selectedModuleId!);
    setState(() {
      quizzes = data;
      isLoading = false;
    });
  }

  void _showQuizForm({Map<String, dynamic>? quiz}) {
    final bool isEdit = quiz != null;
    
    // List untuk menampung banyak soal (Multiple Questions)
    List<Map<String, dynamic>> tempDaftarSoal = [];
    final TextEditingController xpController = TextEditingController(text: isEdit ? quiz['xp_reward'].toString() : '20');

    if (isEdit) {
      for (var s in quiz['daftar_soal']) {
        tempDaftarSoal.add({
          'pertanyaan': TextEditingController(text: s['pertanyaan']),
          'opsi': List.generate(4, (i) => TextEditingController(text: s['opsi'][i])),
          'jawaban_benar': (s['jawaban_benar'] as num).toInt(),
          'hint': TextEditingController(text: s['hint'] ?? ''),
        });
      }
    } else {
      // Tambahkan satu soal kosong sebagai awal
      _tambahSoalBaru(tempDaftarSoal);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              children: [
                Text(isEdit ? 'Edit Set Kuis' : 'Buat Set Kuis Baru', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 15),
                TextField(controller: xpController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total XP Reward', border: OutlineInputBorder())),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: tempDaftarSoal.length,
                    itemBuilder: (context, i) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        color: Colors.grey[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Soal #${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setSheetState(() => tempDaftarSoal.removeAt(i))),
                                ],
                              ),
                              TextField(controller: tempDaftarSoal[i]['pertanyaan'], decoration: const InputDecoration(labelText: 'Pertanyaan')),
                              const SizedBox(height: 10),
                              ...List.generate(4, (j) => Row(
                                children: [
                                  Radio<int>(
                                    value: j,
                                    groupValue: tempDaftarSoal[i]['jawaban_benar'],
                                    onChanged: (val) => setSheetState(() => tempDaftarSoal[i]['jawaban_benar'] = val!),
                                  ),
                                  Expanded(child: TextField(controller: tempDaftarSoal[i]['opsi'][j], decoration: InputDecoration(labelText: 'Opsi ${String.fromCharCode(65 + j)}'))),
                                ],
                              )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(onPressed: () => setSheetState(() => _tambahSoalBaru(tempDaftarSoal)), icon: const Icon(Icons.add), label: const Text("Tambah Soal")),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () async {
                        List<Map<String, dynamic>> finalSoal = tempDaftarSoal.map((s) => {
                          'pertanyaan': s['pertanyaan'].text,
                          'opsi': (s['opsi'] as List<TextEditingController>).map((c) => c.text).toList(),
                          'jawaban_benar': s['jawaban_benar'],
                          'hint': s['hint'].text,
                        }).toList();

                        bool success = isEdit 
                          ? await ApiService.updateQuiz(quiz['_id'], finalSoal, int.parse(xpController.text))
                          : await ApiService.addQuiz(selectedModuleId!, finalSoal, int.parse(xpController.text));
                        
                        if (success) { Navigator.pop(context); _loadQuizzes(); }
                      },
                      child: const Text("Simpan Set Kuis", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        }
      ),
    );
  }

  void _tambahSoalBaru(List<Map<String, dynamic>> list) {
    list.add({
      'pertanyaan': TextEditingController(),
      'opsi': List.generate(4, (i) => TextEditingController()),
      'jawaban_benar': 0,
      'hint': TextEditingController(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Kuis Multi-Soal"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      floatingActionButton: selectedModuleId == null ? null : FloatingActionButton(
        onPressed: () => _showQuizForm(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<String>(
              value: selectedModuleId,
              isExpanded: true,
              items: modules.map((m) => DropdownMenuItem<String>(value: m['_id'], child: Text(m['judul_modul']))).toList(),
              onChanged: (val) { setState(() => selectedModuleId = val); _loadQuizzes(); },
            ),
          ),
          Expanded(
            child: isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final q = quizzes[index];
                return Card(
                  child: ListTile(
                    title: Text("Set Kuis Bab: ${modules.firstWhere((m) => m['_id'] == q['module_id'])['judul_modul']}"),
                    subtitle: Text("Total: ${q['daftar_soal'].length} Soal | Reward: ${q['xp_reward']} XP"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showQuizForm(quiz: q)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                          if (await ApiService.deleteQuiz(q['_id'])) _loadQuizzes();
                        }),
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