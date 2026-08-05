import 'package:flutter/material.dart';
import '../widgets/loading_widget.dart';
import '../widgets/primary_button.dart';

class ProcessingScreen extends StatelessWidget {
  const ProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Uses the reusable widget we built earlier to show the loader and message
            const LoadingWidget(message: 'Analyzing your crop...'),
            const SizedBox(height: 60),
            // A cheat button for today since we have no actual API delay
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: PrimaryButton(
                text: 'Simulate Complete',
                icon: Icons.fast_forward,
                onPressed: () => Navigator.pushReplacementNamed(context, '/result'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}