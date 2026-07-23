import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/components/branding/dawa_mom_logo.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';

import '/auth/base_auth_user_provider.dart';

import '/main.dart';
import '/features/profile/profile_completion_page.dart';
import '/features/settings/dawa_mom_settings_page.dart';
import '/features/auth/dawa_auth_pages.dart';
import '/features/learning/presentation/dawa_learning_detail_pages.dart';
import '/features/learning/presentation/dawa_library_page.dart';
import '/features/learning/presentation/dawa_quest_pages.dart';
import '/features/notifications/dawa_notifications_page.dart';
import '/features/onboarding/dawa_onboarding_page.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) =>
          appStateNotifier.loggedIn ? NavBarPage() : const DawaWelcomePage(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => appStateNotifier.loggedIn
              ? NavBarPage()
              : const DawaWelcomePage(),
        ),
        FFRoute(
          name: HomeWidget.routeName,
          path: HomeWidget.routePath,
          requireAuth: true,
          builder: (context, params) =>
              params.isEmpty ? NavBarPage(initialPage: 'Home') : HomeWidget(),
        ),
        FFRoute(
          name: LoginWidget.routeName,
          path: LoginWidget.routePath,
          builder: (context, params) => const DawaLoginPage(),
        ),
        FFRoute(
          name: RegisterWidget.routeName,
          path: RegisterWidget.routePath,
          builder: (context, params) => const DawaRegistrationPage(),
        ),
        FFRoute(
          name: CreateAccountWidget.routeName,
          path: CreateAccountWidget.routePath,
          requireAuth: true,
          builder: (context, params) => CreateAccountWidget(),
        ),
        FFRoute(
          name: ProfileWidget.routeName,
          path: ProfileWidget.routePath,
          requireAuth: true,
          builder: (context, params) => NavBarPage(initialPage: 'Settings'),
        ),
        FFRoute(
          name: DawaMomSettingsPage.routeName,
          path: DawaMomSettingsPage.routePath,
          requireAuth: true,
          builder: (context, params) => NavBarPage(initialPage: 'Settings'),
        ),
        FFRoute(
          name: PeriodTrackerWidget.routeName,
          path: PeriodTrackerWidget.routePath,
          requireAuth: true,
          builder: (context, params) =>
              NavBarPage(initialPage: 'PeriodTracker'),
        ),
        FFRoute(
          name: DawaLearnPage.routeName,
          path: DawaLearnPage.routePath,
          requireAuth: true,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'Learn')
              : const DawaLearnPage(),
        ),
        FFRoute(
          name: DawaArticlePage.routeName,
          path: DawaArticlePage.routePath,
          requireAuth: true,
          builder: (context, params) => const DawaArticlePage(),
        ),
        FFRoute(
          name: DawaMythFactPage.routeName,
          path: DawaMythFactPage.routePath,
          requireAuth: true,
          builder: (context, params) => const DawaMythFactPage(),
        ),
        FFRoute(
          name: DawaAudioLessonPage.routeName,
          path: DawaAudioLessonPage.routePath,
          requireAuth: true,
          builder: (context, params) => const DawaAudioLessonPage(),
        ),
        FFRoute(
          name: DawaPregnancyGuidesPage.routeName,
          path: DawaPregnancyGuidesPage.routePath,
          requireAuth: true,
          builder: (context, params) => const DawaPregnancyGuidesPage(),
        ),
        FFRoute(
          name: DawaPregnancyGuideDetailPage.routeName,
          path: DawaPregnancyGuideDetailPage.routePath,
          requireAuth: true,
          builder: (context, params) => DawaPregnancyGuideDetailPage(
            guideId: params.getParam('guideId', ParamType.String) ?? '',
          ),
        ),
        FFRoute(
          name: DawaLibraryPage.routeName,
          path: DawaLibraryPage.routePath,
          requireAuth: true,
          builder: (context, params) => const DawaLibraryPage(),
        ),
        FFRoute(
          name: DawaQuestHubPage.routeName,
          path: DawaQuestHubPage.routePath,
          requireAuth: true,
          builder: (context, params) => const DawaQuestHubPage(),
        ),
        FFRoute(
          name: DawaQuestModulePage.routeName,
          path: DawaQuestModulePage.routePath,
          requireAuth: true,
          builder: (context, params) => const DawaQuestModulePage(),
        ),
        FFRoute(
          name: DawaClinicLessonPage.routeName,
          path: DawaClinicLessonPage.routePath,
          requireAuth: true,
          builder: (context, params) => const DawaClinicLessonPage(),
        ),
        FFRoute(
          name: DawaQuestCheckpointPage.routeName,
          path: DawaQuestCheckpointPage.routePath,
          requireAuth: true,
          builder: (context, params) => const DawaQuestCheckpointPage(),
        ),
        FFRoute(
          name: DawaQuestCompletePage.routeName,
          path: DawaQuestCompletePage.routePath,
          requireAuth: true,
          builder: (context, params) => const DawaQuestCompletePage(),
        ),
        FFRoute(
          name: DawaNotificationsPage.routeName,
          path: DawaNotificationsPage.routePath,
          requireAuth: true,
          builder: (context, params) => const DawaNotificationsPage(),
        ),
        FFRoute(
          name: DawaOnboardingPage.routeName,
          path: DawaOnboardingPage.routePath,
          builder: (context, params) => const DawaOnboardingPage(),
        ),
        FFRoute(
          name: ProfileCompletionPage.routeName,
          path: ProfileCompletionPage.routePath,
          requireAuth: true,
          builder: (context, params) => const ProfileCompletionPage(),
        ),
        FFRoute(
          name: EncountersWidget.routeName,
          path: EncountersWidget.routePath,
          requireAuth: true,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'Encounters')
              : EncountersWidget(),
        ),
        FFRoute(
          name: EncounterDetailsWidget.routeName,
          path: EncounterDetailsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => EncounterDetailsWidget(
            encounterDets: params.getParam(
              'encounterDets',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['encounter'],
            ),
          ),
        ),
        FFRoute(
          name: EditProfileWidget.routeName,
          path: EditProfileWidget.routePath,
          requireAuth: true,
          builder: (context, params) => EditProfileWidget(
            motherDets: params.getParam(
              'motherDets',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['mother'],
            ),
          ),
        ),
        FFRoute(
          name: WeekWidget.routeName,
          path: WeekWidget.routePath,
          requireAuth: true,
          builder: (context, params) => WeekWidget(
            week: params.getParam(
              'week',
              ParamType.int,
            ),
          ),
        ),
        FFRoute(
          name: AppointmentDetailsWidget.routeName,
          path: AppointmentDetailsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AppointmentDetailsWidget(
            appointmentId: params.getParam(
              'appointmentId',
              ParamType.String,
            ),
            encounterDets: params.getParam(
              'encounterDets',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['encounter'],
            ),
          ),
        ),
        FFRoute(
          name: WelcomeWidget.routeName,
          path: WelcomeWidget.routePath,
          builder: (context, params) => const DawaWelcomePage(),
        ),
        FFRoute(
          name: ForgotPasswordWidget.routeName,
          path: ForgotPasswordWidget.routePath,
          builder: (context, params) => const DawaPasswordRecoveryPage(),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/register';
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = appStateNotifier.loading
              ? ColoredBox(
                  color: const Color(0xFFF1F4F8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const DawaMomLogo(
                          variant: DawaMomLogoVariant.authentication,
                          size: 180,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: const Color(0xFF1945CD),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(key: state.pageKey, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
