import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/add_transaction_page.dart';
import 'pages/edit_transaction_page.dart';
import 'pages/profile_page.dart';  // import หน้าโปรไฟล์เข้ามา
import 'pages/change_password_page.dart';
import 'pages/summary_page.dart';
import 'pages/export_page.dart'; // เพิ่มบรรทัดนี้
import 'pages/AboutPage.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,

      // หน้าเริ่มต้น
      initialRoute: '/login',

      // กำหนด routes สำหรับ navigation ในแอป
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        // คุณสามารถเพิ่ม route แบบง่ายๆ ที่ไม่ต้องมี arguments ที่นี่ได้
      },

      // กรณีต้องการส่ง arguments (userId, transactionId, etc.) ให้ใช้ onGenerateRoute
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/dashboard':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
                builder: (_) => DashboardPage(userId: args['userId']));
          case '/add-transaction':
            final userId = settings.arguments as int;
            return MaterialPageRoute(
                builder: (_) => AddTransactionPage(userId: userId));
          case '/edit-transaction':
            final transactionId = settings.arguments as int;
            return MaterialPageRoute(
                builder: (_) => EditTransactionPage(transactionId: transactionId));
          case '/profile':  // เพิ่มกรณีนี้เข้าไป
            final userId = settings.arguments as int;
            return MaterialPageRoute(
                builder: (_) => ProfilePage(userId: userId));
          case '/change-password':
            final userId = settings.arguments as int;
            return MaterialPageRoute(
                builder: (_) => ChangePasswordPage(userId: userId));
          case '/summary':  // เพิ่มตรงนี้
            final userId = settings.arguments as int;
            return MaterialPageRoute(
                builder: (_) => SummaryPage(userId: userId));
          case '/export':
            final userId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => ExportPage(userId: userId));
          case '/AboutPage':
            return MaterialPageRoute(
              builder: (_) => const AboutPage(),
            );





          default:
            return null;
        }
      },
    );
  }
}
