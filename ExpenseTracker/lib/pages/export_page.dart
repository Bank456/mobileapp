import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class ExportPage extends StatefulWidget {
  final int userId; // ส่ง user_id มาด้วย
  const ExportPage({super.key, required this.userId});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  DateTimeRange? selectedDateRange;
  bool isLoading = false;
  List<dynamic> transactions = []; // เก็บข้อมูล transaction ที่ดึงมาแสดง

  Future<void> fetchTransactions() async {
    if (selectedDateRange == null) return;

    setState(() => isLoading = true);

    try {
      // ใส่ start_date และ end_date ใน query params ตาม backend ที่รองรับ
      final url = Uri.parse(
          'http://10.0.2.2:5000/transactions?user_id=${widget.userId}&start_date=${selectedDateRange!.start.toIso8601String()}&end_date=${selectedDateRange!.end.toIso8601String()}'
      );
      final response = await http.get(url);


      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          transactions = data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ดึงข้อมูลไม่สำเร็จ (${response.statusCode})")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> exportCSV() async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่มีข้อมูลให้ส่งออก")),
      );
      return;
    }

    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาอนุญาตการเข้าถึงไฟล์ก่อน")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final List<List<dynamic>> csvData = [
        ['วันที่', 'ประเภท', 'จำนวนเงิน', 'หัวข้อ', 'ประเภทหมวดหมู่', 'หมายเหตุ'],
        ...transactions.map((t) => [
          t['created_at'].toString().substring(0, 10),
          t['type'],
          t['amount'],
          t['title'],
          t['category'] ?? '',
          t['note'] ?? ''
        ])
      ];

      final csv = const ListToCsvConverter().convert(csvData);
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/expense_export.csv";
      final file = File(path);
      await file.writeAsString(csv);

      Share.shareXFiles([XFile(path)], text: 'ส่งออกรายงานรายรับรายจ่าย');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
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
      await fetchTransactions(); // โหลดข้อมูลทันทีหลังเลือกวันที่
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ส่งออกรายงาน")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(
                selectedDateRange == null
                    ? "เลือกช่วงเวลา"
                    : "${selectedDateRange!.start.toLocal().toString().substring(0, 10)} - ${selectedDateRange!.end.toLocal().toString().substring(0, 10)}",
              ),
              onPressed: selectDateRange,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: Text(isLoading ? "กำลังโหลด..." : "ส่งออกเป็น CSV"),
              onPressed: isLoading ? null : exportCSV,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: transactions.isEmpty
                  ? Center(child: Text(selectedDateRange == null ? "กรุณาเลือกช่วงเวลา" : "ไม่มีข้อมูลในช่วงเวลาที่เลือก"))
                  : ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final t = transactions[index];
                  return ListTile(
                    title: Text(t['title']),
                    subtitle: Text(
                        "${t['type']} | ${t['category'] ?? 'ไม่มีหมวดหมู่'} | วันที่: ${t['created_at'].substring(0, 10)}"),
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

