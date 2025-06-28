import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ຂໍ້ມູນຜູ້ພັດທະນາ")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "📱 Application: Expense Tracker",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              "👨‍💻 ຜູ້ພັດທະນາ: sss",
              style: TextStyle(fontSize: 18),
            ),
            Text(
              "👨‍💻 ຜູ້ພັດທະນາ: ",
              style: TextStyle(fontSize: 18),
            ),Text(
              "👨‍💻 ຜູ້ພັດທະນາ: ",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              "📧 Email: bank@example.com",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              "📝 Version: 1.0.0 (Demo)",
              style: TextStyle(fontSize: 18),
            ),
            Spacer(),
            Center(
              child: Text(
                "Version: 1.0.0 (Demo)",
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
