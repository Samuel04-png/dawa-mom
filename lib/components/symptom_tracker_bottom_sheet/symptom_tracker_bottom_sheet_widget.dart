import 'package:flutter/material.dart';

class SymptomTrackerBottomSheetWidget extends StatelessWidget {
  const SymptomTrackerBottomSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('Symptom tracking is available from the Period Tracker.'),
      ),
    );
  }
}
