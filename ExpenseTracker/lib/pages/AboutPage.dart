import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ข้อมูลผู้พัฒนา")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "📱 แอปพลิเคชัน: Expense Tracker",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              "👨‍💻 ผู้พัฒนา: Bank Srithirath",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              "📧 อีเมล: bank@example.com",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              "📝 เวอร์ชัน: 1.0.0 (Demo)",
              style: TextStyle(fontSize: 18),
            ),
            Spacer(),
            Center(
              child: Text(
                "ขอบคุณที่ทดลองใช้งาน!",
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
