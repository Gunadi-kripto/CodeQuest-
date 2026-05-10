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
    final TextEditingController tanyaController = TextEditingController(text: isEdit ? quiz['pertanyaan'] : '');
    final TextEditingController hintController = TextEditingController(text: isEdit ? quiz['hint'] : '');
    final TextEditingController xpController = TextEditingController(text: isEdit ? quiz['xp_reward'].toString() : '10');
    
    final List<TextEditingController> opsiControllers = List.generate(4, (index) {
      return TextEditingController(text: isEdit ? quiz['opsi'][index] : '');
    });

    int correctIndex = isEdit ? (quiz['jawaban_benar'] as num).toInt() : 0;
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
                children: [
                  Text(isEdit ? 'Edit Kuis Pilihan Ganda' : 'Kuis Baru', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 20),
                  TextField(controller: tanyaController, decoration: const InputDecoration(labelText: 'Pertanyaan', border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  ...List.generate(4, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: correctIndex,
                          onChanged: (val) => setSheetState(() => correctIndex = val!),
                        ),
                        Expanded(child: TextField(controller: opsiControllers[index], decoration: InputDecoration(labelText: 'Opsi ${String.fromCharCode(65 + index)}'))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 10),
                  TextField(controller: hintController, decoration: const InputDecoration(labelText: 'Hint', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: xpController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'XP Reward', border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(16)),
                      onPressed: isSaving ? null : () async {
                        if (tanyaController.text.isEmpty || opsiControllers.any((e) => e.text.isEmpty)) return;
                        setSheetState(() => isSaving = true);
                        List<String> opsiList = opsiControllers.map((e) => e.text).toList();
                        
                        bool success = isEdit 
                          ? await ApiService.updateQuiz(quiz['_id'], tanyaController.text, opsiList, correctIndex, hintController.text, int.parse(xpController.text))
                          : await ApiService.addQuiz(selectedModuleId!, tanyaController.text, opsiList, correctIndex, hintController.text, int.parse(xpController.text));
                        
                        if (success) { Navigator.pop(context); _loadQuizzes(); }
                        else { setSheetState(() => isSaving = false); }
                      },
                      child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan', style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                final quiz = quizzes[index];
                int correctIdx = (quiz['jawaban_benar'] as num).toInt();
                return Card(
                  child: ListTile(
                    title: Text(quiz['pertanyaan']),
                    subtitle: Text("Benar: Opsi ${String.fromCharCode(65 + correctIdx)}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showQuizForm(quiz: quiz)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                          if (await ApiService.deleteQuiz(quiz['_id'])) _loadQuizzes();
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