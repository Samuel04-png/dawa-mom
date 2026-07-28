import 'dart:async';

import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import '/localization/dawa_localized_material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth/supabase_auth/supabase_user_provider.dart';
import 'auth/supabase_auth/auth_util.dart';

import 'backend/supabase/supabase_config.dart';
import '/components/responsive/dawa_mom_responsive_shell.dart';
import '/features/onboarding/dawa_main_app_tour.dart';
import '/features/settings/dawa_mom_settings_page.dart';
import '/features/period_tracker/presentation/dawa_cycle_tracker_page.dart';
import '/features/appointments/presentation/dawa_care_page.dart';
import '/design_system/dawa_design_tokens.dart';
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
  await DawaLocaleController.instance.initialize();

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
  late final DawaLocaleController _localeController;

  @override
  void initState() {
    super.initState();

    _localeController = DawaLocaleController.instance
      ..addListener(_handleLocaleChanged);
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
    _localeController.removeListener(_handleLocaleChanged);
    _authFallbackTimer?.cancel();
    _userStreamSub?.cancel();
    _jwtTokenStreamSub?.cancel();
    authUserSub.cancel();
    super.dispose();
  }

  void _handleLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DawaMom',
      locale: _localeController.locale,
      scrollBehavior: MyAppScrollBehavior(),
      localizationsDelegates: [
        const DawaMaterialLocalizationsDelegate(),
        const DawaCupertinoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: DawaLanguages.locales,
      theme: DawaTheme.light().copyWith(
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      themeMode: ThemeMode.light,
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
      label: 'Track',
      icon: Icons.sync_rounded,
      selectedIcon: Icons.sync_rounded,
    ),
    DawaMomShellDestination(
      label: 'Care',
      icon: Icons.health_and_safety_outlined,
      selectedIcon: Icons.health_and_safety_rounded,
    ),
    DawaMomShellDestination(
      label: 'Learn',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
    ),
    DawaMomShellDestination(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  int _currentIndex = 0;
  Widget? _overridePage;
  bool _tourEligibilityChecked = false;
  bool _replayPending = false;
  late final MainAppTourService _tourService;
  late final DawaMainAppTourController _tourController;
  final GlobalKey _homeJourneyTourKey =
      GlobalKey(debugLabel: 'home journey tour target');
  final GlobalKey _rewardsTourKey =
      GlobalKey(debugLabel: 'rewards tour target');
  final GlobalKey _notificationsTourKey =
      GlobalKey(debugLabel: 'notifications tour target');
  late final List<GlobalKey> _navigationTourKeys = List.generate(
    _destinations.length,
    (index) =>
        GlobalKey(debugLabel: '${_destinations[index].label} tour target'),
  );

  @override
  void initState() {
    super.initState();
    _currentIndex = _indexForPage(widget.initialPage);
    _overridePage = widget.page;
    _tourService = MainAppTourService();
    _tourController = DawaMainAppTourController(
      service: _tourService,
      onStepChanged: _showTourStep,
    )..addListener(_tourStateChanged);
  }

  @override
  void dispose() {
    _tourController
      ..removeListener(_tourStateChanged)
      ..dispose();
    super.dispose();
  }

  void _tourStateChanged() {
    if (mounted) setState(() {});
  }

  void _handleHomeReady() {
    if (_replayPending) {
      _replayPending = false;
      _tourController.start(replay: true);
      return;
    }
    if (_tourController.active) {
      _tourController.refreshTarget();
      return;
    }
    _maybeStartMainTour();
  }

  Future<void> _maybeStartMainTour() async {
    if (_tourEligibilityChecked ||
        _overridePage != null ||
        _currentIndex != 0) {
      return;
    }
    _tourEligibilityChecked = true;
    final shouldShow = await _tourService.shouldShow();
    if (shouldShow && mounted && _overridePage == null && _currentIndex == 0) {
      _tourController.start();
    }
  }

  void _replayTour() {
    _replayPending = true;
    safeSetState(() {
      _overridePage = null;
      _currentIndex = 0;
    });
  }

  void _showTourStep(DawaMainAppTourStep step) {
    final index = dawaMainAppTourTabFor(step.target);
    if (!mounted) return;
    safeSetState(() {
      _overridePage = null;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final pages = <Widget>[
      HomeWidget(
        onDashboardReady: _handleHomeReady,
        journeyTourKey: _homeJourneyTourKey,
        rewardsTourKey: _rewardsTourKey,
        notificationsTourKey: _notificationsTourKey,
      ),
      const DawaCycleTrackerPage(),
      const DawaCarePage(),
      const DawaLearnPage(),
      const DawaMomSettingsPage(),
    ];
    final child = _overridePage ?? pages[_currentIndex];

    final shell = DawaMomResponsiveShell(
      currentIndex: _currentIndex,
      destinations: _destinations,
      navigationTargetKeys: _navigationTourKeys,
      onDestinationSelected: (index) => safeSetState(() {
        _overridePage = null;
        _currentIndex = index;
      }),
      onLogout: _confirmAndLogout,
      rudoChatBuilder: (rudoContext, rudoController) => AIChatModal(
        userPhoneNumber: currentPhoneNumber,
        userName: currentUserDisplayName.trim().isEmpty
            ? 'DawaMom member'
            : currentUserDisplayName.trim(),
        onClose: rudoController.close,
        onMinimize: rudoController.minimize,
      ),
      child: child,
    );
    return DawaMainAppTourScope(
      onReplay: _replayTour,
      child: Stack(
        children: [
          Positioned.fill(child: shell),
          if (_tourController.active)
            Positioned.fill(
              child: DawaMainAppTourOverlay(
                controller: _tourController,
                targetKeys: {
                  DawaMainAppTourTarget.homeJourney: _homeJourneyTourKey,
                  DawaMainAppTourTarget.track: _navigationTourKeys[1],
                  DawaMainAppTourTarget.care: _navigationTourKeys[2],
                  DawaMainAppTourTarget.learn: _navigationTourKeys[3],
                  DawaMainAppTourTarget.rewards: _rewardsTourKey,
                  DawaMainAppTourTarget.notifications: _notificationsTourKey,
                  DawaMainAppTourTarget.profile: _navigationTourKeys[4],
                },
              ),
            ),
        ],
      ),
    );
  }

  static int _indexForPage(String? page) {
    switch (page) {
      case 'Appointments':
      case 'Encounters':
      case 'Care':
        return 2;
      case 'PeriodTracker':
      case 'Period Tracker':
      case 'Track':
        return 1;
      case 'Learn':
        return 3;
      case 'Profile':
      case 'Settings':
        return 4;
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
