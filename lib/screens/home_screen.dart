import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'my_reports_screen.dart';
import 'report_problem_screen.dart';

/// Main container screen for SysWatch Mobile.
///
/// Shares the visual language of [LoginScreen] and [SplashScreen]:
/// - Radial gradient background wash using [ColorScheme]
/// - Custom SysWatch vitals mark header
/// - Polished user account menu with student identity badge
/// - Minimal modern bottom bar with crisp Build & My Reports icons
class HomeScreen extends StatefulWidget {
  final StudentUser user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  int _reportsRevision = 0;

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Icon(Icons.logout_rounded, size: 36, color: scheme.primary),
          title: const Text('Sign out of SysWatch?'),
          content: Text(
            'You will need to verify your email address again to sign back in.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13.5),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await ApiService.instance.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: Duration(
          milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 380,
        ),
      ),
      (_) => false,
    );
  }

  void _navigateToReports() {
    setState(() {
      _reportsRevision++;
      _index = 1;
    });
  }

  void _navigateToNewReport() {
    setState(() => _index = 0);
  }

  String get _userInitials {
    final name = widget.user.displayName.trim();
    if (name.isEmpty) return 'S';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, math.min(2, name.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final pages = <Widget>[
      ReportProblemScreen(
        onSubmitted: _navigateToReports,
      ),
      MyReportsScreen(
        key: ValueKey(_reportsRevision),
        onNewReportRequested: _navigateToNewReport,
      ),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: <Widget>[
          // Background ambient gradient wash matching LoginScreen
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.85),
                  radius: 1.1,
                  colors: <Color>[
                    scheme.primary.withValues(alpha: 0.08),
                    scheme.surface.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                _buildAppBar(scheme),
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: pages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 29,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              );
            }),
          ),
          child: NavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.transparent,
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.build_circle_outlined),
                selectedIcon: Icon(Icons.build_circle_rounded),
                label: 'Report',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment_rounded),
                label: 'My Reports',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header App Bar ────────────────────────────────────────────────────────
  Widget _buildAppBar(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.transparent,
      child: Row(
        children: <Widget>[
          // Brand logo mark
          SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.08),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.28),
                      width: 1.2,
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
                SizedBox(
                  width: 22,
                  height: 14,
                  child: CustomPaint(
                    painter: _HeaderTracePainter(line: scheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Screen Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _index == 0 ? 'Report a Problem' : 'My Reports',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'SYSWATCH MOBILE',
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // User Account Button & Dropdown
          _buildUserAccountButton(scheme),
        ],
      ),
    );
  }

  Widget _buildUserAccountButton(ColorScheme scheme) {
    return PopupMenuButton<String>(
      tooltip: 'Account Options',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      onSelected: (value) {
        if (value == 'logout') _logout();
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 20,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    _userInitials,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        widget.user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: <Widget>[
              Icon(Icons.logout_rounded, size: 20, color: scheme.error),
              const SizedBox(width: 12),
              Text(
                'Sign out',
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 13,
              backgroundColor: scheme.primary,
              child: Text(
                _userInitials,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini Header Trace Painter ───────────────────────────────────────────────
class _HeaderTracePainter extends CustomPainter {
  const _HeaderTracePainter({required this.line});

  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = h * 0.5;

    final path = Path()
      ..moveTo(0, mid)
      ..lineTo(w * 0.22, mid)
      ..lineTo(w * 0.31, mid - h * 0.2)
      ..lineTo(w * 0.40, mid + h * 0.15)
      ..lineTo(w * 0.50, mid - h * 0.45)
      ..lineTo(w * 0.60, mid + h * 0.35)
      ..lineTo(w * 0.69, mid)
      ..lineTo(w, mid);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = line,
    );
  }

  @override
  bool shouldRepaint(covariant _HeaderTracePainter old) => old.line != line;
}
