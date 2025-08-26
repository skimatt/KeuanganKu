import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_3/models/expense.dart';
import 'package:project_3/pages/edit_expense_page.dart';
import 'package:intl/intl.dart';

class AllTransactionsPage extends StatefulWidget {
  final VoidCallback onRefresh;
  const AllTransactionsPage({super.key, required this.onRefresh});

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Expense>> _allExpensesFuture;

  @override
  void initState() {
    super.initState();
    _allExpensesFuture = _fetchAllExpenses();
  }

  Future<List<Expense>> _fetchAllExpenses() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return [];
    }

    final response = await supabase
        .from('expenses')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final List<dynamic> expenseData = response;
    return expenseData.map((json) => Expense.fromJson(json)).toList();
  }

  Future<void> _deleteExpense(String expenseId) async {
    try {
      await supabase.from('expenses').delete().eq('id', expenseId);

      setState(() {
        _allExpensesFuture = _fetchAllExpenses();
      });
      widget.onRefresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengeluaran berhasil dihapus!'),
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
            content: Text('Gagal menghapus pengeluaran: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(String expenseId) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Transaksi',
          style: TextStyle(color: Colors.deepPurple),
        ),
        content: const Text('Anda yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? categoryName) {
    switch (categoryName?.toLowerCase()) {
      case 'makanan':
        return Icons.restaurant;
      case 'transportasi':
        return Icons.directions_car;
      case 'belanja':
        return Icons.shopping_bag;
      case 'hiburan':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Semua Transaksi',
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
            child: FutureBuilder<List<Expense>>(
              future: _allExpensesFuture,
              key: ValueKey(_allExpensesFuture.hashCode),
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
                      'Belum ada pengeluaran.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final expenses = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width * 0.04,
                  ),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Dismissible(
                      key: Key(expense.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      onDismissed: (direction) {
                        // No action needed here, handled in confirmDismiss
                      },
                      confirmDismiss: (direction) async {
                        final shouldDelete =
                            await _showDeleteConfirmationDialog(expense.id);
                        if (shouldDelete == true) {
                          await _deleteExpense(expense.id);
                        }
                        return shouldDelete;
                      },
                      child: Card(
                        elevation: 8,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),

                            child: Icon(
                              _getCategoryIcon(expense.categoryName),
                              color: Colors.deepPurple,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            expense.description ?? 'Pengeluaran',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'dd MMM yyyy, HH:mm',
                            ).format(expense.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          trailing: Text(
                            'Rp ${NumberFormat('#,##0', 'id_ID').format(expense.amount)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.redAccent,
                            ),
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditExpensePage(expense: expense),
                              ),
                            );
                            setState(() {
                              _allExpensesFuture = _fetchAllExpenses();
                            });
                            widget.onRefresh();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
