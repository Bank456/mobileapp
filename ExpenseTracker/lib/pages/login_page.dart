import 'package:flutter/material.dart';
import 'register_page.dart';
import 'package:expensetracker/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final result = await apiService.login(email, password);

      print('Login success: $result');

      // สมมติ result เป็น Map<String, dynamic> เช่น {'userId': 1, 'email': 'john@example.com'}
      final userId = result['userId'];

      if (userId != null) {
        // นำทางไป Dashboard พร้อมส่ง userId
        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: {'userId': userId},
        );
      } else {
        setState(() {
          _errorMessage = 'ข้อมูลผู้ใช้ไม่ครบถ้วน';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เข้าสู่ระบบ')),
      body: SingleChildScrollView(      // เพิ่มตรงนี้ เพื่อเลื่อนหน้าจอได้
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'อีเมล'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                obscureText: true,
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _login,
                child: const Text('เข้าสู่ระบบ'),
              ),

              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
