import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AddTransactionPage extends StatefulWidget {
  final int userId;

  const AddTransactionPage({super.key, required this.userId});

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'income';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categoriesIncome = ['ເງິນເດືອນ', 'ໂບນັດ', 'ຂອງຂວັນ', 'ລົງທຶນ', 'ອື່ນໆ'];
  final List<String> _categoriesExpense = ['ອາຫານ', 'ການເດີນທາງ', 'ບັນເທີງ', 'ຄ່າເຊົ່າບ້ານ', 'ສຸຂະພາບ', 'ອື່ນໆ'];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final amount = double.tryParse(_amountController.text.trim()) ?? 0;
      final type = _type;
      final category = _selectedCategory ?? '';
      final note = _descriptionController.text.trim();
      final userId = widget.userId;

      final data = {
        'user_id': userId,
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'note': note,
        'created_at': _selectedDate.toIso8601String(),
      };

      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:5000/transactions'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ເພີ່ມສຳເລັດ'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          final res = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ຜິດພາດ: ${res['error'] ?? 'ບໍ່ສາມາດເພີ່ມລາຍການໄດ້'}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ເກີດຂໍ້ຜິດພາດ: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == 'income' ? _categoriesIncome : _categoriesExpense;
    final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ເພີ່ມລາຍການໃໝ່'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ประเภทรายการ
              Text(
                'ປະເພດ',
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
                      label: const Text('ລາຍຮັບ'),
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
                      label: const Text('ລາຍຈ່າຍ'),
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
                  labelText: 'ຊື່ລາຍການ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'ກະລຸນາໃສ່ຊື່ລາຍການ' : null,
              ),
              const SizedBox(height: 20),

              // หมวดหมู่
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'ປະເພດ',
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
                validator: (value) => value == null ? 'ກະລຸນາເລືອກປະເພດ' : null,
                borderRadius: BorderRadius.circular(10),
                isExpanded: true,
              ),
              const SizedBox(height: 20),

              // จำนวนเงิน
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'ຈຳນວນເງິນ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: 'ກີບ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'ກະລຸນາໃສ່ຈຳນວນເງິນ';
                  final n = double.tryParse(value);
                  if (n == null || n <= 0) return 'ກະລຸນາໃສ່ຈຳນວນເງິນທີ່ຖືກຕ້ອງ';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // คำอธิบาย
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'ຄຳອະທິບາຍ',
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
                    labelText: 'ວັນທີ',
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

              // ปุ่มบันทึก
              SizedBox(
                width: double.infinity,
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
                    'ບັນທຶກ',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}