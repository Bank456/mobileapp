import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/drawer_menu.dart';
import 'package:intl/intl.dart'; // สำหรับการจัดรูปแบบวันที่

class DashboardPage extends StatefulWidget {
  final int userId;

  const DashboardPage({required this.userId, super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List transactions = [];
  bool loading = true;
  String filterType = 'all'; // all, income, expense
  DateTimeRange? selectedDateRange; // เปลี่ยนจาก DateTime? เป็น DateTimeRange?
  double totalIncome = 0;
  double totalExpense = 0;

  String userName = '';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    fetchUserInfo();
    fetchTransactions();
  }

  Future<void> fetchUserInfo() async {
    final url = 'http://10.0.2.2:5000/user/${widget.userId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userName = data['username'];
          userEmail = data['email'];
        });
      } else {
        print('โหลดข้อมูลผู้ใช้ล้มเหลว: ${response.body}');
      }
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> fetchTransactions() async {
    setState(() {
      loading = true;
    });

    try {
      String baseUrl = 'http://10.0.2.2:5000/transactions?user_id=${widget.userId}';

      if (filterType != 'all') {
        baseUrl += '&type=$filterType';
      }

      if (selectedDateRange != null) {
        final startStr = selectedDateRange!.start.toIso8601String().substring(0, 10);
        final endStr = selectedDateRange!.end.toIso8601String().substring(0, 10);
        baseUrl += '&start_date=$startStr&end_date=$endStr';
      }

      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // คำนวณยอดรวม
        double income = 0;
        double expense = 0;
        for (var item in data) {
          if (item['type'] == 'income') {
            income += (item['amount'] as num).toDouble();
          } else {
            expense += (item['amount'] as num).toDouble();
          }
        }

        setState(() {
          transactions = data;
          totalIncome = income;
          totalExpense = expense;
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void goToAddTransaction() {
    Navigator.pushNamed(context, '/add-transaction', arguments: widget.userId)
        .then((_) => fetchTransactions());
  }

  void goToEditTransaction(int transactionId) {
    Navigator.pushNamed(context, '/edit-transaction', arguments: transactionId)
        .then((_) => fetchTransactions());
  }

  void setFilter(String type) {
    setState(() {
      filterType = type;
    });
    fetchTransactions();
  }

  // ฟังก์ชันเลื่อนช่วงวันที่ (เลื่อนทั้งช่วงไปข้างหน้า/ข้างหลัง)
  void changeDateRange(int days) {
    if (selectedDateRange == null) return;
    setState(() {
      selectedDateRange = DateTimeRange(
        start: selectedDateRange!.start.add(Duration(days: days)),
        end: selectedDateRange!.end.add(Duration(days: days)),
      );
    });
    fetchTransactions();
  }

  // ฟังก์ชันเลือกช่วงวันที่ด้วย DateRangePicker
  Future<void> pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade800,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade800,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
      fetchTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplay = selectedDateRange == null
        ? 'All Time'
        : '${DateFormat('MMM dd, yyyy').format(selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(selectedDateRange!.end)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Dashboard'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: userName.isEmpty || userEmail.isEmpty
          ? null
          : DrawerMenu(
        key: ValueKey('$userName-$userEmail'),
        userId: widget.userId,
        userName: userName,
        userEmail: userEmail,
      ),
      body: Column(
        children: [
          // Summary Cards & Date Range Picker
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Date Navigation: ปุ่มเลื่อนช่วงวัน + ปุ่มเลือกช่วงวัน
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => changeDateRange(-1),
                    ),
                    TextButton(
                      onPressed: pickDateRange,
                      child: Text(
                        dateDisplay,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () => changeDateRange(1),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'ລາຍຮັບ',
                        totalIncome,
                        Colors.green.shade400,
                        Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        'ລາຍຈ່າຍ',
                        totalExpense,
                        Colors.red.shade400,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        'ທັງໝົດ',
                        totalIncome - totalExpense,
                        (totalIncome - totalExpense) >= 0
                            ? Colors.green.shade400
                            : Colors.red.shade400,
                        (totalIncome - totalExpense) >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterButton('ທັງໝົດ', filterType == 'all', () => setFilter('all')),
                _buildFilterButton('ລາຍຮັບ', filterType == 'income', () => setFilter('income')),
                _buildFilterButton('ລາຍຈ່າຍ', filterType == 'expense', () => setFilter('expense')),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (selectedDateRange != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedDateRange = null;
                      });
                      fetchTransactions();
                    },
                    child: const Text('Show all transactions'),
                  ),
              ],
            )
                : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final item = transactions[index];
                final isIncome = item['type'] == 'income';
                return _buildTransactionCard(item, isIncome);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: goToAddTransaction,
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${NumberFormat("#,##0", "en_US").format(amount)} kip',

              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue.shade800 : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(text),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> item, bool isIncome) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => goToEditTransaction(item['id']),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isIncome
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item['category'] ?? 'Uncategorized'} • ${DateFormat('MMM dd, HH:mm').format(DateTime.parse(item['created_at']))}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}฿${item['amount']}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
