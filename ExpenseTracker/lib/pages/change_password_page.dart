import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChangePasswordPage extends StatefulWidget {
  final int userId;

  const ChangePasswordPage({required this.userId, super.key});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool loading = false;

  Future<void> changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ລະຫັດຜ່ານໃໝ່ກັບລະຫັດຜ່ານຢືນຢັນບໍ່ກົງກັນ')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // ✅ ປ່ຽນ URL ໃຫ້ກົງກັບ Flask API ຈິງ
      final url = 'http://10.0.2.2:5000/change-password/${widget.userId}';

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'old_password': oldPasswordController.text,
          'new_password': newPasswordController.text,
        }),
      );

      setState(() => loading = false);

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ປ່ຽນລະຫັດຜ່ານສຳເລັດ')),
        );
        Navigator.pop(context);
      } else {
        try {
          final data = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ລົ້ມເຫລວ: ${data['error'] ?? 'ເກີດຂໍ້ຜິດພາດ'}')),
          );
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ ບໍ່ສາມາດແປງຂໍ້ມູນໄດ້')),
          );
        }
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: $e')),
      );
    }
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ປ່ຽນລະຫັດຜ່ານ')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'ລະຫັດຜ່ານເກົ່າ'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ກະລຸນາໃສ່ລະຫັດຜ່ານເກົ່າ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'ລະຫັດຜ່ານໃໝ່'),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'ກະລຸນາໃສ່ລະຫັດຜ່ານໃໝ່ຢ່າງໜ້ອຍ 6 ຕົວອັກສອນ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'ຢືນຢັນລະຫັດຜ່ານໃໝ່'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ກະລຸນາຢືນຢັນລະຫັດຜ່ານໃໝ່';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: changePassword,
                child: const Text('ປ່ຽນລະຫັດຜ່ານ'),
              )
            ],
          ),
        ),
      ),
    );
  }
}