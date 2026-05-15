import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/api_service.dart';

class AdminManageKuis extends StatefulWidget {
  const AdminManageKuis({super.key});

  @override
  State<AdminManageKuis> createState() => _AdminManageKuisState();
}

class _AdminManageKuisState extends State<AdminManageKuis> {
  List<dynamic> languages = [];
  List<dynamic> modules = [];
  List<dynamic> quizzes = [];

  dynamic selectedLanguage;
  dynamic selectedModule;

  bool isLoadingLanguages = true;
  bool isLoadingModules = false;
  bool isLoadingQuizzes = false;

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    setState(() => isLoadingLanguages = true);

    final data = await ApiService.getLanguages();

    if (!mounted) return;

    setState(() {
      languages = data;
      isLoadingLanguages = false;
    });

    if (languages.isNotEmpty) {
      await _selectLanguage(languages.first);
    }
  }

  Future<void> _selectLanguage(dynamic language) async {
    setState(() {
      selectedLanguage = language;
      selectedModule = null;
      modules = [];
      quizzes = [];
      isLoadingModules = true;
    });

    final data = await ApiService.getModulesByLanguage(language['_id']);

    if (!mounted) return;

    setState(() {
      modules = data;
      isLoadingModules = false;
    });

    if (modules.isNotEmpty) {
      await _selectModule(modules.first);
    }
  }

  Future<void> _selectModule(dynamic module) async {
    setState(() {
      selectedModule = module;
      quizzes = [];
      isLoadingQuizzes = true;
    });

    final data = await ApiService.getQuizzes(module['_id']);

    if (!mounted) return;

    setState(() {
      quizzes = data;
      isLoadingQuizzes = false;
    });
  }

  Future<void> _refreshAll() async {
    if (selectedLanguage != null) {
      await _selectLanguage(selectedLanguage);
    } else {
      await _loadLanguages();
    }
  }

  void _showQuizForm({Map<String, dynamic>? quiz}) {
    if (selectedModule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih materi terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuizBuilderSheet(
        module: selectedModule,
        existingQuiz: quiz,
        onSaved: () async {
          if (selectedModule != null) {
            await _selectModule(selectedModule);
          }
        },
      ),
    );
  }

  void _confirmDeleteQuiz(String quizId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF5F6F8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Hapus Kuis?',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Kuis yang dihapus tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final success = await ApiService.deleteQuiz(quizId);

              if (!mounted) return;

              Navigator.pop(context);

              if (success) {
                if (selectedModule != null) {
                  await _selectModule(selectedModule);
                }

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kuis berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus kuis'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        color: Colors.green,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 22),

              _buildSelectorCard(),

              const SizedBox(height: 22),

              _buildQuizListHeader(),

              const SizedBox(height: 14),

              _buildQuizContent(),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed:
                      selectedModule == null ? null : () => _showQuizForm(),
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Tambah Kuis',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.quiz_outlined,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kuis',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Kelola soal pembelajaran',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bahasa Pemrograman',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          _buildLanguageDropdown(),

          const SizedBox(height: 16),

          const Text(
            'Materi / Bab',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          _buildModuleDropdown(),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    if (isLoadingLanguages) {
      return _loadingBox('Memuat bahasa...');
    }

    if (languages.isEmpty) {
      return _emptyBox('Belum ada bahasa');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: selectedLanguage,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: languages.map((lang) {
            return DropdownMenuItem<dynamic>(
              value: lang,
              child: Row(
                children: [
                  _smallLanguageIcon(lang['icon_url']),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang['nama_bahasa'] ?? 'Tanpa Nama',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _selectLanguage(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildModuleDropdown() {
    if (isLoadingModules) {
      return _loadingBox('Memuat materi...');
    }

    if (selectedLanguage == null) {
      return _emptyBox('Pilih bahasa dahulu');
    }

    if (modules.isEmpty) {
      return _emptyBox('Belum ada materi untuk bahasa ini');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: selectedModule,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: modules.map((mod) {
            return DropdownMenuItem<dynamic>(
              value: mod,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.green,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mod['judul_modul'] ?? 'Tanpa Judul',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _selectModule(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildQuizListHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Daftar Kuis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.format_list_bulleted_rounded,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizContent() {
    if (isLoadingQuizzes) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(35),
          child: CircularProgressIndicator(
            color: Colors.green,
          ),
        ),
      );
    }

    if (selectedModule == null) {
      return _emptyQuizCard('Pilih materi terlebih dahulu');
    }

    if (quizzes.isEmpty) {
      return _emptyQuizCard('Belum ada kuis untuk materi ini');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        return _buildQuizCard(quizzes[index]);
      },
    );
  }

  Widget _buildQuizCard(dynamic quiz) {
    final List soal = quiz['daftar_soal'] ?? [];
    final int xp = _toInt(quiz['xp_reward']);
    final String moduleName = selectedModule?['judul_modul'] ?? 'Materi';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _quizLanguageIcon(),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moduleName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '${soal.length} Soal • $xp XP',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    _smallActionButton(
                      label: 'Edit',
                      icon: Icons.edit,
                      color: Colors.green,
                      onTap: () => _showQuizForm(
                        quiz: Map<String, dynamic>.from(quiz),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _smallActionButton(
                      label: 'Hapus',
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: () => _confirmDeleteQuiz(quiz['_id']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  Widget _smallActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.45),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallLanguageIcon(String? iconUrl) {
    return Container(
      width: 36,
      height: 36,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: iconUrl != null && iconUrl.isNotEmpty
          ? Image.network(
              iconUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.code_rounded,
                  color: Colors.green,
                  size: 19,
                );
              },
            )
          : const Icon(
              Icons.code_rounded,
              color: Colors.green,
              size: 19,
            ),
    );
  }

  Widget _quizLanguageIcon() {
    final String? iconUrl = selectedLanguage?['icon_url'];

    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: iconUrl != null && iconUrl.isNotEmpty
          ? Image.network(
              iconUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.quiz_outlined,
                  color: Colors.green,
                  size: 36,
                );
              },
            )
          : const Icon(
              Icons.quiz_outlined,
              color: Colors.green,
              size: 36,
            ),
    );
  }

  Widget _loadingBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: Colors.green,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _emptyQuizCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.quiz_outlined,
            color: Colors.grey.shade400,
            size: 46,
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class QuizBuilderSheet extends StatefulWidget {
  final dynamic module;
  final Map<String, dynamic>? existingQuiz;
  final Future<void> Function() onSaved;

  const QuizBuilderSheet({
    super.key,
    required this.module,
    this.existingQuiz,
    required this.onSaved,
  });

  @override
  State<QuizBuilderSheet> createState() => _QuizBuilderSheetState();
}

class _QuizBuilderSheetState extends State<QuizBuilderSheet> {
  final TextEditingController xpController = TextEditingController(text: '50');
  final List<QuestionFormData> questions = [];

  bool isSaving = false;

  bool get isEditMode => widget.existingQuiz != null;

  @override
  void initState() {
    super.initState();

    if (widget.existingQuiz != null) {
      xpController.text =
          (widget.existingQuiz!['xp_reward'] ?? 50).toString();

      final List soal = widget.existingQuiz!['daftar_soal'] ?? [];

      for (var item in soal) {
        if (item is Map) {
          questions.add(
            QuestionFormData.fromMap(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    if (questions.isEmpty) {
      questions.add(QuestionFormData());
    }
  }

  @override
  void dispose() {
    xpController.dispose();

    for (final q in questions) {
      q.dispose();
    }

    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      questions.add(QuestionFormData());
    });
  }

  void _removeQuestion(int index) {
    if (questions.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal harus ada 1 soal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      questions[index].dispose();
      questions.removeAt(index);
    });
  }

  Future<void> _pickQuestionImage(QuestionFormData question) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        question.imageFile = File(picked.path);
      });
    }
  }

  void _removeQuestionImage(QuestionFormData question) {
    setState(() {
      question.imageFile = null;
      question.imageUrl = '';
    });
  }

  Future<void> _saveQuiz() async {
    final int xp = int.tryParse(xpController.text.trim()) ?? 0;

    if (xp <= 0) {
      _showError('XP Reward harus lebih dari 0');
      return;
    }

    for (int i = 0; i < questions.length; i++) {
      final validation = questions[i].validate(i + 1);
      if (validation != null) {
        _showError(validation);
        return;
      }
    }

    setState(() => isSaving = true);

    final daftarSoal = questions.map((q) => q.toMap()).toList();

    bool success;

    if (isEditMode) {
      success = await ApiService.updateQuiz(
        widget.existingQuiz!['_id'],
        daftarSoal,
        xp,
      );
    } else {
      success = await ApiService.addQuiz(
        widget.module['_id'],
        daftarSoal,
        xp,
      );
    }

    if (!mounted) return;

    setState(() => isSaving = false);

    if (success) {
      await widget.onSaved();

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode ? 'Kuis berhasil diupdate' : 'Kuis berhasil disimpan',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showError(
        isEditMode ? 'Gagal update kuis' : 'Gagal menyimpan kuis',
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6F8),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: Text(
                    isEditMode ? 'Edit Kuis' : 'Tambah Kuis Baru',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _selectedMaterialBox(),

                  const SizedBox(height: 18),

                  _xpInput(),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Soal Kuis',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${questions.length} Soal • ${int.tryParse(xpController.text) ?? 0} XP',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  ...questions.asMap().entries.map((entry) {
                    return _questionCard(entry.key, entry.value);
                  }),

                  InkWell(
                    onTap: _addQuestion,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Tambah Soal',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _saveQuiz,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.save_outlined,
                        color: Colors.white,
                      ),
                label: Text(
                  isSaving
                      ? 'Menyimpan...'
                      : isEditMode
                          ? 'Update Kuis'
                          : 'Simpan Kuis',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedMaterialBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Materi Terpilih',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.module['judul_modul'] ?? 'Tanpa Judul',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _xpInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'XP Reward',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: xpController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.stars_outlined,
              color: Colors.grey,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Colors.green,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _questionCard(int index, QuestionFormData question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Soal ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeQuestion(index),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _field(
            question.questionController,
            'Pertanyaan',
            'Contoh: Apa fungsi print()?',
          ),

          const SizedBox(height: 12),

          _questionImageBox(question),

          const SizedBox(height: 14),

          const Text(
            'Pilihan Jawaban',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          _optionField(
            'A',
            question.optionAController,
          ),

          const SizedBox(height: 8),

          _optionField(
            'B',
            question.optionBController,
          ),

          const SizedBox(height: 8),

          _optionField(
            'C',
            question.optionCController,
          ),

          const SizedBox(height: 8),

          _optionField(
            'D',
            question.optionDController,
          ),

          const SizedBox(height: 16),

          const Text(
            'Jawaban Benar',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: ['A', 'B', 'C', 'D'].map((answer) {
              final selected = question.correctAnswer == answer;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        question.correctAnswer = answer;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: selected ? Colors.green : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? Colors.green : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          answer,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _questionImageBox(QuestionFormData question) {
    final bool hasLocalImage = question.imageFile != null;
    final bool hasNetworkImage = question.imageUrl.trim().isNotEmpty;

    return Column(
      children: [
        if (hasLocalImage || hasNetworkImage)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: hasLocalImage
                    ? Image.file(
                        question.imageFile!,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      )
                    : CachedNetworkImage(
                        imageUrl: question.imageUrl,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          height: 160,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.green,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: double.infinity,
                          height: 160,
                          color: Colors.grey.shade100,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () => _removeQuestionImage(question),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),

        if (hasLocalImage || hasNetworkImage) const SizedBox(height: 10),

        InkWell(
          onTap: () => _pickQuestionImage(question),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.green.withOpacity(0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.image_outlined,
                  color: Colors.green,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasLocalImage || hasNetworkImage
                        ? 'Ganti gambar soal'
                        : 'Tambah gambar soal',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          maxLines: null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.green,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionField(
    String label,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        hintText: 'Jawaban $label',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}

class QuestionFormData {
  final TextEditingController questionController;
  final TextEditingController optionAController;
  final TextEditingController optionBController;
  final TextEditingController optionCController;
  final TextEditingController optionDController;

  String correctAnswer;
  File? imageFile;
  String imageUrl;

  QuestionFormData({
    String question = '',
    String optionA = '',
    String optionB = '',
    String optionC = '',
    String optionD = '',
    this.correctAnswer = 'A',
    this.imageFile,
    this.imageUrl = '',
  })  : questionController = TextEditingController(text: question),
        optionAController = TextEditingController(text: optionA),
        optionBController = TextEditingController(text: optionB),
        optionCController = TextEditingController(text: optionC),
        optionDController = TextEditingController(text: optionD);

  factory QuestionFormData.fromMap(Map<String, dynamic> map) {
    final dynamic opsiRaw = map['opsi'] ?? map['pilihan'];

    String optionA = '';
    String optionB = '';
    String optionC = '';
    String optionD = '';

    if (opsiRaw is List) {
      optionA = opsiRaw.isNotEmpty ? opsiRaw[0]?.toString() ?? '' : '';
      optionB = opsiRaw.length > 1 ? opsiRaw[1]?.toString() ?? '' : '';
      optionC = opsiRaw.length > 2 ? opsiRaw[2]?.toString() ?? '' : '';
      optionD = opsiRaw.length > 3 ? opsiRaw[3]?.toString() ?? '' : '';
    } else if (opsiRaw is Map) {
      optionA = opsiRaw['A']?.toString() ?? '';
      optionB = opsiRaw['B']?.toString() ?? '';
      optionC = opsiRaw['C']?.toString() ?? '';
      optionD = opsiRaw['D']?.toString() ?? '';
    }

    String correctAnswer = 'A';
    final dynamic rawAnswer =
        map['jawaban_benar'] ?? map['correct_answer'] ?? map['correctAnswer'];

    if (rawAnswer is int) {
      correctAnswer = _indexToAnswer(rawAnswer);
    } else if (rawAnswer is num) {
      correctAnswer = _indexToAnswer(rawAnswer.toInt());
    } else {
      final answerString = rawAnswer?.toString().toUpperCase().trim() ?? 'A';

      if (['A', 'B', 'C', 'D'].contains(answerString)) {
        correctAnswer = answerString;
      } else {
        correctAnswer = 'A';
      }
    }

    return QuestionFormData(
      question: map['pertanyaan']?.toString() ?? map['question']?.toString() ?? '',
      optionA: optionA,
      optionB: optionB,
      optionC: optionC,
      optionD: optionD,
      correctAnswer: correctAnswer,
      imageUrl: map['gambar_url']?.toString() ??
          map['image_url']?.toString() ??
          '',
    );
  }

  static String _indexToAnswer(int index) {
    switch (index) {
      case 0:
        return 'A';
      case 1:
        return 'B';
      case 2:
        return 'C';
      case 3:
        return 'D';
      default:
        return 'A';
    }
  }

  String? validate(int number) {
    if (questionController.text.trim().isEmpty) {
      return 'Pertanyaan soal $number wajib diisi';
    }

    if (optionAController.text.trim().isEmpty ||
        optionBController.text.trim().isEmpty ||
        optionCController.text.trim().isEmpty ||
        optionDController.text.trim().isEmpty) {
      return 'Semua pilihan jawaban soal $number wajib diisi';
    }

    if (!['A', 'B', 'C', 'D'].contains(correctAnswer)) {
      return 'Jawaban benar soal $number wajib dipilih';
    }

    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'pertanyaan': questionController.text.trim(),
      'gambar_url': imageUrl,
      'image_file': imageFile,
      'opsi': {
        'A': optionAController.text.trim(),
        'B': optionBController.text.trim(),
        'C': optionCController.text.trim(),
        'D': optionDController.text.trim(),
      },
      'jawaban_benar': correctAnswer,
    };
  }

  void dispose() {
    questionController.dispose();
    optionAController.dispose();
    optionBController.dispose();
    optionCController.dispose();
    optionDController.dispose();
  }
}