import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';

class AdminManageAchievements extends StatefulWidget {
  const AdminManageAchievements({super.key});

  @override
  State<AdminManageAchievements> createState() =>
      _AdminManageAchievementsState();
}

class _AdminManageAchievementsState extends State<AdminManageAchievements> {
  List<dynamic> languages = [];
  List<dynamic> achievements = [];

  dynamic selectedLanguage;
  String selectedCategory = 'progress_belajar';

  bool isLoadingLanguages = true;
  bool isLoadingAchievements = true;

  final List<Map<String, dynamic>> categories = const [
    {
      'label': 'Progress Belajar',
      'value': 'progress_belajar',
      'icon': Icons.school_rounded,
    },
    {
      'label': 'Quiz Master',
      'value': 'quiz_master',
      'icon': Icons.quiz_rounded,
    },
    {
      'label': 'XP Reward',
      'value': 'xp_reward',
      'icon': Icons.stars_rounded,
    },
    {
      'label': 'Streak Login',
      'value': 'streak_login',
      'icon': Icons.local_fire_department_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadLanguages();
    await _loadAchievements();
  }

  Future<void> _loadLanguages() async {
    if (!mounted) return;

    setState(() => isLoadingLanguages = true);

    final data = await ApiService.getLanguages();

    if (!mounted) return;

    setState(() {
      languages = data;
      isLoadingLanguages = false;

      if (languages.isNotEmpty && selectedLanguage == null) {
        selectedLanguage = languages.first;
      }
    });
  }

  Future<void> _loadAchievements() async {
    if (!mounted) return;

    setState(() => isLoadingAchievements = true);

    final data = await ApiService.getAchievements();

    if (!mounted) return;

    setState(() {
      achievements = data;
      isLoadingAchievements = false;
    });
  }

  Future<void> _refreshAll() async {
    await _loadLanguages();
    await _loadAchievements();
  }

  List<dynamic> get filteredAchievements {
    return achievements.where((achievement) {
      final languageId =
          achievement['language_id']?['_id'] ?? achievement['language_id'];

      final category = achievement['syarat_tipe'] ?? achievement['kategori'];

      final matchLanguage =
          selectedLanguage == null || languageId == selectedLanguage['_id'];

      final matchCategory = category == selectedCategory;

      return matchLanguage && matchCategory;
    }).toList();
  }

  int get totalXp {
    return filteredAchievements.fold<int>(0, (sum, item) {
      final value = item['xp_reward'] ?? item['xp'] ?? 0;

      if (value is int) return sum + value;

      return sum + (int.tryParse(value.toString()) ?? 0);
    });
  }

  void _showAchievementForm({Map<String, dynamic>? achievement}) {
    if (selectedLanguage == null && achievement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih bahasa terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AchievementFormSheet(
        languages: languages,
        selectedLanguage: selectedLanguage,
        existingAchievement: achievement,
        onSaved: _loadAchievements,
      ),
    );
  }

  void _confirmDeleteAchievement(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF5F6F8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Hapus Achievement?',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Achievement yang dihapus tidak bisa dikembalikan.',
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
              final success = await ApiService.deleteAchievement(id);

              if (!mounted) return;

              Navigator.pop(context);

              if (success) {
                await _loadAchievements();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Achievement berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus achievement'),
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
        color: Colors.green,
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 22),

              _buildFilterCard(),

              const SizedBox(height: 22),

              _buildSummaryCard(),

              const SizedBox(height: 22),

              _buildListHeader(),

              const SizedBox(height: 14),

              _buildAchievementContent(),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: selectedLanguage == null
                      ? null
                      : () => _showAchievementForm(),
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Tambah Achievement',
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
            Icons.emoji_events_rounded,
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
                'Lencana',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Kelola achievement pembelajaran',
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

  Widget _buildFilterCard() {
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
            'Kategori',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          _buildCategoryDropdown(),
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
            setState(() {
              selectedLanguage = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
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
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: categories.map((item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'],
                      color: Colors.green,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['label'],
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
              setState(() {
                selectedCategory = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.green.withOpacity(0.15),
        ),
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
              Icons.emoji_events_rounded,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Total ${filteredAchievements.length} Achievement • $totalXp XP',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Daftar Achievement',
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

  Widget _buildAchievementContent() {
    if (isLoadingAchievements) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(35),
          child: CircularProgressIndicator(
            color: Colors.green,
          ),
        ),
      );
    }

    if (selectedLanguage == null) {
      return _emptyAchievementCard('Pilih bahasa terlebih dahulu');
    }

    if (filteredAchievements.isEmpty) {
      return _emptyAchievementCard('Belum ada achievement untuk filter ini');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredAchievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(filteredAchievements[index]);
      },
    );
  }

  Widget _buildAchievementCard(dynamic achievement) {
    final String title = achievement['judul'] ?? 'Tanpa Judul';
    final String desc = achievement['deskripsi'] ?? '';
    final int xp = achievement['xp_reward'] ?? achievement['xp'] ?? 0;
    final String rarity = achievement['rarity'] ?? 'Common';
    final String icon = achievement['icon'] ?? achievement['icon_url'] ?? '';

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
          _achievementIcon(icon),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _rarityBadge(rarity),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '$xp XP',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    _smallActionButton(
                      label: 'Edit',
                      icon: Icons.edit,
                      color: Colors.green,
                      onTap: () => _showAchievementForm(
                        achievement: Map<String, dynamic>.from(achievement),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _smallActionButton(
                      label: 'Hapus',
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: () => _confirmDeleteAchievement(
                        achievement['_id'],
                      ),
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
            )
          : const Icon(
              Icons.code_rounded,
              color: Colors.green,
              size: 19,
            ),
    );
  }

  Widget _achievementIcon(String iconUrl) {
    return Container(
      width: 86,
      height: 86,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: iconUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: iconUrl,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.green,
                  size: 42,
                ),
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(
                    color: Colors.green,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          : const Icon(
              Icons.emoji_events_rounded,
              color: Colors.green,
              size: 42,
            ),
    );
  }

  Widget _rarityBadge(String rarity) {
    Color color;

    switch (rarity.toLowerCase()) {
      case 'rare':
        color = Colors.green;
        break;
      case 'epic':
        color = Colors.purple;
        break;
      case 'legendary':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        rarity,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
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

  Widget _emptyAchievementCard(String text) {
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
            Icons.emoji_events_outlined,
            color: Colors.grey.shade400,
            size: 46,
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
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

// =====================================================
// FORM TAMBAH / EDIT ACHIEVEMENT
// =====================================================

class AchievementFormSheet extends StatefulWidget {
  final List<dynamic> languages;
  final dynamic selectedLanguage;
  final Map<String, dynamic>? existingAchievement;
  final Future<void> Function() onSaved;

  const AchievementFormSheet({
    super.key,
    required this.languages,
    required this.selectedLanguage,
    this.existingAchievement,
    required this.onSaved,
  });

  @override
  State<AchievementFormSheet> createState() => _AchievementFormSheetState();
}

class _AchievementFormSheetState extends State<AchievementFormSheet> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final xpController = TextEditingController(text: '100');
  final requirementController = TextEditingController(text: '5');

  dynamic selectedLanguage;
  String selectedCategory = 'progress_belajar';
  String selectedRarity = 'Rare';

  File? selectedBadgeFile;
  String existingIconUrl = '';

  bool isSaving = false;

  bool get isEditMode => widget.existingAchievement != null;

  final List<Map<String, dynamic>> categories = const [
    {
      'label': 'Progress Belajar',
      'value': 'progress_belajar',
      'icon': Icons.school_rounded,
    },
    {
      'label': 'Quiz Master',
      'value': 'quiz_master',
      'icon': Icons.quiz_rounded,
    },
    {
      'label': 'XP Reward',
      'value': 'xp_reward',
      'icon': Icons.stars_rounded,
    },
    {
      'label': 'Streak Login',
      'value': 'streak_login',
      'icon': Icons.local_fire_department_rounded,
    },
  ];

  final List<String> rarities = const [
    'Common',
    'Rare',
    'Epic',
    'Legendary',
  ];

  @override
  void initState() {
    super.initState();

    selectedLanguage = widget.selectedLanguage;

    if (widget.existingAchievement != null) {
      final achievement = widget.existingAchievement!;

      titleController.text = achievement['judul'] ?? '';
      descriptionController.text = achievement['deskripsi'] ?? '';
      xpController.text =
          (achievement['xp_reward'] ?? achievement['xp'] ?? 100).toString();

      requirementController.text =
          (achievement['syarat_nilai'] ?? 5).toString();

      selectedCategory =
          achievement['syarat_tipe'] ?? achievement['kategori'] ?? 'progress_belajar';

      selectedRarity = achievement['rarity'] ?? 'Rare';

      existingIconUrl = achievement['icon'] ?? achievement['icon_url'] ?? '';

      final achievementLanguageId =
          achievement['language_id']?['_id'] ?? achievement['language_id'];

      if (achievementLanguageId != null) {
        try {
          selectedLanguage = widget.languages.firstWhere(
            (lang) => lang['_id'] == achievementLanguageId,
          );
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    xpController.dispose();
    requirementController.dispose();
    super.dispose();
  }

  Future<void> _pickBadgeFromDriveOrFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedBadgeFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _saveAchievement() async {
    if (selectedLanguage == null) {
      _showError('Bahasa wajib dipilih');
      return;
    }

    if (titleController.text.trim().isEmpty) {
      _showError('Nama achievement wajib diisi');
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      _showError('Deskripsi wajib diisi');
      return;
    }

    final int xp = int.tryParse(xpController.text.trim()) ?? 0;
    final int requirement =
        int.tryParse(requirementController.text.trim()) ?? 0;

    if (xp <= 0) {
      _showError('XP Reward harus lebih dari 0');
      return;
    }

    if (requirement <= 0) {
      _showError('Syarat unlock harus lebih dari 0');
      return;
    }

    if (!isEditMode && selectedBadgeFile == null) {
      _showError('Upload badge achievement terlebih dahulu');
      return;
    }

    setState(() => isSaving = true);

    Map<String, dynamic> result;

    if (isEditMode) {
      result = await ApiService.updateAchievementV2(
        id: widget.existingAchievement!['_id'],
        languageId: selectedLanguage['_id'],
        judul: titleController.text.trim(),
        deskripsi: descriptionController.text.trim(),
        syaratTipe: selectedCategory,
        syaratNilai: requirement,
        xpReward: xp,
        rarity: selectedRarity,
        iconFile: selectedBadgeFile,
        existingIconUrl: existingIconUrl,
      );
    } else {
      result = await ApiService.addAchievementV2(
        languageId: selectedLanguage['_id'],
        judul: titleController.text.trim(),
        deskripsi: descriptionController.text.trim(),
        syaratTipe: selectedCategory,
        syaratNilai: requirement,
        xpReward: xp,
        rarity: selectedRarity,
        iconFile: selectedBadgeFile!,
      );
    }

    if (!mounted) return;

    setState(() => isSaving = false);

    if (result['success'] == true) {
      await widget.onSaved();

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Achievement berhasil diupdate'
                : 'Achievement berhasil ditambahkan',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showError(result['message'] ?? 'Gagal menyimpan achievement');
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
                    isEditMode ? 'Edit Achievement' : 'Tambah Achievement',
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
                  _previewCard(),

                  const SizedBox(height: 18),

                  _languageDropdown(),

                  const SizedBox(height: 14),

                  _input(
                    titleController,
                    'Nama Achievement',
                    'Contoh: Python Explorer',
                  ),

                  const SizedBox(height: 14),

                  _input(
                    descriptionController,
                    'Deskripsi',
                    'Contoh: Selesaikan 5 materi Python',
                  ),

                  const SizedBox(height: 14),

                  _input(
                    xpController,
                    'XP Reward',
                    'Contoh: 100',
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 14),

                  _input(
                    requirementController,
                    'Syarat Unlock',
                    'Contoh: 5',
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 14),

                  _categoryDropdown(),

                  const SizedBox(height: 18),

                  const Text(
                    'Rarity',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _raritySelector(),

                  const SizedBox(height: 18),

                  _uploadBadgeBox(),

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
                onPressed: isSaving ? null : _saveAchievement,
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
                  isSaving ? 'Menyimpan...' : 'Simpan Achievement',
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

  Widget _previewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.green.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          _previewIcon(),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preview Badge',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  titleController.text.trim().isEmpty
                      ? 'Nama Achievement'
                      : titleController.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  descriptionController.text.trim().isEmpty
                      ? 'Deskripsi achievement'
                      : descriptionController.text.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewIcon() {
    return Container(
      width: 86,
      height: 86,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: selectedBadgeFile != null
            ? Image.file(
                selectedBadgeFile!,
                fit: BoxFit.contain,
              )
            : existingIconUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: existingIconUrl,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.green,
                      size: 46,
                    ),
                  )
                : const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.green,
                    size: 46,
                  ),
      ),
    );
  }

  Widget _languageDropdown() {
    return Column(
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

        Container(
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
              items: widget.languages.map((lang) {
                return DropdownMenuItem<dynamic>(
                  value: lang,
                  child: Text(
                    lang['nama_bahasa'] ?? 'Tanpa Nama',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedLanguage = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: categories.map((item) {
                return DropdownMenuItem<String>(
                  value: item['value'],
                  child: Row(
                    children: [
                      Icon(
                        item['icon'],
                        color: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Text(item['label']),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _input(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
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
          keyboardType: keyboardType,
          onChanged: (_) => setState(() {}),
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

  Widget _raritySelector() {
    return Row(
      children: rarities.map((rarity) {
        final selected = selectedRarity == rarity;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedRarity = rarity;
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? Colors.green : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? Colors.green : Colors.grey.shade300,
                  ),
                ),
                child: Center(
                  child: Text(
                    rarity,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _uploadBadgeBox() {
    return InkWell(
      onTap: _pickBadgeFromDriveOrFiles,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: Colors.green,
                size: 32,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedBadgeFile == null
                        ? 'Upload Badge'
                        : 'Badge berhasil dipilih',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 3),

                  const Text(
                    'Pilih PNG/JPG dari galeri, file, atau Google Drive',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}