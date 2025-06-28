import 'package:flutter/material.dart';

class DrawerMenu extends StatelessWidget {
  final int userId;
  final String userName;
  final String userEmail;

  const DrawerMenu({
    super.key,
    required this.userId,
    this.userName = 'ผู้ใช้',
    this.userEmail = 'example@email.com',
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7, // กำหนดความกว้าง
      child: Column(
        children: [
          // ส่วนหัว Drawer
          UserAccountsDrawerHeader(
            accountName: Text(
              userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade800, Colors.blue.shade600],
              ),
            ),
          ),

          // เมนูหลัก
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildListTile(
                  context,
                  icon: Icons.home_filled,
                  title: 'Home',
                  route: '/dashboard',
                ),
                _buildListTile(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Summary graph',
                  route: '/summary',
                ),
                _buildListTile(
                  context,
                  icon: Icons.account_circle,
                  title: 'Profile',
                  route: '/profile',
                ),

                const Divider(height: 1, thickness: 1),
                _buildListTile(
                  context,
                  icon: Icons.folder_open,
                  title: 'Export',
                  route: '/export',
                ),

                _buildListTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'About',
                  route: '/AboutPage',
                ),
              ],
            ),
          ),

          // ส่วนล่าง - ปุ่มออกจากระบบ
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Log out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                      (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String route,
      }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.blue.shade800,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        Navigator.pop(context); // ปิด drawer ก่อนเปลี่ยนหน้า
        if (route == '/dashboard') {
          Navigator.pushReplacementNamed(context, route, arguments: userId);
        } else {
          Navigator.pushNamed(context, route, arguments: userId);
        }
      },
    );
  }
}