import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final int userId;

  const ProfilePage({required this.userId, super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = '';
  String email = '';
  bool loading = true;
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double balance = 0.0;
  String joinDate = '';

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    setState(() {
      loading = true;
    });

    try {
      final userUrl = 'http://10.0.2.2:5000/users/${widget.userId}';
      final summaryUrl = 'http://10.0.2.2:5000/users/${widget.userId}/summary';

      final [userResponse, summaryResponse] = await Future.wait([
        http.get(Uri.parse(userUrl)),
        http.get(Uri.parse(summaryUrl)),
      ]);

      if (userResponse.statusCode == 200 && summaryResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        final summaryData = json.decode(summaryResponse.body);

        setState(() {
          username = userData['username'] ?? '';
          email = userData['email'] ?? '';
          totalIncome = summaryData['total_income']?.toDouble() ?? 0.0;
          totalExpense = summaryData['total_expense']?.toDouble() ?? 0.0;
          balance = summaryData['balance']?.toDouble() ?? 0.0;
          joinDate = userData['created_at'] != null
              ? DateFormat('dd MMM yyyy').format(DateTime.parse(userData['created_at']))
              : '';
          loading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void goToChangePassword() {
    Navigator.pushNamed(context, '/change-password', arguments: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ส่วนโปรไฟล์
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.blue.shade400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            username.isNotEmpty ? username[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (joinDate.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'สมัครสมาชิกเมื่อ $joinDate',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // สรุปการเงิน
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ສະຫຼຸບການເງິນ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFinanceItem(
                    icon: Icons.arrow_downward,
                    color: Colors.green,
                    title: 'ລາຍຮັບທັງໝົດ',
                    amount: totalIncome,
                  ),
                  _buildFinanceItem(
                    icon: Icons.arrow_upward,
                    color: Colors.red,
                    title: 'ລາຍຈ່າຍທັງໝົດ',
                    amount: totalExpense,
                  ),
                  const Divider(height: 24, thickness: 1),
                  _buildFinanceItem(
                    icon: Icons.account_balance_wallet,
                    color: balance >= 0 ? Colors.green : Colors.red,
                    title: 'ຍອດຄົງເຫຼືອ',
                    amount: balance,
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ปุ่มดำเนินการ
            Column(
              children: [
                _buildActionButton(
                  icon: Icons.lock_outline,
                  text: 'ປ່ຽນລະຫັດ',
                  onTap: goToChangePassword,
                ),

                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.logout,
                  text: 'ອອກຈາກລະບົບ',
                  color: Colors.red,
                  onTap: logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceItem({
    required IconData icon,
    required Color color,
    required String title,
    required double amount,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${NumberFormat('#,###.##').format(amount)} ກີບ',
                  style: TextStyle(
                    fontSize: isTotal ? 18 : 16,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    color: isTotal ? color : Colors.black,
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color == Colors.red ? color : Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}