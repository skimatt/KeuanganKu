import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_3/models/expense.dart';
import 'package:intl/intl.dart';
import 'package:project_3/pages/reports_page.dart';
import 'package:project_3/pages/profile_page.dart';
import 'package:project_3/pages/add_expense_page.dart';
import 'package:project_3/pages/all_transactions_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Expense>> _expensesFuture;
  late Future<Map<String, dynamic>> _userProfileFuture;
  int _currentIndex = 0;
  double _totalMonthlyExpense = 0.0;
  Map<String, double> _categoryTotals = {};
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadData() {
    _expensesFuture = _fetchExpenses();
    _userProfileFuture = _fetchUserProfile();
  }

  Future<List<Expense>> _fetchExpenses() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      final response = await supabase
          .from('expenses')
          .select()
          .eq('user_id', user.id)
          .gte('created_at', firstDayOfMonth.toIso8601String())
          .lte('created_at', lastDayOfMonth.toIso8601String())
          .order('created_at', ascending: false);

      final List<dynamic> expenseData = response;
      final expenses = expenseData
          .map((json) => Expense.fromJson(json))
          .toList();

      double total = 0.0;
      Map<String, double> categoryTotals = {};

      for (var expense in expenses) {
        total += expense.amount;
        final category = expense.categoryName ?? 'Lainnya';
        categoryTotals[category] =
            (categoryTotals[category] ?? 0) + expense.amount;
      }

      setState(() {
        _totalMonthlyExpense = total;
        _categoryTotals = categoryTotals;
      });

      return expenses;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat pengeluaran: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return [];
    }
  }

  Future<Map<String, dynamic>> _fetchUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return {};
      }
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return response ?? {};
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat profil: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return {};
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _loadData();
    });
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal keluar: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _HomePage(
        onRefresh: _refreshDashboard,
        totalMonthlyExpense: _totalMonthlyExpense,
        categoryTotals: _categoryTotals,
        expensesFuture: _expensesFuture,
        userProfileFuture: _userProfileFuture,
        onSignOut: _signOut,
        pageController: _pageController,
        currentPageIndex: _currentPageIndex,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
      ),
      AllTransactionsPage(onRefresh: _refreshDashboard),
      const ReportsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final VoidCallback onSignOut;
  final double totalMonthlyExpense;
  final Map<String, double> categoryTotals;
  final Future<List<Expense>> expensesFuture;
  final Future<Map<String, dynamic>> userProfileFuture;
  final PageController pageController;
  final int currentPageIndex;
  final Function(int) onPageChanged;

  const _HomePage({
    required this.onRefresh,
    required this.onSignOut,
    required this.totalMonthlyExpense,
    required this.categoryTotals,
    required this.expensesFuture,
    required this.userProfileFuture,
    required this.pageController,
    required this.currentPageIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tips = [
      TipsCard(
        title: 'Hemat Pangkal Kaya',
        content: 'Buat anggaran bulanan untuk mengontrol pengeluaran Anda.',
        icon: Icons.lightbulb_outline,
        color: Colors.orange,
      ),
      TipsCard(
        title: 'Investasi Cerdas',
        content: 'Mulai investasi kecil-kecilan di reksa dana atau saham.',
        icon: Icons.trending_up,
        color: Colors.blue,
      ),
      TipsCard(
        title: 'Tinjau Laporanmu',
        content: 'Cek laporan pengeluaran bulananmu di halaman Laporan.',
        icon: Icons.analytics,
        color: Colors.teal,
      ),
      TipsCard(
        title: 'Kurangi Pengeluaran',
        content: 'Identifikasi dan potong pengeluaran yang tidak perlu.',
        icon: Icons.cut,
        color: Colors.redAccent,
      ),
    ];

    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.deepPurple,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight:
                  MediaQuery.of(context).size.height *
                  0.25, // Made more compact
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple,
                        const Color.fromARGB(255, 193, 73, 214),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 80, // Geser ke bawah dari atas
                        right: 15,
                        child: SvgPicture.asset(
                          'assets/svg/auth_decoration1.svg',
                          height: 180,
                          width: 80,
                        ),
                      ),

                      // Konten utama
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: FutureBuilder<Map<String, dynamic>>(
                            future: userProfileFuture,
                            builder: (context, snapshot) {
                              String displayName =
                                  snapshot.data?['display_name'] ?? 'Pengguna';
                              String? avatarUrl = snapshot.data?['avatar_url'];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const ProfilePage(),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            Hero(
                                              tag: 'profile_avatar',
                                              child: CircleAvatar(
                                                radius: 24,
                                                backgroundImage:
                                                    avatarUrl != null
                                                    ? NetworkImage(avatarUrl)
                                                    : null,
                                                child: avatarUrl == null
                                                    ? const Icon(
                                                        Icons.person,
                                                        color: Colors.white,
                                                        size: 28,
                                                      )
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Selamat Datang,',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  displayName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.logout,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        onPressed: onSignOut,
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'Pengeluaran Bulan Ini',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                      'Rp ${NumberFormat('#,##0', 'id_ID').format(totalMonthlyExpense)}',
                                      key: ValueKey(totalMonthlyExpense),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.all(
                      12.0,
                    ), // Reduced padding for compactness
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan Kategori',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (categoryTotals.isEmpty)
                          Card(
                            elevation: 4, // Increased elevation for modern look
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Center(
                                child: Text('Belum ada data kategori.'),
                              ),
                            ),
                          )
                        else
                          isWideScreen
                              ? GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 3,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  itemCount: categoryTotals.entries.length > 5
                                      ? 5
                                      : categoryTotals.entries.length,
                                  itemBuilder: (context, index) {
                                    final entry = categoryTotals.entries
                                        .toList()
                                        .sortedBy(
                                          (entry) => -entry.value,
                                        )[index];
                                    return CategoryBar(
                                      category: entry.key,
                                      amount: entry.value,
                                      total: totalMonthlyExpense,
                                    );
                                  },
                                )
                              : Column(
                                  children: categoryTotals.entries
                                      .toList()
                                      .sortedBy((entry) => -entry.value)
                                      .take(5)
                                      .map(
                                        (entry) => CategoryBar(
                                          category: entry.key,
                                          amount: entry.value,
                                          total: totalMonthlyExpense,
                                        ),
                                      )
                                      .toList(),
                                ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaksi Terbaru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    AllTransactionsPage(onRefresh: onRefresh),
                              ),
                            );
                          },
                          child: const Text(
                            'Lihat Semua',
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 250, // Slightly reduced height for compactness
                      child: FutureBuilder<List<Expense>>(
                        future: expensesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.deepPurple,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Center(
                                  child: Text('Belum ada pengeluaran.'),
                                ),
                              ),
                            );
                          }

                          final expenses = snapshot.data!.take(5).toList();

                          return ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              final expense = expenses[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 4, // Modern shadow
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ), // Compact padding
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.deepPurple.shade100,
                                    child: Icon(
                                      _getCategoryIcon(expense.categoryName),
                                      color: Colors.deepPurple,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    expense.description ?? 'Tanpa Deskripsi',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    DateFormat(
                                      'dd MMM yyyy, HH:mm',
                                    ).format(expense.createdAt),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Text(
                                    'Rp ${NumberFormat('#,##0', 'id_ID').format(expense.amount)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AllTransactionsPage(
                                              onRefresh: onRefresh,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tips Keuangan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160, // Compact height
                      child: PageView.builder(
                        controller: pageController,
                        onPageChanged: onPageChanged,
                        itemCount: tips.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: tips[index],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          tips.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: currentPageIndex == index ? 20.0 : 6.0,
                            height: 6.0,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3.0),
                              color: currentPageIndex == index
                                  ? Colors.deepPurple
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddExpensePage()),
            );
            onRefresh();
          },
          backgroundColor: Colors.deepPurple,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Tambah', style: TextStyle(color: Colors.white)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
}

class CategoryBar extends StatelessWidget {
  final String category;
  final double amount;
  final double total;

  const CategoryBar({
    required this.category,
    required this.amount,
    required this.total,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Compact
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Rp ${NumberFormat('#,##0', 'id_ID').format(amount)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                color: Colors.deepPurple,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TipsCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const TipsCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withAlpha((0.8 * 255).toInt()), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  List<T> sortedBy(Comparable Function(T) key) {
    return toList()..sort((a, b) => key(a).compareTo(key(b)));
  }
}
