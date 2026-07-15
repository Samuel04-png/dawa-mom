import 'package:dawa_mom/components/responsive/dawa_mom_responsive_shell.dart';
import 'package:dawa_mom/components/branding/dawa_mom_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _destinations = [
  DawaMomShellDestination(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  DawaMomShellDestination(
    label: 'Appointments',
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_month,
  ),
  DawaMomShellDestination(
    label: 'Period Tracker',
    icon: Icons.water_drop_outlined,
    selectedIcon: Icons.water_drop,
  ),
  DawaMomShellDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];

Widget _shellAt(double width) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 900)),
      child: DawaMomResponsiveShell(
        key: ValueKey(width),
        currentIndex: 0,
        destinations: _destinations,
        onDestinationSelected: (_) {},
        onLogout: () async {},
        rudoChatBuilder: (_, controller) =>
            _StatefulRudoChat(controller: controller),
        child: const ColoredBox(
          color: Colors.white,
          child: Center(child: Text('Content')),
        ),
      ),
    ),
  );
}

void main() {
  test('Rudo controller exposes deterministic panel transitions', () {
    final controller = RudoAssistantController();

    controller.open();
    expect(controller.state, RudoPanelState.open);
    controller.minimize();
    expect(controller.state, RudoPanelState.minimized);
    controller.toggle();
    expect(controller.state, RudoPanelState.open);
    controller.toggle();
    expect(controller.state, RudoPanelState.closed);
    controller.dispose();
  });

  testWidgets('mobile keeps bottom navigation', (tester) async {
    await tester.pumpWidget(_shellAt(390));

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byKey(const ValueKey('rudo-launcher')), findsOneWidget);
  });

  testWidgets('tablet uses a navigation rail', (tester) async {
    await tester.pumpWidget(_shellAt(900));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byKey(const ValueKey('rudo-launcher')), findsOneWidget);
  });

  testWidgets('desktop uses the labelled collapsible sidebar', (tester) async {
    await tester.pumpWidget(_shellAt(1400));

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Appointments'), findsOneWidget);
    expect(find.text('Collapse sidebar'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    expect(find.byKey(const ValueKey('dawa-mom-logo-full')), findsOneWidget);
    expect(find.text('DAWA HEALTH'), findsNothing);
    final images = tester.widgetList<Image>(find.byType(Image));
    expect(
      images.any(
        (image) =>
            image.image is AssetImage &&
            (image.image as AssetImage).assetName == DawaMomLogo.crossAsset,
      ),
      isTrue,
    );
  });

  testWidgets('collapsed desktop sidebar uses the compact Dawa Mom logo',
      (tester) async {
    await tester.pumpWidget(_shellAt(1400));

    await tester.tap(find.text('Collapse sidebar'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('dawa-mom-logo-compact')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('dawa-mom-logo-full')), findsNothing);
  });

  testWidgets('Rudo uses bounded responsive panels and preserves chat state',
      (tester) async {
    for (final entry in <(double, String)>[
      (390, 'rudo-mobile-panel'),
      (900, 'rudo-tablet-panel'),
      (1400, 'rudo-desktop-panel'),
    ]) {
      await tester.pumpWidget(_shellAt(entry.$1));
      await tester.tap(find.byKey(const ValueKey('rudo-launcher')));
      await tester.pumpAndSettle();

      final panel = find.byKey(ValueKey(entry.$2));
      expect(panel, findsOneWidget);
      expect(find.byKey(const ValueKey('rudo-launcher')), findsNothing);
      final panelSize = tester.getSize(panel);
      if (entry.$1 == 390) {
        expect(panelSize.width, 390);
      } else {
        expect(panelSize.width, lessThanOrEqualTo(500));
        expect(panelSize.width, greaterThanOrEqualTo(400));
      }

      await tester.tap(find.byKey(const ValueKey('rudo-state-button')));
      await tester.pump();
      expect(find.text('Messages 1'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('rudo-close-button')));
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(find.byKey(const ValueKey('rudo-launcher')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rudo-launcher')));
      await tester.pumpAndSettle();
      expect(find.text('Messages 1'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(panel, findsNothing);

      await tester.tap(find.byKey(const ValueKey('rudo-launcher')));
      await tester.pumpAndSettle();
      expect(find.text('Messages 1'), findsOneWidget);
    }
  });

  testWidgets('responsive shell renders every required product breakpoint',
      (tester) async {
    for (final width in [390.0, 768.0, 1024.0, 1366.0, 1440.0]) {
      await tester.pumpWidget(_shellAt(width));
      await tester.pump();

      if (width < 700) {
        expect(find.byType(BottomNavigationBar), findsOneWidget,
            reason: 'Expected mobile navigation at $width px');
      } else if (width < 1100) {
        expect(find.byType(NavigationRail), findsOneWidget,
            reason: 'Expected tablet navigation at $width px');
      } else {
        expect(find.text('Collapse sidebar'), findsOneWidget,
            reason: 'Expected desktop sidebar at $width px');
      }
    }
  });
}

class _StatefulRudoChat extends StatefulWidget {
  const _StatefulRudoChat({required this.controller});

  final RudoAssistantController controller;

  @override
  State<_StatefulRudoChat> createState() => _StatefulRudoChatState();
}

class _StatefulRudoChatState extends State<_StatefulRudoChat> {
  int _messages = 0;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              key: const ValueKey('rudo-state-button'),
              onPressed: () => setState(() => _messages++),
              child: Text('Messages $_messages'),
            ),
            IconButton(
              key: const ValueKey('rudo-close-button'),
              onPressed: widget.controller.close,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      );
}
