import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});

  // Opens the default email app with prefilled details
  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'habithivee@gmail.com',
      query:
          'subject=${Uri.encodeComponent("Support Request")}&body=${Uri.encodeComponent("Hi Habit Hive Team,\n\nI need help with...")}',
    );

    try {
      bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email app.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Support"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.email, color: Colors.orange),
                title: const Text("Email: habithivee@gmail.com"),
                subtitle: const Text("Tap to contact us"),
                onTap: () => _sendEmail(context),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Common Issues:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "- App not loading\n- Unable to add or mark habit\n- Forgot password",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
