import 'dart:async';

import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth/supabase_auth/supabase_user_provider.dart';
import 'auth/supabase_auth/auth_util.dart';

import 'backend/supabase/supabase_config.dart';
import '/components/responsive/dawa_mom_responsive_shell.dart';
import '/features/onboarding/app_walkthrough_service.dart';
import '/features/onboarding/dawa_mom_walkthrough.dart';
import '/features/settings/dawa_mom_settings_page.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/navbar/home/home_widget.dart' show AIChatModal;
import 'flutter_flow/flutter_flow_util.dart';
import 'index.dart';
import 'dawa_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await initSupabase();

  await FlutterFlowTheme.initialize();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class MyAppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;
  static const bool _skipSplash =
      bool.fromEnvironment('SKIP_SPLASH', defaultValue: false);
  bool _showSplash = !_skipSplash;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();

  StreamSubscription<BaseAuthUser>? _userStreamSub;
  StreamSubscription<dynamic>? _jwtTokenStreamSub;
  Timer? _authFallbackTimer;
  final authUserSub = authenticatedUserStream.listen((_) {});

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    if (_skipSplash) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _appStateNotifier.stopShowingSplashImage();
      });
    }

    _authFallbackTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _appStateNotifier.user == null) {
        _appStateNotifier.update(DawaMomSupabaseUser(null));
      }
    });

    _userStreamSub = dawaMomSupabaseUserStream().listen(
      (user) {
        _authFallbackTimer?.cancel();
        if (!user.loggedIn) {
          FFAppState().motherRef = null;
        }
        _appStateNotifier.update(user);
      },
      onError: (error) {
        debugPrint('Auth state stream failed during startup: $error');
        if (mounted && _appStateNotifier.user == null) {
          _appStateNotifier.update(DawaMomSupabaseUser(null));
        }
      },
    );
    _jwtTokenStreamSub = jwtTokenStream.listen(
      (_) {},
      onError: (error) {
        debugPrint('JWT token stream failed during startup: $error');
      },
    );

    // Removed the 2-second delay logic since DawaSplashScreen
    // will handle its own timing based on video duration
  }

  @override
  void dispose() {
    _authFallbackTimer?.cancel();
    _userStreamSub?.cancel();
    _jwtTokenStreamSub?.cancel();
    authUserSub.cancel();
    super.dispose();
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DawaMom',
      scrollBehavior: MyAppScrollBehavior(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
      // Show DawaSplashScreen first, then the actual app
      builder: (context, child) {
        return _showSplash
            ? DawaSplashScreen(
                onAnimationComplete: () {
                  if (mounted) {
                    setState(() {
                      _showSplash = false;
                    });
                    // Notify app state that splash is complete
                    _appStateNotifier.stopShowingSplashImage();
                  }
                },
              )
            : (child ?? Container());
      },
    );
  }
}

class NavBarPage extends StatefulWidget {
  NavBarPage({
    Key? key,
    this.initialPage,
    this.page,
    this.disableResizeToAvoidBottomInset = false,
  }) : super(key: key);

  final String? initialPage;
  final Widget? page;
  final bool disableResizeToAvoidBottomInset;

  @override
  _NavBarPageState createState() => _NavBarPageState();
}

class _NavBarPageState extends State<NavBarPage> {
  static const _destinations = <DawaMomShellDestination>[
    DawaMomShellDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    DawaMomShellDestination(
      label: 'Appointments',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_month_rounded,
    ),
    DawaMomShellDestination(
      label: 'Period Tracker',
      icon: Icons.water_drop_outlined,
      selectedIcon: Icons.water_drop_rounded,
    ),
    DawaMomShellDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  int _currentIndex = 0;
  Widget? _overridePage;
  bool _walkthroughChecked = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = _indexForPage(widget.initialPage);
    _overridePage = widget.page;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeShowWalkthrough());
  }

  Future<void> _maybeShowWalkthrough() async {
    if (_walkthroughChecked) return;
    _walkthroughChecked = true;
    final shouldShow = await AppWalkthroughService().shouldShow();
    if (shouldShow && mounted) await showDawaMomWalkthrough(context);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final pages = <Widget>[
      HomeWidget(),
      EncountersWidget(),
      PeriodTrackerWidget(),
      const DawaMomSettingsPage(),
    ];
    final child = _overridePage ?? pages[_currentIndex];

    return DawaMomResponsiveShell(
      currentIndex: _currentIndex,
      destinations: _destinations,
      onDestinationSelected: (index) => safeSetState(() {
        _overridePage = null;
        _currentIndex = index;
      }),
      onLogout: _confirmAndLogout,
      rudoChatBuilder: (rudoContext, rudoController) => AIChatModal(
        userPhoneNumber: currentPhoneNumber,
        userName: currentUserDisplayName.trim().isEmpty
            ? 'Dawa Mom member'
            : currentUserDisplayName.trim(),
        onClose: rudoController.close,
        onMinimize: rudoController.minimize,
      ),
      child: child,
    );
  }

  static int _indexForPage(String? page) {
    switch (page) {
      case 'Appointments':
      case 'Encounters':
        return 1;
      case 'PeriodTracker':
      case 'Period Tracker':
        return 2;
      case 'Profile':
      case 'Settings':
        return 3;
      default:
        return 0;
    }
  }

  Future<void> _confirmAndLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    GoRouter.of(context).prepareAuthEvent();
    await authManager.signOut();
    if (!mounted) return;
    GoRouter.of(context).clearRedirectLocation();
    context.goNamedAuth(LoginWidget.routeName, context.mounted);
  }
}
