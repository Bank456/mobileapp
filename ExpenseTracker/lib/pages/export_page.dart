import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class ExportPage extends StatefulWidget {
  final int userId;
  const ExportPage({super.key, required this.userId});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  DateTimeRange? selectedDateRange;
  bool isLoading = false;
  List<dynamic> transactions = [];

  Future<void> fetchTransactions() async {
    if (selectedDateRange == null) return;

    setState(() => isLoading = true);

    try {
      final startDateStr = selectedDateRange!.start.toIso8601String().substring(0, 10);
      final endDateStr = selectedDateRange!.end.toIso8601String().substring(0, 10);

      final url = Uri.parse(
          'http://10.0.2.2:5000/transactions?user_id=${widget.userId}&start_date=$startDateStr&end_date=$endDateStr'
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          transactions = data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ດຶງຂໍ້ມູນບໍ່ສຳເລັດ (${response.statusCode})")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ເກີດຂໍ້ຜິດພາດ: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> exportCSV() async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ບໍ່ມີຂໍ້ມູນ")),
      );
      return;
    }

    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ກະລຸນາອະນຸຍາດເຂົ້າເຖິງໄຟລ໌")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // สร้างข้อมูล CSV
      final List<List<dynamic>> csvData = [
        ['ວັນທີ', 'ປະເພດ', 'ຈຳນວນເງິນ', 'ຫົວຂໍ້', 'ໝວດໝູ່', 'ໝາຍເຫດ'],
        ...transactions.map((t) => [
          t['created_at'].toString().substring(0, 10),
          t['type'],
          t['amount'],
          t['title'],
          t['category'] ?? '',
          t['note'] ?? ''
        ])
      ];

      // รวมรายรับ รายจ่าย
      double totalIncome = 0;
      double totalExpense = 0;
      for (var t in transactions) {
        if (t['type'] == 'income') {
          totalIncome += t['amount'];
        } else if (t['type'] == 'expense') {
          totalExpense += t['amount'];
        }
      }
      final balance = totalIncome - totalExpense;

      // แทรกบรรทัดสรุปท้ายตาราง
      csvData.add([]);
      csvData.add(['ລວມລາຍຮັບ', '', '', '', '', '${totalIncome.toStringAsFixed(2)} ກີບ']);
      csvData.add(['ລວມລາຍຈ່າຍ', '', '', '', '', '${totalExpense.toStringAsFixed(2)} ກີບ']);
      csvData.add(['ຍອດຄົງເຫຼືອ', '', '', '', '', '${balance.toStringAsFixed(2)} ກີບ']);

      // เขียนไฟล์
      final csv = const ListToCsvConverter().convert(csvData);
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/expense_export.csv";
      final file = File(path);
      await file.writeAsString(csv);

      // แชร์ไฟล์
      Share.shareXFiles([XFile(path)], text: 'ສົ່ງອອກລາຍງານລາຍຮັບລາຍຈ່າຍ');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ເກີດຂໍ້ຜິດພາດ: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
      await fetchTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ສົ່ງອອກລາຍງານ")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(
                selectedDateRange == null
                    ? "ເລືອກວັນ"
                    : "${selectedDateRange!.start.toLocal().toString().substring(0, 10)} - ${selectedDateRange!.end.toLocal().toString().substring(0, 10)}",
              ),
              onPressed: selectDateRange,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: Text(isLoading ? "ກຳລັງດາວໂຫຼດ..." : "ສົ່ງອອກເປັນ CSV"),
              onPressed: isLoading ? null : exportCSV,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: transactions.isEmpty
                  ? Center(child: Text(selectedDateRange == null ? "ກະລຸນາເລືອກວັນ" : "ບໍ່ມີຂໍ້ມູນ"))
                  : ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final t = transactions[index];
                  return ListTile(
                    title: Text(t['title']),
                    subtitle: Text(
                        "${t['type']} | ${t['category'] ?? 'ບໍ່ມີໝວດໝູ່'} | ວັນທີ: ${t['created_at'].substring(0, 10)}"),
                    trailing: Text(t['amount'].toString()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
