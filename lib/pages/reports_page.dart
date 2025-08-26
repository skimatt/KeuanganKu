import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:project_3/models/expense.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final supabase = Supabase.instance.client;
  late Future<void> _fetchDataFuture;
  List<Expense> _expenses = [];
  Map<String, String> _categoryNames = {};
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = _fetchData();
  }

  Future<void> _fetchData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final firstDayOfMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
        1,
      );
      final lastDayOfMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
      );

      final responses = await Future.wait([
        supabase
            .from('expenses')
            .select()
            .eq('user_id', user.id)
            .gte('created_at', firstDayOfMonth.toIso8601String())
            .lte('created_at', lastDayOfMonth.toIso8601String()),
        supabase.from('categories').select().eq('user_id', user.id),
      ]);

      final List<dynamic> expenseData = responses[0];
      final List<dynamic> categoryData = responses[1];

      setState(() {
        _expenses = expenseData.map((json) => Expense.fromJson(json)).toList();
        _categoryNames = {
          for (var item in categoryData)
            item['id'] as String: item['name'] as String,
        };
      });
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      rethrow;
    }
  }

  Map<String, double> _groupExpensesByDay() {
    final Map<String, double> expensesByDay = {};
    for (var expense in _expenses) {
      final date = DateFormat('dd').format(expense.createdAt);
      expensesByDay.update(
        date,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return expensesByDay;
  }

  Map<String, double> _groupExpensesByCategory() {
    final Map<String, double> expensesByCategory = {};
    for (var expense in _expenses) {
      final categoryName =
          _categoryNames[expense.categoryId] ?? 'Tidak Diketahui';
      expensesByCategory.update(
        categoryName,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return expensesByCategory;
  }

  double _getTotalMonthlyExpense() {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  List<Color> _getCategoryColors(int count) {
    final List<Color> colors = [
      Colors.deepPurple,
      Colors.purpleAccent,
      Colors.indigo,
      Colors.blueAccent,
      Colors.teal,
    ];
    return List.generate(count, (index) => colors[index % colors.length]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Pengeluaran',
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
            child: FutureBuilder<void>(
              future: _fetchDataFuture,
              key: ValueKey(_selectedMonth),
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

                final expensesByDay = _groupExpensesByDay();
                final expensesByCategory = _groupExpensesByCategory();
                final totalExpense = _getTotalMonthlyExpense();

                return SingleChildScrollView(
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width * 0.05,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurple, Colors.purpleAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedMonth = DateTime(
                                    _selectedMonth.year,
                                    _selectedMonth.month - 1,
                                  );
                                  _fetchDataFuture = _fetchData();
                                });
                              },
                            ),
                            Text(
                              DateFormat(
                                'MMMM yyyy',
                                'id_ID',
                              ).format(_selectedMonth),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedMonth = DateTime(
                                    _selectedMonth.year,
                                    _selectedMonth.month + 1,
                                  );
                                  _fetchDataFuture = _fetchData();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.deepPurple,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Pengeluaran',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                'Rp ${NumberFormat('#,##0', 'id_ID').format(totalExpense)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (_expenses.isNotEmpty) ...[
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pengeluaran Bulanan (Harian)',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.3,
                                  child: LineChart(
                                    LineChartData(
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: true,
                                        getDrawingHorizontalLine: (value) {
                                          return FlLine(
                                            color: Colors.grey[300]!,
                                            strokeWidth: 0.5,
                                          );
                                        },
                                      ),
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 22,
                                            getTitlesWidget: (value, meta) {
                                              final day = value.toInt();
                                              return day <= expensesByDay.length
                                                  ? Text(
                                                      '$day',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    )
                                                  : const Text('');
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 28,
                                            getTitlesWidget: (value, meta) =>
                                                Text(
                                                  'Rp ${value.toInt()}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      minX: 1,
                                      maxX: 31,
                                      minY: 0,
                                      maxY: expensesByDay.values.isNotEmpty
                                          ? expensesByDay.values.reduce(
                                                  math.max,
                                                ) *
                                                1.2
                                          : 100,
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: expensesByDay.entries
                                              .map(
                                                (e) => FlSpot(
                                                  double.parse(e.key),
                                                  e.value,
                                                ),
                                              )
                                              .toList(),
                                          isCurved: true,
                                          color: Colors.deepPurple,
                                          barWidth: 3,
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.deepPurple.withAlpha(
                                                  128,
                                                ), // 0.5 * 255 = 127.5 dibulatkan ke 128
                                                Colors.transparent,
                                              ],

                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                          dotData: FlDotData(show: false),
                                        ),
                                      ],
                                      lineTouchData: LineTouchData(
                                        touchTooltipData: LineTouchTooltipData(
                                          tooltipBgColor: Colors.deepPurple
                                              .withAlpha(204),
                                          getTooltipItems: (touchedSpots) {
                                            return touchedSpots.map((spot) {
                                              final day = spot.x.toInt();
                                              final amount = spot.y;
                                              return LineTooltipItem(
                                                'Hari $day: Rp ${NumberFormat('#,##0', 'id_ID').format(amount)}\n',
                                                const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              );
                                            }).toList();
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pengeluaran per Kategori',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.3,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                      sections: List.generate(
                                        expensesByCategory.length,
                                        (index) {
                                          final entry = expensesByCategory
                                              .entries
                                              .elementAt(index);
                                          return PieChartSectionData(
                                            value: entry.value,
                                            title:
                                                '${entry.key}\nRp ${NumberFormat('#,##0', 'id_ID').format(entry.value)}',
                                            color: _getCategoryColors(
                                              expensesByCategory.length,
                                            )[index],
                                            radius: 80,
                                            titleStyle: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      ),
                                      pieTouchData: PieTouchData(
                                        touchCallback:
                                            (
                                              FlTouchEvent event,
                                              pieTouchResponse,
                                            ) {
                                              setState(() {
                                                if (!event
                                                        .isInterestedForInteractions ||
                                                    pieTouchResponse == null ||
                                                    pieTouchResponse
                                                            .touchedSection ==
                                                        null) {
                                                  return;
                                                }
                                              });
                                            },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 64.0),
                          child: Center(
                            child: Text(
                              'Tidak ada data pengeluaran pada bulan ini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
