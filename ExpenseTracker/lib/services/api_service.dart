import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://10.0.2.2:5000';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      // decode safe check: response.body is not empty
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw 'Empty response body';
      }
    } else {
      // ถ้าบางกรณี response.body อาจจะไม่ใช่ JSON หรือว่าง
      try {
        final body = jsonDecode(response.body);
        final errorMessage = body['error'] ?? 'Login failed';
        throw errorMessage;
      } catch (_) {
        throw 'Login failed with status ${response.statusCode}';
      }
    }
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw 'Empty response body';
      }
    } else {
      try {
        final body = jsonDecode(response.body);
        final errorMessage = body['error'] ?? 'Register failed';
        throw errorMessage;
      } catch (_) {
        throw 'Register failed with status ${response.statusCode}';
      }
    }
  }
}
