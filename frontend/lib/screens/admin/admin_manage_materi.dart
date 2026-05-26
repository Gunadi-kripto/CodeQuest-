import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/api_service.dart';

class AdminManageMateri extends StatefulWidget {
  final String languageId;
  final String languageName;
  final String? languageIconUrl;
  final String? languageUpdatedAt;

  const AdminManageMateri({
    super.key,
    required this.languageId,
    required this.languageName,
    this.languageIconUrl,
    this.languageUpdatedAt,
  });

  @override
  State<AdminManageMateri> createState() => _AdminManageMateriState();
}

class _AdminManageMateriState extends State<AdminManageMateri> {
  List<dynamic> modules = [];
  bool isLoading = true;

  String currentLanguageName = '';
  String currentLanguageIconUrl = '';
  String currentLanguageUpdatedAt = '';

  Timer? _timeAgoTimer;

  @override
  void initState() {
    super.initState();

    currentLanguageName = widget.languageName;
    currentLanguageIconUrl = widget.languageIconUrl ?? '';
    currentLanguageUpdatedAt = widget.languageUpdatedAt ?? '';

    _fetchModules();
    _fetchLanguageInfo();

    _timeAgoTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timeAgoTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchModules() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final data = await ApiService.getModulesByLanguage(widget.languageId);

      if (!mounted) return;

      setState(() {
        modules = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengambil data materi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchLanguageInfo() async {
    try {
      final languages = await ApiService.getLanguages();

      dynamic matched;

      try {
        matched = languages.firstWhere(
          (item) => item['_id'] == widget.languageId,
        );
      } catch (_) {
        matched = null;
      }

      if (matched != null && mounted) {
        setState(() {
          currentLanguageName = matched['nama_bahasa'] ?? currentLanguageName;
          currentLanguageIconUrl =
              matched['icon_url'] ?? currentLanguageIconUrl;
          currentLanguageUpdatedAt =
              matched['updatedAt'] ?? currentLanguageUpdatedAt;
        });
      }
    } catch (e) {
      debugPrint('Gagal fetch detail bahasa: $e');
    }
  }

  String _timeAgo(String dateString) {
    if (dateString.isEmpty) return 'Baru saja';

    try {
      final dateTime = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Baru saja';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} menit lalu';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} jam lalu';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari lalu';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks minggu lalu';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months bulan lalu';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years tahun lalu';
      }
    } catch (e) {
      return 'Baru saja';
    }
  }

  void _showEditLanguageDialog() {
    final TextEditingController languageController = TextEditingController(
      text: currentLanguageName.isEmpty
          ? widget.languageName
          : currentLanguageName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F6F8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Edit Bahasa",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: languageController,
          decoration: InputDecoration(
            hintText: "Masukkan nama bahasa",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final newName = languageController.text.trim();

              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Nama bahasa tidak boleh kosong"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final success = await ApiService.updateLanguage(
                widget.languageId,
                newName,
              );

              if (!mounted) return;

              if (success) {
                setState(() {
                  currentLanguageName = newName;
                  currentLanguageUpdatedAt = DateTime.now().toIso8601String();
                });

                await _fetchLanguageInfo();

                if (!mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bahasa berhasil diupdate"),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Gagal update bahasa"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLanguage() {
    final languageName = currentLanguageName.isEmpty
        ? widget.languageName
        : currentLanguageName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F6F8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Hapus Bahasa?",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Yakin ingin menghapus bahasa '$languageName'? Semua materi di dalam bahasa ini juga bisa ikut terhapus.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
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
              final success = await ApiService.deleteLanguage(
                widget.languageId,
              );

              if (!mounted) return;

              if (success) {
                Navigator.pop(context);
                Navigator.pop(context, true);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bahasa berhasil dihapus"),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Gagal menghapus bahasa"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteModule(String id, String judul) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF5F6F8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Hapus Materi?",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text("Yakin ingin menghapus '$judul'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
            ),
            onPressed: () async {
              bool success = await ApiService.deleteModule(id);

              if (!mounted) return;

              if (success) {
                Navigator.pop(context);

                await _fetchModules();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Materi berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus materi'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showForm({Map<String, dynamic>? module, bool openDraft = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiContentForm(
        languageId: widget.languageId,
        existingModule: module,
        openDraft: openDraft,
        onSave: _fetchModules,
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayLanguageName = currentLanguageName.isEmpty
        ? widget.languageName
        : currentLanguageName;

    final bool hasDraft = ModuleDraftStore.hasDraft(widget.languageId);

    return Scaffold(
      // AppBar transparan dengan panah back warna putih
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Universal
          SizedBox.expand(
            child: Image.asset(
              'assets/coding_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await _fetchModules();
                      await _fetchLanguageInfo();
                    },
                    color: Colors.green,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Materi',
                            style: TextStyle(
                              color: Colors.white, // Ubah ke putih
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Kelola materi pembelajaran',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ), // Putih transparan
                          ),
                          const SizedBox(height: 25),
                          _buildLanguageHeaderCard(displayLanguageName),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Daftar Bab',
                                style: TextStyle(
                                  color: Colors.white, // Ubah ke putih
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showForm(),
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  "Tambah Bab",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          if (hasDraft) _buildDraftCard(),

                          if (modules.isEmpty && !hasDraft)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                  0.92,
                                ), // Glassmorphism
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: Text(
                                  "Belum ada materi",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: modules.length,
                              itemBuilder: (context, index) {
                                final mod = modules[index];
                                return _buildChapterCard(index + 1, mod);
                              },
                            ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageHeaderCard(String displayLanguageName) {
    final updatedText = _timeAgo(currentLanguageUpdatedAt);
    final iconUrl = currentLanguageIconUrl.isNotEmpty
        ? currentLanguageIconUrl
        : (widget.languageIconUrl ?? '');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92), // Glassmorphism
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 65,
                height: 65,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: iconUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: iconUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.green,
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 35,
                          ),
                        )
                      : const Icon(Icons.code, color: Colors.blue, size: 35),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayLanguageName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Aktif",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${modules.length} Materi • Terakhir diupdate $updatedText",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _showEditLanguageDialog,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Edit Bahasa",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _confirmDeleteLanguage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Hapus Bahasa",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraftCard() {
    final draft = ModuleDraftStore.get(widget.languageId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // Glassmorphism draft
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_note_rounded, color: Colors.orange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Draft - Belum Disimpan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  draft?.judul.trim().isNotEmpty == true
                      ? draft!.judul
                      : 'Lanjutkan materi yang belum disimpan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.green),
              onPressed: () => _showForm(openDraft: true),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  ModuleDraftStore.remove(widget.languageId);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(int number, dynamic mod) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92), // Glassmorphism
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bab $number - ${mod['judul_modul'] ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mod['deskripsi'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _showForm(module: mod),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red,
              ),
              onPressed: () => _confirmDeleteModule(
                mod['_id'],
                mod['judul_modul'] ?? 'Tanpa Judul',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// SISA KODE (Draft Store & MultiContentForm) SAMA SAJA
// =====================================================

class ModuleDraftData {
  final String judul;
  final String deskripsi;
  final List<Map<String, dynamic>> contents;

  ModuleDraftData({
    required this.judul,
    required this.deskripsi,
    required this.contents,
  });
}

class ModuleDraftStore {
  static final Map<String, ModuleDraftData> _drafts = {};

  static String key(String languageId) => 'module_draft_$languageId';

  static ModuleDraftData? get(String languageId) {
    return _drafts[key(languageId)];
  }

  static void save(String languageId, ModuleDraftData draft) {
    _drafts[key(languageId)] = draft;
  }

  static void remove(String languageId) {
    _drafts.remove(key(languageId));
  }

  static bool hasDraft(String languageId) {
    return _drafts.containsKey(key(languageId));
  }
}

class MultiContentForm extends StatefulWidget {
  final String languageId;
  final Map<String, dynamic>? existingModule;
  final bool openDraft;
  final VoidCallback onSave;

  const MultiContentForm({
    super.key,
    required this.languageId,
    this.existingModule,
    this.openDraft = false,
    required this.onSave,
  });

  @override
  State<MultiContentForm> createState() => _MultiContentFormState();
}

class _MultiContentFormState extends State<MultiContentForm> {
  final _judulController = TextEditingController();
  final _descController = TextEditingController();

  List<Map<String, dynamic>> contentItems = [];
  bool isSaving = false;

  bool get isEditMode => widget.existingModule != null;

  @override
  void initState() {
    super.initState();

    if (widget.openDraft && !isEditMode) {
      final draft = ModuleDraftStore.get(widget.languageId);

      if (draft != null) {
        _judulController.text = draft.judul;
        _descController.text = draft.deskripsi;

        for (final item in draft.contents) {
          if (item['tipe'] == 'text') {
            final controller = TextEditingController(
              text: item['content']?.toString() ?? '',
            );

            controller.addListener(_saveDraft);

            contentItems.add({
              'tipe': 'text',
              'controller': controller,
              'isExisting': false,
            });
          } else if (item['tipe'] == 'image') {
            final path = item['path']?.toString() ?? '';

            if (path.isNotEmpty && File(path).existsSync()) {
              contentItems.add({
                'tipe': 'image',
                'file': File(path),
                'isExisting': false,
              });
            }
          }
        }
      }
    } else if (widget.existingModule != null) {
      _judulController.text = widget.existingModule!['judul_modul'] ?? '';
      _descController.text = widget.existingModule!['deskripsi'] ?? '';

      var materiIsi = widget.existingModule!['materi_isi'];

      if (materiIsi != null && materiIsi is List) {
        for (var item in materiIsi) {
          final tipe = item['tipe'] ?? 'text';
          final content = item['content']?.toString() ?? '';

          contentItems.add({
            'tipe': tipe,
            'content': content,
            'isExisting': true,
            'controller': tipe == 'text'
                ? TextEditingController(text: content)
                : null,
          });
        }
      }
    }

    _judulController.addListener(_saveDraft);
    _descController.addListener(_saveDraft);
  }

  @override
  void dispose() {
    _saveDraft();

    _judulController.removeListener(_saveDraft);
    _descController.removeListener(_saveDraft);

    _judulController.dispose();
    _descController.dispose();

    for (var item in contentItems) {
      _disposeItemController(item);
    }

    super.dispose();
  }

  void _disposeItemController(Map<String, dynamic> item) {
    if (item['controller'] != null &&
        item['controller'] is TextEditingController) {
      item['controller'].dispose();
    }
  }

  void _saveDraft() {
    if (isEditMode) return;

    final List<Map<String, dynamic>> draftContents = [];

    for (final item in contentItems) {
      if (item['tipe'] == 'text') {
        final controller = item['controller'];

        draftContents.add({
          'tipe': 'text',
          'content': controller is TextEditingController ? controller.text : '',
        });
      } else if (item['tipe'] == 'image') {
        final file = item['file'];

        if (file is File) {
          draftContents.add({'tipe': 'image', 'path': file.path});
        }
      }
    }

    final bool hasDraft =
        _judulController.text.trim().isNotEmpty ||
        _descController.text.trim().isNotEmpty ||
        draftContents.isNotEmpty;

    if (!hasDraft) return;

    ModuleDraftStore.save(
      widget.languageId,
      ModuleDraftData(
        judul: _judulController.text,
        deskripsi: _descController.text,
        contents: draftContents,
      ),
    );
  }

  void _clearDraft() {
    if (!isEditMode) {
      ModuleDraftStore.remove(widget.languageId);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Peringatan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Oke',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addText() {
    final controller = TextEditingController();
    controller.addListener(_saveDraft);

    setState(() {
      contentItems.add({
        'tipe': 'text',
        'controller': controller,
        'isExisting': false,
      });
    });

    _saveDraft();
  }

  Future<void> _addImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        contentItems.add({
          'tipe': 'image',
          'file': File(picked.path),
          'isExisting': false,
        });
      });

      _saveDraft();
    }
  }

  String? _validateForm() {
    if (_judulController.text.trim().isEmpty) {
      return 'Judul bab wajib diisi';
    }

    if (_descController.text.trim().isEmpty) {
      return 'Deskripsi wajib diisi';
    }

    if (contentItems.isEmpty) {
      return 'Minimal isi 1 konten materi';
    }

    for (int i = 0; i < contentItems.length; i++) {
      final item = contentItems[i];

      if (item['tipe'] == 'text') {
        final controller = item['controller'];

        if (controller == null ||
            controller is! TextEditingController ||
            controller.text.trim().isEmpty) {
          return 'Konten teks ${i + 1} masih kosong';
        }
      }

      if (item['tipe'] == 'image') {
        final bool hasExistingImage =
            item['isExisting'] == true &&
            item['content'] != null &&
            item['content'].toString().isNotEmpty;

        final bool hasNewImage = item['file'] != null;

        if (!hasExistingImage && !hasNewImage) {
          return 'Gambar konten ${i + 1} belum dipilih';
        }
      }
    }

    return null;
  }

  Future<void> _submit() async {
    final validationMessage = _validateForm();

    if (validationMessage != null) {
      _showError(validationMessage);
      return;
    }

    setState(() => isSaving = true);

    Map<String, dynamic> res;

    if (isEditMode) {
      res = await ApiService.updateModuleV2(
        idModule: widget.existingModule!['_id'],
        idBahasa: widget.languageId,
        judul: _judulController.text.trim(),
        deskripsi: _descController.text.trim(),
        contents: contentItems,
      );
    } else {
      res = await ApiService.addModuleV2(
        idBahasa: widget.languageId,
        judul: _judulController.text.trim(),
        deskripsi: _descController.text.trim(),
        contents: contentItems,
      );
    }

    if (!mounted) return;

    setState(() => isSaving = false);

    if (res['success'] == true) {
      _clearDraft();

      widget.onSave();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Materi berhasil diupdate'
                : 'Materi berhasil disimpan',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showError(res['message'] ?? 'Gagal menyimpan materi');
    }
  }

  Future<void> _replaceImage(int index) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        contentItems[index]['file'] = File(picked.path);
        contentItems[index]['isExisting'] = false;
        contentItems[index].remove('content');
      });

      _saveDraft();
    }
  }

  Future<bool> _onWillPopForm() async {
    _saveDraft();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPopForm,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEditMode ? "Edit Isi Materi" : "Tambah Isi Materi",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _input(_judulController, "Judul Bab"),
                    const SizedBox(height: 15),
                    _input(_descController, "Deskripsi"),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: _addButton(
                            Icons.text_fields,
                            "Tambah Teks",
                            _addText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _addButton(
                            Icons.image,
                            "Tambah Gambar",
                            _addImage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    ...contentItems.asMap().entries.map((entry) {
                      int i = entry.key;
                      var itm = entry.value;

                      return _contentCard(i, itm);
                    }).toList(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditMode ? "Update Materi" : "Simpan Materi",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      onChanged: (_) => _saveDraft(),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF4F5F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _addButton(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentCard(int i, Map<String, dynamic> itm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Konten ${i + 1} (${itm['tipe'].toString().toUpperCase()})",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _disposeItemController(contentItems[i]);
                    contentItems.removeAt(i);
                  });

                  _saveDraft();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (itm['tipe'] == 'text')
            TextField(
              controller: itm['controller'],
              maxLines: 5,
              onChanged: (_) => _saveDraft(),
              decoration: const InputDecoration(
                hintText: 'Tulis isi materi...',
                border: InputBorder.none,
              ),
            )
          else
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: itm['isExisting'] == true
                      ? CachedNetworkImage(
                          imageUrl: itm['content'],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 180,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.green,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Image.file(
                          itm['file'],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _replaceImage(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          color: Colors.green,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ganti Gambar',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}