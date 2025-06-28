import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class EditTransactionPage extends StatefulWidget {
  final int transactionId;

  const EditTransactionPage({super.key, required this.transactionId});

  @override
  _EditTransactionPageState createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'income';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categoriesIncome = ['เงินเดือน', 'โบนัส', 'ของขวัญ', 'ลงทุน', 'อื่นๆ'];
  final List<String> _categoriesExpense = ['อาหาร', 'เดินทาง', 'บันเทิง', 'ที่อยู่อาศัย', 'สุขภาพ', 'อื่นๆ'];

  bool _loading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _fetchTransaction();
  }

  Future<void> _fetchTransaction() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/transactions/${widget.transactionId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _titleController.text = data['title'];
          _amountController.text = data['amount'].toString();
          _type = data['type'];
          _selectedCategory = data['category'];
          _descriptionController.text = data['note'] ?? '';
          _selectedDate = DateTime.parse(data['created_at']);
          _loading = false;
        });
      } else {
        throw Exception('ไม่สามารถโหลดข้อมูลได้');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final amount = double.tryParse(_amountController.text.trim()) ?? 0;
      final note = _descriptionController.text.trim();

      final data = {
        'title': title,
        'amount': amount,
        'type': _type,
        'category': _selectedCategory ?? '',
        'note': note,
        'created_at': _selectedDate.toIso8601String(),
      };

      try {
        final response = await http.put(
          Uri.parse('http://10.0.2.2:5000/transactions/${widget.transactionId}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('อัปเดตรายการสำเร็จ'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('เกิดข้อผิดพลาดในการอัปเดต');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจว่าจะลบรายการนี้หรือไม่? การกระทำนี้ไม่สามารถยกเลิกได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);

      try {
        final response = await http.delete(
          Uri.parse('http://10.0.2.2:5000/transactions/${widget.transactionId}'),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ลบรายการสำเร็จ'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('เกิดข้อผิดพลาดในการลบ');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == 'income' ? _categoriesIncome : _categoriesExpense;
    final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขรายการ'),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ประเภทรายการ
              Text(
                'ประเภท',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('รายรับ'),
                      selected: _type == 'income',
                      onSelected: (selected) {
                        setState(() {
                          _type = 'income';
                          _selectedCategory = null;
                        });
                      },
                      selectedColor: Colors.green,
                      labelStyle: TextStyle(
                        color: _type == 'income' ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('รายจ่าย'),
                      selected: _type == 'expense',
                      onSelected: (selected) {
                        setState(() {
                          _type = 'expense';
                          _selectedCategory = null;
                        });
                      },
                      selectedColor: Colors.red,
                      labelStyle: TextStyle(
                        color: _type == 'expense' ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ชื่อรายการ
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'ชื่อรายการ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'กรุณากรอกชื่อรายการ' : null,
              ),
              const SizedBox(height: 20),

              // หมวดหมู่
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'หมวดหมู่',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                value: _selectedCategory,
                items: categories
                    .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                borderRadius: BorderRadius.circular(10),
                isExpanded: true,
              ),
              const SizedBox(height: 20),

              // จำนวนเงิน
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'จำนวนเงิน',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: 'บาท',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'กรุณากรอกจำนวนเงิน';
                  final n = double.tryParse(value);
                  if (n == null || n <= 0) return 'กรุณากรอกจำนวนเงินที่ถูกต้อง';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // คำอธิบาย
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'คำอธิบาย (ไม่บังคับ)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // วันที่
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'วันที่',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formattedDate),
                      const Icon(Icons.arrow_drop_down, size: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ปุ่มบันทึกและลบ
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'อัปเดตรายการ',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isDeleting ? null : _delete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: _isDeleting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'ลบรายการ',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}