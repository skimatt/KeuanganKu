import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_3/models/category.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Category>> _categoriesFuture;
  final TextEditingController _categoryNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchCategories();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  Future<List<Category>> _fetchCategories() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return [];
    }

    final response = await supabase
        .from('categories')
        .select()
        .eq('user_id', user.id)
        .order('name');

    final List<dynamic> categoryData = response;
    return categoryData.map((json) => Category.fromJson(json)).toList();
  }

  Future<int> _countExpensesForCategory(String categoryId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return 0;

    final response = await supabase
        .from('expenses')
        .select('count')
        .eq('user_id', user.id)
        .eq('category_id', categoryId);

    return (response[0]['count'] as int?) ?? 0;
  }

  Future<void> _addCategory() async {
    final categoryName = _categoryNameController.text.trim();
    if (categoryName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama kategori tidak boleh kosong!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('categories').insert({
        'name': categoryName,
        'user_id': userId,
      });

      _categoryNameController.clear();
      setState(() {
        _categoriesFuture = _fetchCategories();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil ditambahkan!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan kategori: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    final expenseCount = await _countExpensesForCategory(categoryId);
    if (expenseCount > 0) {
      _showDeleteWarningDialog(categoryId, expenseCount);
      return;
    }

    try {
      await supabase.from('categories').delete().eq('id', categoryId);

      setState(() {
        _categoriesFuture = _fetchCategories();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori dan pengeluaran terkait berhasil dihapus!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus kategori: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showDeleteWarningDialog(String categoryId, int expenseCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Peringatan: Penghapusan Fatal'),
        content: Text(
          'Kategori ini digunakan oleh $expenseCount pengeluaran. Menghapus kategori ini akan menghapus SEMUA pengeluaran terkait secara permanen! Apakah Anda yakin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batalkan', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCategory(categoryId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Kategori',
          style: TextStyle(color: Colors.white),
        ),
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
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: FutureBuilder<List<Category>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.deepPurple),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada kategori. Tambahkan yang baru!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final categories = snapshot.data!;

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _categoryNameController,
                              decoration: InputDecoration(
                                labelText: 'Nama Kategori Baru',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(
                                  Icons.category,
                                  color: Colors.deepPurple,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _addCategory,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: const Icon(Icons.add, size: 20),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.05,
                          ),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                              child: Card(
                                key: ValueKey(category.id),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  title: Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _deleteCategory(category.id),
                                    onHover: (hover) {
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
