import 'package:flutter/material.dart';

class CycleInfoBottomSheetWidget extends StatelessWidget {
  const CycleInfoBottomSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'Cycle information is available from the Period Tracker info action.',
        ),
      ),
    );
  }
}
