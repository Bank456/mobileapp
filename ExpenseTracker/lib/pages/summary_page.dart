import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class SummaryPage extends StatefulWidget {
  final int userId;

  const SummaryPage({super.key, required this.userId});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  List<Map<String, dynamic>> _categoryData = [];
  double _totalExpense = 0;
  String _selectedMonth = '';
  String filterType = 'expense';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    fetchExpenseSummary();
  }

  Future<void> fetchExpenseSummary() async {
    final baseUrl = 'http://10.0.2.2:5000/summary/expenses?user_id=${widget.userId}&month=$_selectedMonth';

    if (filterType == 'all') {
      final incomeResp = await http.get(Uri.parse('$baseUrl&type=income'));
      final expenseResp = await http.get(Uri.parse('$baseUrl&type=expense'));
      if (incomeResp.statusCode == 200 && expenseResp.statusCode == 200) {
        final incomeData = jsonDecode(incomeResp.body);
        final expenseData = jsonDecode(expenseResp.body);
        final incomeTotal = double.tryParse(incomeData['total_expense'].toString()) ?? 0.0;
        final expenseTotal = double.tryParse(expenseData['total_expense'].toString()) ?? 0.0;

        final incomeList = List<Map<String, dynamic>>.from(incomeData['by_category']).map((e) {
          return {...e, 'type': 'income'};
        }).toList();

        final expenseList = List<Map<String, dynamic>>.from(expenseData['by_category']).map((e) {
          return {...e, 'type': 'expense'};
        }).toList();

        setState(() {
          _totalExpense = incomeTotal - expenseTotal;
          _categoryData = [...incomeList, ...expenseList];
          _categoryData.sort((a, b) => b['amount'].compareTo(a['amount']));
        });
      }
    } else {
      final response = await http.get(Uri.parse('$baseUrl&type=$filterType'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _totalExpense = double.tryParse(data['total_expense'].toString()) ?? 0.0;
          _categoryData = List<Map<String, dynamic>>.from(data['by_category']).map((e) {
            return {...e, 'type': filterType};
          }).toList();
          _categoryData.sort((a, b) => b['amount'].compareTo(a['amount']));
        });
      }
    }
  }

  Future<void> pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = "${picked.year}-${picked.month.toString().padLeft(2, '0')}";
      });
      fetchExpenseSummary();
    }
  }

  Color getColor(String category, String type) {
    if (type == 'income') {
      switch (category) {
        case 'เงินเดือน':
          return Colors.green.shade700;
        case 'โบนัส':
          return Colors.lightGreen;
        default:
          return Colors.teal;
      }
    } else {
      switch (category) {
        case 'อาหาร':
          return Colors.redAccent;
        case 'เดินทาง':
          return Colors.blue;
        case 'บันเทิง':
          return Colors.orange;
        case 'ค่าเช่าบ้าน':
          return Colors.brown;
        default:
          return Colors.grey;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สรุปรายรับรายจ่าย'),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ToggleButtons(
                      isSelected: [
                        filterType == 'all',
                        filterType == 'income',
                        filterType == 'expense',
                      ],
                      onPressed: (index) {
                        setState(() {
                          filterType = ['all', 'income', 'expense'][index];
                        });
                        fetchExpenseSummary();
                      },
                      borderRadius: BorderRadius.circular(12),
                      selectedColor: Colors.white,
                      fillColor: Colors.blue.shade800,
                      color: Colors.black87,
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("ทั้งหมด")),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("รายรับ")),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("รายจ่าย")),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: pickMonth,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedMonth,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Summary
            if (_totalExpense == 0)
              const Expanded(
                child: Center(child: Text('ไม่มีข้อมูลในเดือนนี้')),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'รวมทั้งหมด: ${_totalExpense.toStringAsFixed(2)} บาท',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  centerSpaceRadius: 50,
                                  sections: _categoryData.map((item) {
                                    final percent = (item['amount'] / _totalExpense.abs()) * 100;
                                    return PieChartSectionData(
                                      value: item['amount'],
                                      title: '${percent.toStringAsFixed(0)}%',
                                      color: getColor(item['category'], item['type']),
                                      titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                                      radius: 50,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'หมวดหมู่:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ..._categoryData.map((item) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Icon(Icons.circle,
                              color: getColor(item['category'], item['type']), size: 14),
                          title: Text(item['category']),
                          trailing: Text('${item['amount']} บาท'),
                        ),
                      );
                    }).toList()
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
