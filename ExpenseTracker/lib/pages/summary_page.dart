import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SummaryPage extends StatefulWidget {
  final int userId;

  const SummaryPage({super.key, required this.userId});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  List<Map<String, dynamic>> _categoryData = [];
  double _totalAmount = 0;
  String filterType = 'expense';
  DateTimeRange? selectedDateRange;
  bool _isLoading = false;
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "lo_LA");

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    if (selectedDateRange == null) return;

    setState(() => _isLoading = true);

    final startDate = selectedDateRange!.start.toIso8601String().substring(0, 10);
    final endDate = selectedDateRange!.end.toIso8601String().substring(0, 10);

    final baseUrl = 'http://10.0.2.2:5000/summary/expenses?user_id=${widget.userId}&start_date=$startDate&end_date=$endDate';

    try {
      if (filterType == 'all') {
        final incomeResp = await http.get(Uri.parse('$baseUrl&type=income'));
        final expenseResp = await http.get(Uri.parse('$baseUrl&type=expense'));

        if (incomeResp.statusCode == 200 && expenseResp.statusCode == 200) {
          final incomeData = jsonDecode(incomeResp.body);
          final expenseData = jsonDecode(expenseResp.body);

          final incomeTotal = (incomeData['total_expense'] as num?)?.toDouble() ?? 0.0;
          final expenseTotal = (expenseData['total_expense'] as num?)?.toDouble() ?? 0.0;

          final incomeList = (incomeData['by_category'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .map((e) => {...e, 'type': 'income', 'amount': (e['amount'] as num).toDouble()})
              .toList();

          final expenseList = (expenseData['by_category'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .map((e) => {...e, 'type': 'expense', 'amount': (e['amount'] as num).toDouble()})
              .toList();

          setState(() {
            _totalAmount = incomeTotal - expenseTotal;
            _categoryData = [...incomeList, ...expenseList];
            _categoryData.sort((a, b) => (b['amount'] as num).compareTo(a['amount'] as num));
          });
        } else {
          throw Exception('Failed to load data');
        }
      } else {
        final resp = await http.get(Uri.parse('$baseUrl&type=$filterType'));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final total = (data['total_expense'] as num?)?.toDouble() ?? 0.0;
          final categories = (data['by_category'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .map((e) => {...e, 'type': filterType, 'amount': (e['amount'] as num).toDouble()})
              .toList();

          setState(() {
            _totalAmount = total;
            _categoryData = categories;
            _categoryData.sort((a, b) => (b['amount'] as num).compareTo(a['amount'] as num));
          });
        } else {
          throw Exception('Failed to load data');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ມີຂໍ້ຜິດພາດ: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
      fetchSummary();
    }
  }

  Color getColor(String category, String type) {
    if (type == 'income') {
      switch (category) {
        case 'ເງິນເດືອນ':
          return const Color(0xFF81C784); // เขียวอ่อน สดใส
        case 'ໂບນັດ':
          return const Color(0xFF4CAF50); // เขียวกลาง
        case 'ລົງທຶນ':
          return const Color(0xFF388E3C); // เขียวเข้ม
        default:
          return const Color(0xFF66BB6A); // เขียวสดใสอีกแบบ
      }
    } else {
      switch (category) {
        case 'ອາຫານ':
          return const Color(0xFFFF8A65); // ส้มอมแดง
        case 'ການເດີນທາງ':
          return const Color(0xFFFF7043); // ส้มเข้ม
        case 'ບັນເທີງ':
          return const Color(0xFFE57373); // แดงอ่อน
        case 'ຄ່າເຊົ່າບ້ານ':
          return const Color(0xFFD32F2F); // แดงเข้ม
        case 'ສຸຂະພາບ':
          return const Color(0xFFFFCA28); // เหลืองสดใส
        default:
          return const Color(0xFFFFEB3B); // เหลืองอ่อน
      }
    }
  }


  String _getTotalLabel() {
    switch (filterType) {
      case 'income':
        return 'ລວມລາຍຮັບທັງໝົດ';
      case 'expense':
        return 'ລວມລາຍຈ່າຍທັງໝົດ';
      case 'all':
        return 'ຍອດລວມສຸດທິ';
      default:
        return 'ລວມທັງໝົດ';
    }
  }

  Widget _buildPieChart() {
    final total = _categoryData.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble().abs());

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        sections: _categoryData.map((item) {
          final percent = ((item['amount'] as num).toDouble().abs() / total) * 100;
          return PieChartSectionData(
            value: (item['amount'] as num).toDouble().abs(),
            title: '${percent.toStringAsFixed(0)}%',
            color: getColor(item['category'], item['type']),
            radius: 24,
            titleStyle: TextStyle(
              fontSize: percent < 5 ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> item) {
    final isIncome = item['type'] == 'income';
    final amount = (item['amount'] as num).toDouble();
    final total = _categoryData.fold(0.0, (sum, e) => sum + (e['amount'] as num).toDouble().abs());
    final percent = total > 0 ? ((amount.abs() / total) * 100).toStringAsFixed(0) : '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: getColor(item['category'], item['type']).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: getColor(item['category'], item['type']),
            size: 20,
          ),
        ),
        title: Text(
          item['category'],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          isIncome ? 'ລາຍຮັບ' : 'ລາຍຈ່າຍ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_currencyFormat.format(amount.abs())} ກີບ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isIncome ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateRangeText = selectedDateRange == null
        ? 'ເລືອກຊ່ວງວັນທີ'
        : '${DateFormat('dd MMM yyyy').format(selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(selectedDateRange!.end)}';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('ສະຫຼຸບລາຍຮັບ-ລາຍຈ່າຍ'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade800,
                Colors.blue.shade600,
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              'ກຳລັງໂຫຼດຂໍ້ມູນ...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Toggle Buttons
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ToggleButtons(
                        isSelected: [
                          filterType == 'all',
                          filterType == 'income',
                          filterType == 'expense',
                        ],
                        onPressed: (index) {
                          setState(() {
                            filterType = ['all', 'income', 'expense'][index];
                          });
                          fetchSummary();
                        },
                        borderRadius: BorderRadius.circular(12),
                        selectedColor: Colors.white,
                        fillColor: Colors.blue.shade700,
                        color: Colors.grey.shade700,
                        constraints: const BoxConstraints(
                          minHeight: 40,
                          minWidth: 80,
                        ),
                        children: const [
                          Text("ທັງໝົດ", style: TextStyle(fontWeight: FontWeight.w500)),
                          Text("ລາຍຮັບ", style: TextStyle(fontWeight: FontWeight.w500)),
                          Text("ລາຍຈ່າຍ", style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Date Picker Button
                    InkWell(
                      onTap: pickDateRange,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateRangeText,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Data Display
            if (_categoryData.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insert_chart_outlined,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ບໍ່ມີຂໍ້ມູນໃນຊ່ວງນີ້',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: fetchSummary,
                  color: Colors.blue,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // Summary Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                _getTotalLabel(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_currencyFormat.format(_totalAmount.abs())} ກີບ',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: _totalAmount >= 0
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFF44336),
                                ),
                              ),
                              if (filterType == 'all') ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 16,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    Text(
                                      'ລາຍຮັບ: ${_currencyFormat.format(_categoryData.where((e) => e['type'] == 'income').fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble()))} ກີບ',
                                      style: TextStyle(
                                        color: const Color(0xFF4CAF50),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'ລາຍຈ່າຍ: ${_currencyFormat.format(_categoryData.where((e) => e['type'] == 'expense').fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble()))} ກີບ',
                                      style: TextStyle(
                                        color: const Color(0xFFF44336),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 220,
                                child: _buildPieChart(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'ໝວດໝູ່',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._categoryData.map((item) => _buildCategoryItem(item)).toList(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}