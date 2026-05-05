import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminManageAchievements extends StatefulWidget {
  const AdminManageAchievements({super.key});

  @override
  _AdminManageAchievementsState createState() => _AdminManageAchievementsState();
}

class _AdminManageAchievementsState extends State<AdminManageAchievements> {
  List<dynamic> achievements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => isLoading = true);
    final data = await ApiService.getAchievements();
    if (mounted) {
      setState(() {
        achievements = data;
        isLoading = false;
      });
    }
  }

  // Helper untuk mengubah string icon jadi IconData beneran
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'star': return Icons.star;
      case 'menu_book': return Icons.menu_book;
      case 'military_tech': return Icons.military_tech;
      case 'bolt': return Icons.bolt;
      case 'group_add': return Icons.group_add;
      default: return Icons.emoji_events;
    }
  }

  // FUNGSI FORM TAMBAH / EDIT
  void _showForm({Map<String, dynamic>? item}) {
    final bool isEdit = item != null;
    
    final TextEditingController judulController = TextEditingController(text: isEdit ? item['judul'] : '');
    final TextEditingController deskripsiController = TextEditingController(text: isEdit ? item['deskripsi'] : '');
    final TextEditingController nilaiController = TextEditingController(text: isEdit ? item['syarat_nilai'].toString() : '');
    
    String selectedTipe = isEdit ? item['syarat_tipe'] : 'capai_xp';
    String selectedIcon = isEdit ? item['icon'] ?? 'emoji_events' : 'emoji_events';
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
                  Text(isEdit ? 'Edit Pencapaian' : 'Tambah Pencapaian', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 20),
                  
                  TextField(controller: judulController, decoration: const InputDecoration(labelText: 'Judul Lencana', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  
                  TextField(controller: deskripsiController, decoration: const InputDecoration(labelText: 'Deskripsi Singkat', border: OutlineInputBorder())),
                  const SizedBox(height: 16),

                  // Dropdown Tipe Syarat
                  DropdownButtonFormField<String>(
                    value: selectedTipe,
                    decoration: const InputDecoration(labelText: 'Tipe Syarat', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'capai_xp', child: Text('Capai Total XP')),
                      DropdownMenuItem(value: 'baca_materi', child: Text('Total Materi Dibaca')),
                      DropdownMenuItem(value: 'selesai_kuis', child: Text('Total Kuis Diselesaikan')),
                      DropdownMenuItem(value: 'tambah_teman', child: Text('Total Teman')),
                    ],
                    onChanged: (val) => setSheetState(() => selectedTipe = val!),
                  ),
                  const SizedBox(height: 16),

                  TextField(controller: nilaiController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Nilai (Angka)', border: OutlineInputBorder())),
                  const SizedBox(height: 16),

                  // Dropdown Pilihan Icon
                  DropdownButtonFormField<String>(
                    value: selectedIcon,
                    decoration: const InputDecoration(labelText: 'Pilih Ikon', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'emoji_events', child: Row(children: [Icon(Icons.emoji_events, color: Colors.orange), SizedBox(width: 10), Text('Piala')])),
                      DropdownMenuItem(value: 'star', child: Row(children: [Icon(Icons.star, color: Colors.orange), SizedBox(width: 10), Text('Bintang')])),
                      DropdownMenuItem(value: 'military_tech', child: Row(children: [Icon(Icons.military_tech, color: Colors.green), SizedBox(width: 10), Text('Medali')])),
                      DropdownMenuItem(value: 'bolt', child: Row(children: [Icon(Icons.bolt, color: Colors.blue), SizedBox(width: 10), Text('Petir (XP)')])),
                      DropdownMenuItem(value: 'menu_book', child: Row(children: [Icon(Icons.menu_book, color: Colors.brown), SizedBox(width: 10), Text('Buku (Materi)')])),
                      DropdownMenuItem(value: 'group_add', child: Row(children: [Icon(Icons.group_add, color: Colors.purple), SizedBox(width: 10), Text('Teman')])),
                    ],
                    onChanged: (val) => setSheetState(() => selectedIcon = val!),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: isSaving ? null : () async {
                        if (judulController.text.isEmpty || nilaiController.text.isEmpty) return;

                        setSheetState(() => isSaving = true);
                        int nilai = int.tryParse(nilaiController.text) ?? 0;
                        
                        bool success;
                        if (isEdit) {
                          success = await ApiService.updateAchievement(item['_id'], judulController.text, deskripsiController.text, selectedTipe, nilai, selectedIcon);
                        } else {
                          success = await ApiService.addAchievement(judulController.text, deskripsiController.text, selectedTipe, nilai, selectedIcon);
                        }
                        
                        if (success) {
                          Navigator.pop(context); 
                          _loadAchievements(); 
                        } else {
                          setSheetState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan!')));
                        }
                      },
                      child: isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(isEdit ? 'Simpan' : 'Tambah', style: const TextStyle(color: Colors.white, fontSize: 18)),
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

  void _confirmDelete(String id, String judul) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pencapaian?', style: TextStyle(color: Colors.red)),
        content: Text('Yakin ingin menghapus lencana "$judul"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => isLoading = true);
              await ApiService.deleteAchievement(id);
              _loadAchievements();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Lencana', style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : achievements.isEmpty
              ? const Center(child: Text('Belum ada lencana yang dibuat.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final item = achievements[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[100], 
                          child: Icon(_getIconData(item['icon'] ?? ''), color: Colors.orange)
                        ),
                        title: Text(item['judul'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item['deskripsi']}\nSyarat: ${item['syarat_tipe']} = ${item['syarat_nilai']}'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showForm(item: item)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(item['_id'], item['judul'])),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}