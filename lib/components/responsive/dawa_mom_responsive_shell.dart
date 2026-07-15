import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/components/branding/dawa_mom_logo.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class DawaMomShellDestination {
  const DawaMomShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

enum RudoPanelState { closed, open, minimized }

class RudoAssistantController extends ChangeNotifier {
  RudoPanelState _state = RudoPanelState.closed;

  RudoPanelState get state => _state;
  bool get isOpen => _state == RudoPanelState.open;
  bool get isClosed => _state == RudoPanelState.closed;
  bool get isMinimized => _state == RudoPanelState.minimized;

  void open() => _setState(RudoPanelState.open);
  void close() => _setState(RudoPanelState.closed);
  void minimize() => _setState(RudoPanelState.minimized);
  void toggle() => isOpen ? close() : open();

  void _setState(RudoPanelState value) {
    if (_state == value) return;
    _state = value;
    notifyListeners();
  }
}

typedef RudoChatBuilder = Widget Function(
  BuildContext context,
  RudoAssistantController controller,
);

class DawaMomResponsiveShell extends StatefulWidget {
  const DawaMomResponsiveShell({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.onLogout,
    required this.child,
    this.rudoChatBuilder,
  });

  final int currentIndex;
  final List<DawaMomShellDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Future<void> Function() onLogout;
  final Widget child;
  final RudoChatBuilder? rudoChatBuilder;

  static RudoAssistantController? controllerOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_RudoAssistantScope>()?.controller;

  static void openRudo(BuildContext context) {
    controllerOf(context)?.open();
  }

  static void closeRudo(BuildContext context) {
    controllerOf(context)?.close();
  }

  static void minimizeRudo(BuildContext context) =>
      controllerOf(context)?.minimize();

  static void toggleRudo(BuildContext context) =>
      controllerOf(context)?.toggle();

  @override
  State<DawaMomResponsiveShell> createState() => _DawaMomResponsiveShellState();
}

class _DawaMomResponsiveShellState extends State<DawaMomResponsiveShell> {
  bool _sidebarCollapsed = false;
  late final RudoAssistantController _rudoController;
  final FocusNode _rudoFocusNode = FocusNode(debugLabel: 'Rudo chat panel');

  @override
  void initState() {
    super.initState();
    _rudoController = RudoAssistantController()
      ..addListener(_handleRudoChanged);
  }

  @override
  void dispose() {
    _rudoController
      ..removeListener(_handleRudoChanged)
      ..dispose();
    _rudoFocusNode.dispose();
    super.dispose();
  }

  void _handleRudoChanged() {
    if (!mounted) return;
    setState(() {});
    if (_rudoController.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rudoFocusNode.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    late final Widget shell;
    if (width < 700) {
      shell = _MobileShell(
        currentIndex: widget.currentIndex,
        destinations: widget.destinations,
        onDestinationSelected: widget.onDestinationSelected,
        child: widget.child,
      );
    } else if (width < 1100) {
      shell = _TabletShell(
        currentIndex: widget.currentIndex,
        destinations: widget.destinations,
        onDestinationSelected: widget.onDestinationSelected,
        onLogout: widget.onLogout,
        child: widget.child,
      );
    } else {
      shell = _DesktopShell(
        currentIndex: widget.currentIndex,
        destinations: widget.destinations,
        collapsed: _sidebarCollapsed,
        onToggleCollapsed: () => setState(
          () => _sidebarCollapsed = !_sidebarCollapsed,
        ),
        onDestinationSelected: widget.onDestinationSelected,
        onLogout: widget.onLogout,
        child: widget.child,
      );
    }

    return _RudoAssistantScope(
      controller: _rudoController,
      child: Stack(
        children: [
          Positioned.fill(child: shell),
          _buildRudoSurface(context),
          if (_rudoController.isClosed)
            Positioned(
              right: width < 700
                  ? 16
                  : width < 1100
                      ? 22
                      : 28,
              bottom: width < 700
                  ? 88
                  : width < 1100
                      ? 22
                      : 28,
              child: _RudoFloatingLauncher(onPressed: _rudoController.open),
            ),
          if (_rudoController.isMinimized)
            Positioned(
              right: width < 700 ? 16 : 28,
              bottom: width < 700 ? 88 : 28,
              child: _RudoMinimizedLauncher(
                onOpen: _rudoController.open,
                onClose: _rudoController.close,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRudoSurface(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final width = viewport.width;
    final height = viewport.height;
    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1100;
    final panelWidth = isMobile
        ? width
        : isTablet
            ? (width - 48).clamp(420.0, 500.0)
            : (width - 64).clamp(400.0, 450.0);
    final panelHeight = isMobile
        ? height
        : isTablet
            ? (height * 0.8).clamp(480.0, 680.0)
            : (height * 0.82).clamp(480.0, 700.0);
    final panelKey = ValueKey(
      isMobile
          ? 'rudo-mobile-panel'
          : isTablet
              ? 'rudo-tablet-panel'
              : 'rudo-desktop-panel',
    );
    final borderRadius = BorderRadius.circular(isMobile ? 0 : 22);

    return Positioned(
      right: isMobile
          ? 0
          : isTablet
              ? 22
              : 28,
      bottom: isMobile
          ? 0
          : isTablet
              ? 22
              : 28,
      width: panelWidth,
      height: panelHeight,
      child: Visibility(
        visible: _rudoController.isOpen,
        maintainState: true,
        maintainAnimation: true,
        child: IgnorePointer(
          ignoring: !_rudoController.isOpen,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _rudoController.isOpen ? 1 : 0,
            child: KeyboardListener(
              focusNode: _rudoFocusNode,
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  _rudoController.close();
                }
              },
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape):
                      _rudoController.close,
                },
                child: Semantics(
                  key: panelKey,
                  container: true,
                  label: 'Rudo assistant chat',
                  child: Material(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    elevation: isMobile ? 0 : 16,
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                    borderRadius: borderRadius,
                    clipBehavior: Clip.antiAlias,
                    child: widget.rudoChatBuilder
                            ?.call(context, _rudoController) ??
                        Center(
                          child: Text(
                            'Rudo is unavailable.',
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RudoAssistantScope extends InheritedWidget {
  const _RudoAssistantScope({
    required this.controller,
    required super.child,
  });

  final RudoAssistantController controller;

  @override
  bool updateShouldNotify(_RudoAssistantScope oldWidget) => false;
}

class _RudoMinimizedLauncher extends StatelessWidget {
  const _RudoMinimizedLauncher({
    required this.onOpen,
    required this.onClose,
  });

  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: theme.secondaryBackground,
      elevation: 8,
      borderRadius: BorderRadius.circular(999),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            key: const ValueKey('rudo-minimized-launcher'),
            onTap: onOpen,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/female-doctor.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Rudo', style: theme.bodyMedium),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close Rudo',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _RudoFloatingLauncher extends StatelessWidget {
  const _RudoFloatingLauncher({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;
    return Semantics(
      key: const ValueKey('rudo-launcher'),
      button: true,
      label: 'Ask Rudo',
      child: Tooltip(
        message: 'Ask Rudo',
        child: Material(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          elevation: 8,
          shadowColor: primary.withValues(alpha: 0.32),
          shape: const CircleBorder(),
          child: InkResponse(
            onTap: onPressed,
            radius: 34,
            hoverColor: primary.withValues(alpha: 0.08),
            focusColor: primary.withValues(alpha: 0.12),
            child: SizedBox.square(
              dimension: 62,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/female-doctor.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 5,
                    bottom: 7,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2EAD62),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.currentIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.child,
  });

  final int currentIndex;
  final List<DawaMomShellDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex >= 0 && currentIndex < destinations.length
            ? currentIndex
            : 0,
        onTap: onDestinationSelected,
        backgroundColor: theme.secondaryBackground,
        selectedItemColor: theme.primary,
        unselectedItemColor: theme.secondaryText,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: destinations
            .map(
              (destination) => BottomNavigationBarItem(
                icon: Icon(destination.icon),
                activeIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabletShell extends StatelessWidget {
  const _TabletShell({
    required this.currentIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.onLogout,
    required this.child,
  });

  final int currentIndex;
  final List<DawaMomShellDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Future<void> Function() onLogout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: Row(
        children: [
          SafeArea(
            right: false,
            child: Container(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                border: Border(right: BorderSide(color: theme.alternate)),
              ),
              child: NavigationRail(
                selectedIndex: currentIndex.clamp(0, destinations.length - 1),
                onDestinationSelected: onDestinationSelected,
                backgroundColor: theme.secondaryBackground,
                useIndicator: true,
                indicatorColor: theme.primary.withValues(alpha: 0.12),
                selectedIconTheme: IconThemeData(color: theme.primary),
                selectedLabelTextStyle: TextStyle(
                  color: theme.primary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                unselectedIconTheme: IconThemeData(color: theme.secondaryText),
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: const DawaMomLogo(
                    variant: DawaMomLogoVariant.compact,
                    size: 44,
                  ),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: IconButton(
                        tooltip: 'Logout',
                        onPressed: onLogout,
                        icon: const Icon(Icons.logout_rounded),
                      ),
                    ),
                  ),
                ),
                destinations: destinations
                    .map(
                      (destination) => NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Expanded(child: _ConstrainedShellBody(child: child)),
        ],
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.currentIndex,
    required this.destinations,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onDestinationSelected,
    required this.onLogout,
    required this.child,
  });

  final int currentIndex;
  final List<DawaMomShellDestination> destinations;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<int> onDestinationSelected;
  final Future<void> Function() onLogout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final sidebarWidth = collapsed ? 82.0 : 252.0;
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              border: Border(right: BorderSide(color: theme.alternate)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      collapsed ? 16 : 20,
                      18,
                      collapsed ? 16 : 12,
                      22,
                    ),
                    child: collapsed
                        ? const DawaMomLogo(
                            variant: DawaMomLogoVariant.compact,
                            size: 42,
                          )
                        : const SizedBox(
                            width: double.infinity,
                            child: DawaMomLogo(
                              variant: DawaMomLogoVariant.full,
                              size: 46,
                            ),
                          ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: destinations.length,
                      itemBuilder: (context, index) {
                        final item = destinations[index];
                        return _SidebarItem(
                          destination: item,
                          selected: currentIndex == index,
                          collapsed: collapsed,
                          onTap: () => onDestinationSelected(index),
                        );
                      },
                    ),
                  ),
                  _SidebarAction(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    collapsed: collapsed,
                    onTap: onLogout,
                  ),
                  const SizedBox(height: 8),
                  _SidebarAction(
                    icon: collapsed
                        ? Icons.keyboard_double_arrow_right_rounded
                        : Icons.keyboard_double_arrow_left_rounded,
                    label: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                    collapsed: collapsed,
                    onTap: onToggleCollapsed,
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          Expanded(child: _ConstrainedShellBody(child: child)),
        ],
      ),
    );
  }
}

class _ConstrainedShellBody extends StatelessWidget {
  const _ConstrainedShellBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1480),
          child: child,
        ),
      );
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final DawaMomShellDestination destination;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final item = Material(
      color:
          selected ? theme.primary.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: theme.primary.withValues(alpha: 0.06),
        focusColor: theme.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 0 : 13,
            vertical: 12,
          ),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: selected ? theme.primary : theme.secondaryText,
                size: 23,
              ),
              if (!collapsed) ...[
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    destination.label,
                    style: TextStyle(
                      color: selected ? theme.primary : theme.primaryText,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child:
          collapsed ? Tooltip(message: destination.label, child: item) : item,
    );
  }
}

class _SidebarAction extends StatelessWidget {
  const _SidebarAction({
    required this.icon,
    required this.label,
    required this.collapsed,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      hoverColor: theme.primary.withValues(alpha: 0.06),
      focusColor: theme.primary.withValues(alpha: 0.1),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 10 : 22,
          vertical: 11,
        ),
        child: Row(
          mainAxisAlignment:
              collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, color: theme.secondaryText, size: 22),
            if (!collapsed) ...[
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.primaryText,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return collapsed ? Tooltip(message: label, child: button) : button;
  }
}
