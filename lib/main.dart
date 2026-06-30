import 'dart:async';

import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth/supabase_auth/supabase_user_provider.dart';
import 'auth/supabase_auth/auth_util.dart';

import 'backend/supabase/supabase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
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

/// This is the private State class that goes with NavBarPage.
class _NavBarPageState extends State<NavBarPage> {
  String _currentPageName = 'Home';
  late Widget? _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = {
      'Home': HomeWidget(),
      'Appointments':
          EncountersWidget(), // Changed from 'Encounters' to match label
      'PeriodTracker': PeriodTrackerWidget(), // Add PeriodTrackerWidget here
    };

    // Map the current page name to the tabs keys
    String pageKey = _currentPageName;
    if (_currentPageName == 'Period Tracker') {
      pageKey = 'PeriodTracker'; // Map the label to the key
    }

    final currentIndex = tabs.keys.toList().indexOf(pageKey);

    return Scaffold(
      resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
      body: _currentPage ?? tabs[pageKey],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => safeSetState(() {
          _currentPage = null;
          final pageName = tabs.keys.toList()[i];
          _currentPageName = pageName == 'PeriodTracker'
              ? 'Period Tracker'
              : pageName; // Store the label
        }),
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        selectedItemColor: FlutterFlowTheme.of(context).primary,
        unselectedItemColor: FlutterFlowTheme.of(context).secondaryText,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
              size: 24.0,
            ),
            activeIcon: Icon(
              Icons.home_rounded,
              size: 24.0,
            ),
            label: 'Home',
            tooltip: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_today,
              size: 24.0,
            ),
            activeIcon: Icon(
              Icons.calendar_month,
              size: 24.0,
            ),
            label: 'Appointments',
            tooltip: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.water_drop_outlined,
              size: 24.0,
            ),
            activeIcon: Icon(
              Icons.water_drop,
              size: 24.0,
            ),
            label: 'Period Tracker',
            tooltip: '',
          ),
        ],
      ),
    );
  }
}
