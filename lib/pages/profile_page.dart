import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:project_3/pages/categories_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  User? _user;
  String? _displayName;
  String? _avatarUrl;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isUploading = false;
  static const int _maxFileSizeInBytes = 5 * 1024 * 1024; // 5MB limit

  @override
  void initState() {
    super.initState();
    _user = supabase.auth.currentUser;
    _fetchProfile();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      if (_user == null) return;

      final Map<String, dynamic>? response = await supabase
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _displayName = response['display_name'] as String?;
          _avatarUrl = response['avatar_url'] as String?;
          _displayNameController.text = _displayName ?? '';
        });
      } else {
        await _createProfile();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        _showSnackBar('Gagal memuat profil: ${e.message}', isError: true);
      }
    }
  }

  Future<void> _createProfile() async {
    try {
      final user = supabase.auth.currentUser!;
      await supabase.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'display_name': user.email!.split('@')[0],
      });

      setState(() {
        _displayName = user.email!.split('@')[0];
        _displayNameController.text = _displayName!;
      });
      if (mounted) {
        _showSnackBar('Profil baru berhasil dibuat.', isError: false);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        _showSnackBar('Gagal membuat profil: ${e.message}', isError: true);
      }
    }
  }

  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text.trim();
    if (newPassword.isEmpty || newPassword.length < 6) {
      _showSnackBar('Kata sandi harus minimal 6 karakter', isError: true);
      return;
    }
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      if (mounted) {
        _showSnackBar('Kata sandi berhasil diperbarui!', isError: false);
        _newPasswordController.clear();
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showSnackBar(
          'Gagal memperbarui kata sandi: ${e.message}',
          isError: true,
        );
      }
    }
  }

  Future<void> _updateDisplayName() async {
    final newName = _displayNameController.text.trim();
    if (newName.isEmpty) {
      _showSnackBar('Nama tidak boleh kosong', isError: true);
      return;
    }
    try {
      await supabase
          .from('profiles')
          .update({'display_name': newName})
          .eq('id', _user!.id);

      setState(() {
        _displayName = newName;
      });
      if (mounted) {
        _showSnackBar('Nama berhasil diperbarui!', isError: false);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        _showSnackBar('Gagal memperbarui nama: ${e.message}', isError: true);
      }
    }
  }

  Future<void> _changeAvatar() async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedImage == null) return;

      final imageFile = File(pickedImage.path);
      final fileSize = await imageFile.length();
      if (fileSize > _maxFileSizeInBytes) {
        _showSnackBar(
          'Ukuran file terlalu besar (maksimum 5MB)',
          isError: true,
        );
        return;
      }

      setState(() => _isUploading = true);

      if (_avatarUrl != null) {
        final oldFileName = _avatarUrl!.split('/').last;
        await supabase.storage.from('avatars').remove([oldFileName]);
      }

      final fileName =
          '${_user!.id}/${DateTime.now().millisecondsSinceEpoch}.png';

      await supabase.storage.from('avatars').upload(fileName, imageFile);
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      await supabase
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', _user!.id);

      setState(() {
        _avatarUrl = publicUrl;
        _isUploading = false;
      });

      if (mounted) {
        _showSnackBar('Foto profil berhasil diperbarui!', isError: false);
      }
    } on StorageException catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showSnackBar('Gagal mengunggah foto: ${e.message}', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showSnackBar('Terjadi kesalahan: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showSnackBar('Gagal keluar: ${e.message}', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                    child: Stack(
                      key: ValueKey(_avatarUrl ?? 'default'),
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.deepPurple,
                          backgroundImage: _avatarUrl != null
                              ? NetworkImage(_avatarUrl!)
                              : null,
                          child: _avatarUrl == null
                              ? const Icon(
                                  Icons.account_circle,
                                  size: 90,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        if (_isUploading)
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        Positioned(
                          bottom: -10,
                          right: -10,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.deepPurple,
                                size: 24,
                              ),
                              onPressed: _isUploading ? null : _changeAvatar,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _displayName ?? 'Pengguna Baru',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _user?.email ?? 'Tidak Ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ganti Nama Tampilan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _displayNameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Baru',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Colors.deepPurple,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _updateDisplayName,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Simpan Nama',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ganti Kata Sandi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi Baru',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Colors.deepPurple,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _updatePassword,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Perbarui Kata Sandi',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: const Text(
                      'Kelola Kategori',
                      style: TextStyle(fontSize: 18, color: Colors.deepPurple),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.deepPurple,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CategoriesPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Keluar', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    onHover: (hover) {
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
