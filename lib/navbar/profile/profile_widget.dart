import 'package:flutter/material.dart';

import '/features/settings/dawa_mom_settings_page.dart';

/// Backwards-compatible destination for links created before Profile was
/// consolidated into Settings.
class ProfileWidget extends StatelessWidget {
  const ProfileWidget({super.key});

  static const String routeName = 'Profile';
  static const String routePath = '/profile';

  @override
  Widget build(BuildContext context) => const DawaMomSettingsPage();
}
