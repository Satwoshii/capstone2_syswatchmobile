import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import 'home_screen.dart';

/// Email + OTP sign-in.
///
/// Shares the visual language of the splash screen: colours come from
/// [ColorScheme] only, the vitals mark is reused, motion respects
/// `MediaQuery.disableAnimationsOf`, and every state change is announced
/// to screen readers.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();

  bool _loading = false;
  bool _otpSent = false;
  String? _errorMessage;

  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _emailFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────
  static final RegExp _allowedEmail = RegExp(
    r'^[A-Za-z0-9._%+-]+@(gmail\.com|students\.nu-clark\.edu\.ph)$',
  );

  bool _isAllowedEmail(String value) =>
      _allowedEmail.hasMatch(value.trim().toLowerCase());

  // ── Resend countdown ────────────────────────────────────────────────────
  void _startResendTimer(int seconds) {
    _resendTimer?.cancel();
    if (seconds <= 0) {
      setState(() => _resendSeconds = 0);
      return;
    }

    setState(() => _resendSeconds = seconds);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
        return;
      }
      setState(() => _resendSeconds--);
    });
  }

  String get _resendLabel {
    if (_resendSeconds <= 0) return 'Resend code';
    final m = _resendSeconds ~/ 60;
    final s = _resendSeconds % 60;
    return m > 0
        ? 'Resend in $m:${s.toString().padLeft(2, '0')}'
        : 'Resend in ${s}s';
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final result = await ApiService.instance.requestOtp(email);
      if (!mounted) return;

      _emailController.text = result.email;
      _otpController.clear();
      setState(() => _otpSent = true);
      _startResendTimer(result.resendAfterSeconds);

      // Land the caret where the user has to act next.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _otpFocus.requestFocus();
      });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Code sent to ${result.email}'),
          ),
        );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
      final retry = e.retryAfterSeconds;
      if (retry != null && retry > 0) _startResendTimer(retry);
    } catch (_) {
      if (!mounted) return;
      // Raw exception text is not something a student can act on.
      setState(() => _errorMessage =
      "Couldn't send the code. Check your connection and try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!(_otpFormKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = await ApiService.instance.verifyOtp(
        email: _emailController.text.trim().toLowerCase(),
        code: _otpController.text.trim(),
      );
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => HomeScreen(user: user),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: Duration(
            milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 380,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
      _otpController.clear();
      _otpFocus.requestFocus();
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage =
      "Couldn't verify the code. Check your connection and try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeEmail() {
    _resendTimer?.cancel();
    setState(() {
      _otpSent = false;
      _errorMessage = null;
      _resendSeconds = 0;
      _otpController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emailFocus.requestFocus();
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduced = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.75),
                  radius: 1.0,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _header(scheme),
                      const SizedBox(height: 26),
                      _card(scheme, reduced),
                      const SizedBox(height: 20),
                      _securityNote(scheme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header: mark + wordmark, outside the card ───────────────────────────
  Widget _header(ColorScheme scheme) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.28),
                    width: 1.4,
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              SizedBox(
                width: 50,
                height: 32,
                child: CustomPaint(painter: _TracePainter(line: scheme.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'SYSWATCH',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mobile Laboratory Reporter',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ── Card ────────────────────────────────────────────────────────────────
  Widget _card(ColorScheme scheme, bool reduced) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _stepHeading(scheme),
            const SizedBox(height: 20),
            _emailField(scheme),
            AnimatedSize(
              duration: Duration(milliseconds: reduced ? 0 : 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _otpSent ? _otpSection(scheme) : _sendSection(),
            ),
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 14),
              _errorBanner(scheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepHeading(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            _stepDot(scheme, filled: true),
            _stepRule(scheme, active: _otpSent),
            _stepDot(scheme, filled: _otpSent),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _otpSent ? 'Enter your code' : 'Sign in',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _otpSent
              ? 'We sent a 6-digit code to your inbox. It expires shortly.'
              : 'Use your NU Clark student email or a Gmail address. '
              "We'll send a one-time code.",
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _stepDot(ColorScheme scheme, {required bool filled}) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? scheme.primary : scheme.onSurface.withValues(alpha: 0.18),
      ),
    );
  }

  Widget _stepRule(ColorScheme scheme, {required bool active}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: active
            ? scheme.primary
            : scheme.onSurface.withValues(alpha: 0.12),
      ),
    );
  }

  // ── Step 1: email ───────────────────────────────────────────────────────
  Widget _emailField(ColorScheme scheme) {
    return Form(
      key: _emailFormKey,
      child: TextFormField(
        controller: _emailController,
        focusNode: _emailFocus,
        enabled: !_otpSent && !_loading,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        autofillHints: const <String>[AutofillHints.email],
        decoration: InputDecoration(
          labelText: 'Email address',
          hintText: 'name@students.nu-clark.edu.ph',
          prefixIcon: const Icon(Icons.alternate_email, size: 20),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // Keep the locked field legible rather than greyed into the card.
          suffixIcon: _otpSent
              ? Icon(Icons.lock_outline, size: 18, color: scheme.onSurfaceVariant)
              : null,
        ),
        validator: (value) {
          final email = (value ?? '').trim();
          if (email.isEmpty) return 'Enter your email address.';
          if (!_isAllowedEmail(email)) {
            return 'Use your NU Clark student email or a Gmail address.';
          }
          return null;
        },
        onFieldSubmitted: (_) {
          if (!_otpSent && !_loading) _sendOtp();
        },
      ),
    );
  }

  Widget _sendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 18),
        _primaryButton(
          label: 'Send code',
          icon: Icons.send_outlined,
          onPressed: _loading ? null : _sendOtp,
        ),
      ],
    );
  }

  // ── Step 2: code ────────────────────────────────────────────────────────
  Widget _otpSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _loading ? null : _changeEmail,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Change email'),
          ),
        ),
        const SizedBox(height: 4),
        Form(
          key: _otpFormKey,
          child: TextFormField(
            controller: _otpController,
            focusNode: _otpFocus,
            enabled: !_loading,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            textAlign: TextAlign.center,
            autofillHints: const <String>[AutofillHints.oneTimeCode],
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 26,
              letterSpacing: 10,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              labelText: 'Verification code',
              counterText: '',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              final otp = (value ?? '').trim();
              if (otp.isEmpty) return 'Enter the code from your email.';
              if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
                return 'The code is 6 digits.';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (!_loading) _verifyOtp();
            },
          ),
        ),
        const SizedBox(height: 14),
        _primaryButton(
          label: 'Verify and sign in',
          icon: Icons.verified_user_outlined,
          onPressed: _loading ? null : _verifyOtp,
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _loading || _resendSeconds > 0 ? null : _sendOtp,
          child: Text(_resendLabel),
        ),
      ],
    );
  }

  // ── Shared primary button, with the spinner inside it ───────────────────
  //
  // A separate progress indicator below the form left the pressed button
  // looking idle; putting the spinner in the button ties the wait to the
  // action that caused it and keeps the layout height stable.
  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _loading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 19),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error banner ────────────────────────────────────────────────────────
  Widget _errorBanner(ColorScheme scheme) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.error_outline, size: 18, color: scheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _securityNote(ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          Icons.shield_outlined,
          size: 15,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'SysWatch only asks for your email address and a one-time code. '
                'It never asks for your email password.',
            style: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Vitals mark ─────────────────────────────────────────────────────────────
//
// The static form of the splash screen's sweeping trace. If you keep both
// screens, move this into widgets/syswatch_mark.dart and import it in each
// rather than maintaining two copies.
class _TracePainter extends CustomPainter {
  const _TracePainter({required this.line});

  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = h * 0.5;

    final path = Path()
      ..moveTo(0, mid)
      ..lineTo(w * 0.22, mid)
      ..lineTo(w * 0.31, mid - h * 0.16)
      ..lineTo(w * 0.40, mid + h * 0.10)
      ..lineTo(w * 0.50, mid - h * 0.46)
      ..lineTo(w * 0.60, mid + h * 0.34)
      ..lineTo(w * 0.69, mid)
      ..lineTo(w, mid);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, w * 0.045)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = line,
    );
  }

  @override
  bool shouldRepaint(covariant _TracePainter old) => old.line != line;
}