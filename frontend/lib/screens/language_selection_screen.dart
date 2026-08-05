import 'package:flutter/material.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Language'),
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.language, color: Colors.green),
            title: Text('English'),
            trailing: Icon(Icons.check_circle, color: Colors.green), // Pretend it's selected
          ),
          ListTile(
            leading: Icon(Icons.language, color: Colors.grey),
            title: Text('Hindi'),
          ),
          ListTile(
            leading: Icon(Icons.language, color: Colors.grey),
            title: Text('Marathi'),
          ),
          ListTile(
            leading: Icon(Icons.language, color: Colors.grey),
            title: Text('Tamil'),
          ),
        ],
      ),
    );
  }
}