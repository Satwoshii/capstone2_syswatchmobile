import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Splash / boot screen.
///
/// Design notes:
///  * Colours come from [ColorScheme] only — no hardcoded hex — so the screen
///    follows the app theme in both brightnesses.
///  * The status line is tied to real awaits, not a timer, so the text never
///    claims progress that has not happened.
///  * A minimum on-screen time stops the screen flashing when the session
///    restores instantly.
///  * Honours `MediaQuery.disableAnimationsOf` and exposes semantics for
///    screen readers.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Boot phases ─────────────────────────────────────────────────────────
  static const _labels = <String>[
    'Starting SysWatch',
    'Restoring your session',
    'Ready',
  ];

  int _phase = 0;
  Object? _error;

  /// Guards against the splash disappearing in a single frame.
  static const _minimumVisible = Duration(milliseconds: 1400);

  // ── Animation ───────────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final AnimationController _traceCtrl;
  late final AnimationController _barCtrl;

  late final Animation<double> _fade;
  late final Animation<double> _rise;
  late final Animation<double> _logoScale;

  bool _motionReduced = false;
  bool _startedOnce = false;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _rise = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack),
    );

    _traceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Motion preference is only readable once we have a MediaQuery.
    _motionReduced = MediaQuery.disableAnimationsOf(context);

    if (_startedOnce) return;
    _startedOnce = true;

    if (_motionReduced) {
      _entryCtrl.value = 1;
    } else {
      _entryCtrl.forward();
      _traceCtrl.repeat();
      _barCtrl.repeat();
    }

    _start();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _traceCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  // ── Boot sequence ───────────────────────────────────────────────────────
  Future<void> _start() async {
    final clock = Stopwatch()..start();

    try {
      await ApiService.instance.init();
      if (!mounted) return;
      setState(() => _phase = 1);

      final user = await ApiService.instance.restoreSession();
      if (!mounted) return;
      setState(() => _phase = 2);

      // Hold the splash for the remainder of the minimum, if any.
      final remaining = _minimumVisible - clock.elapsed;
      if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) =>
          user == null ? const LoginScreen() : HomeScreen(user: user),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: Duration(
            milliseconds: _motionReduced ? 0 : 420,
          ),
        ),
      );
    } catch (e) {
      // Without this the screen would spin forever on a failed init.
      if (!mounted) return;
      _traceCtrl.stop();
      _barCtrl.stop();
      setState(() => _error = e);
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _phase = 0;
    });
    if (!_motionReduced) {
      _traceCtrl.repeat();
      _barCtrl.repeat();
    }
    _start();
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: Stack(
          children: <Widget>[
            // Soft accent wash behind the mark, keyed to the theme.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.35),
                    radius: 0.95,
                    colors: <Color>[
                      scheme.primary.withValues(alpha: 0.10),
                      scheme.surface.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: AnimatedBuilder(
                      animation: _entryCtrl,
                      builder: (context, child) => Opacity(
                        opacity: _fade.value,
                        child: Transform.translate(
                          offset: Offset(0, _rise.value),
                          child: child,
                        ),
                      ),
                      child: _content(scheme),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(ColorScheme scheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ScaleTransition(scale: _logoScale, child: _mark(scheme)),
        const SizedBox(height: 28),
        Text(
          'SYSWATCH',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mobile Laboratory Reporter',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 40),
        if (_error == null) ...<Widget>[
          _bar(scheme),
          const SizedBox(height: 18),
          _status(scheme),
        ] else
          _errorBlock(scheme),
      ],
    );
  }

  // ── Logo: ring + sweeping vitals trace ──────────────────────────────────
  Widget _mark(ColorScheme scheme) {
    return SizedBox(
      width: 124,
      height: 124,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.28),
                width: 1.6,
              ),
            ),
          ),
          SizedBox(
            width: 74,
            height: 46,
            child: AnimatedBuilder(
              animation: _traceCtrl,
              builder: (context, _) => CustomPaint(
                painter: _TracePainter(
                  progress: _motionReduced ? 1 : _traceCtrl.value,
                  line: scheme.primary,
                  head: scheme.secondary,
                  showHead: !_motionReduced && _error == null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Indeterminate bar ───────────────────────────────────────────────────
  //
  // The two awaits have no measurable progress, so an indeterminate sweep is
  // the honest control here — a percentage would be invented.
  Widget _bar(ColorScheme scheme) {
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      value: _labels[_phase],
      child: ExcludeSemantics(
        child: SizedBox(
          height: 4,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: <Widget>[
                ColoredBox(
                  color: scheme.onSurface.withValues(alpha: 0.08),
                  child: const SizedBox.expand(),
                ),
                if (_motionReduced)
                  FractionallySizedBox(
                    widthFactor: 0.4,
                    child: ColoredBox(color: scheme.primary),
                  )
                else
                  AnimatedBuilder(
                    animation: _barCtrl,
                    builder: (context, _) {
                      // Ease the segment at both ends of its travel.
                      final t = Curves.easeInOut.transform(
                        (math.sin(_barCtrl.value * 2 * math.pi) + 1) / 2,
                      );
                      return Align(
                        alignment: Alignment(t * 2 - 1, 0),
                        child: FractionallySizedBox(
                          widthFactor: 0.38,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: <Color>[
                                  scheme.primary.withValues(alpha: 0),
                                  scheme.primary,
                                  scheme.primary.withValues(alpha: 0),
                                ],
                              ),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Status line ─────────────────────────────────────────────────────────
  //
  // Fixed height so a phase change never nudges the layout above it.
  Widget _status(ColorScheme scheme) {
    return SizedBox(
      height: 20,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: _motionReduced ? 0 : 260),
        child: Text(
          _labels[_phase],
          key: ValueKey<int>(_phase),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // ── Failure state ───────────────────────────────────────────────────────
  Widget _errorBlock(ColorScheme scheme) {
    return Column(
      children: <Widget>[
        Text(
          "Couldn't reach the SysWatch service.",
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.error, fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: 14),
        FilledButton.tonal(onPressed: _retry, child: const Text('Try again')),
      ],
    );
  }
}

// ── Vitals trace painter ────────────────────────────────────────────────────
//
// Draws a flat-line-with-a-beat path. The whole path sits faint underneath and
// a bright window sweeps along it, so the mark reads as a live monitor rather
// than a static icon. [progress] of 1 with [showHead] false renders the
// complete trace, which is what the reduced-motion and error states use.
class _TracePainter extends CustomPainter {
  _TracePainter({
    required this.progress,
    required this.line,
    required this.head,
    required this.showHead,
  });

  final double progress;
  final Color line;
  final Color head;
  final bool showHead;

  Path _trace(Size s) {
    final w = s.width;
    final h = s.height;
    final mid = h * 0.5;

    return Path()
      ..moveTo(0, mid)
      ..lineTo(w * 0.22, mid)
      ..lineTo(w * 0.31, mid - h * 0.16)
      ..lineTo(w * 0.40, mid + h * 0.10)
      ..lineTo(w * 0.50, mid - h * 0.46)
      ..lineTo(w * 0.60, mid + h * 0.34)
      ..lineTo(w * 0.69, mid)
      ..lineTo(w, mid);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _trace(size);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Ghost of the full trace.
    canvas.drawPath(path, stroke..color = line.withValues(alpha: 0.18));

    final metric = path.computeMetrics().first;
    final total = metric.length;
    final window = total * 0.42;

    // Travel far enough that the window fully enters and fully exits.
    final headPos = progress * (total + window);
    final start = math.max(0.0, headPos - window);
    final end = math.min(total, headPos);
    if (end <= start) return;

    canvas.drawPath(
      metric.extractPath(start, end),
      stroke..color = line,
    );

    if (!showHead) return;
    final tangent = metric.getTangentForOffset(end);
    if (tangent == null) return;
    canvas.drawCircle(
      tangent.position,
      3,
      Paint()
        ..style = PaintingStyle.fill
        ..color = head,
    );
  }

  @override
  bool shouldRepaint(covariant _TracePainter old) =>
      old.progress != progress ||
          old.line != line ||
          old.head != head ||
          old.showHead != showHead;
}