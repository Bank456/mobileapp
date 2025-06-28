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
  DateTime? selectedDate;
  double totalIncome = 0;
  double totalExpense = 0;

  String userName = '';
  String userEmail = '';
  @override
  void initState() {
    super.initState();
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

      if (selectedDate != null) {
        final dateStr = selectedDate!.toIso8601String().split('T')[0];
        baseUrl += '&date=$dateStr';
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

  void changeDate(int days) {
    if (selectedDate == null) return;

    setState(() {
      selectedDate = selectedDate!.add(Duration(days: days));
    });
    fetchTransactions();
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      fetchTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplay = selectedDate == null
        ? 'All Time'
        : DateFormat('MMM dd, yyyy').format(selectedDate!);

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
          // Summary Cards
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
                // Date Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => changeDate(-1),
                    ),
                    TextButton(
                      onPressed: pickDate,
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
                      onPressed: () => changeDate(1),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Income',
                        totalIncome,
                        Colors.green.shade400,
                        Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        'Expense',
                        totalExpense,
                        Colors.red.shade400,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        'Balance',
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
                _buildFilterButton('All', filterType == 'all', () => setFilter('all')),
                _buildFilterButton('Income', filterType == 'income', () => setFilter('income')),
                _buildFilterButton('Expense', filterType == 'expense', () => setFilter('expense')),
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
                if (selectedDate != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedDate = null;
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
              '฿${amount.toStringAsFixed(2)}',
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