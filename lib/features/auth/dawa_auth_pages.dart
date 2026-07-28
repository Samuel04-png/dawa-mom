import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/branding/dawa_mom_logo.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/onboarding/app_walkthrough_service.dart';

class DawaAuthScaffold extends StatelessWidget {
  const DawaAuthScaffold({
    super.key,
    required this.child,
    this.showMotherLine = true,
    this.maxWidth = 510,
  });

  final Widget child;
  final bool showMotherLine;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DawaColors.canvas,
        body: Stack(
          children: [
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 155,
              child: IgnorePointer(
                child: CustomPaint(painter: DawaWavePainter()),
              ),
            ),
            if (showMotherLine)
              Positioned(
                right: DawaBreakpoints.isMobile(context) ? -34 : 24,
                bottom: 50,
                width: DawaBreakpoints.isMobile(context) ? 165 : 210,
                height: 235,
                child: Opacity(
                  opacity: 0.45,
                  child: Image.asset(
                    DawaArtwork.motherBabyLine,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    DawaBreakpoints.pagePadding(context),
                    26,
                    DawaBreakpoints.pagePadding(context),
                    120,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class DawaWelcomePage extends StatelessWidget {
  const DawaWelcomePage({super.key});

  static const routeName = 'DawaWelcome';
  static const routePath = '/welcome-new';

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DawaColors.canvas,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final width = constraints.maxWidth;
            final compact = height < 720;
            final contentWidth = width.clamp(0, 520).toDouble();
            return Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _DawaWelcomeBackgroundPainter()),
                Positioned(
                  right: width < 520 ? -18 : width * 0.08,
                  top: height * (compact ? 0.39 : 0.42),
                  width: contentWidth * (compact ? 0.50 : 0.58),
                  height: height * (compact ? 0.29 : 0.31),
                  child: Opacity(
                    opacity: 0.72,
                    child: Image.asset(
                      DawaArtwork.motherBabyLine,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          children: [
                            SizedBox(height: height * (compact ? 0.045 : 0.07)),
                            DawaMomLogo(
                              variant: DawaMomLogoVariant.iconOnly,
                              size: compact ? 72 : 86,
                              width: compact ? 72 : 86,
                              semanticLabel: 'DawaMom',
                            ),
                            SizedBox(height: compact ? 12 : 18),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'DawaMom',
                                style: context.dawaDisplay.copyWith(
                                  fontSize: compact ? 37 : 43,
                                  letterSpacing: -1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Icon(
                              Icons.favorite_rounded,
                              color: DawaColors.green,
                              size: 18,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Simple care for every mother',
                              textAlign: TextAlign.center,
                              style: context.dawaBody.copyWith(
                                color: DawaColors.muted,
                                fontSize: compact ? 14 : 16,
                              ),
                            ),
                            const Spacer(),
                            Semantics(
                              button: true,
                              label: 'Get started',
                              child: Material(
                                color: Colors.white,
                                elevation: 8,
                                shadowColor: DawaColors.primaryDark
                                    .withValues(alpha: .3),
                                borderRadius:
                                    BorderRadius.circular(DawaRadii.pill),
                                child: InkWell(
                                  onTap: () => context.go('/onboarding'),
                                  borderRadius:
                                      BorderRadius.circular(DawaRadii.pill),
                                  child: Container(
                                    height: 62,
                                    padding: const EdgeInsets.only(
                                      left: 25,
                                      right: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(DawaRadii.pill),
                                    ),
                                    child: Row(
                                      children: [
                                        const Spacer(),
                                        Text(
                                          'Get started',
                                          style:
                                              context.dawaSectionTitle.copyWith(
                                            color: DawaColors.primary,
                                            fontSize: 17,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          width: 49,
                                          height: 49,
                                          decoration: const BoxDecoration(
                                            color: DawaColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                minimumSize: const Size(44, 44),
                              ),
                              child: Text.rich(
                                TextSpan(
                                  text: 'Already have an account? ',
                                  children: const [
                                    TextSpan(
                                      text: 'Sign in',
                                      style: TextStyle(
                                        color: DawaColors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 2 : 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _DawaWelcomeBackgroundPainter extends CustomPainter {
  const _DawaWelcomeBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = DawaColors.canvas,
    );
    final path = Path()
      ..moveTo(0, size.height * .61)
      ..cubicTo(
        size.width * .22,
        size.height * .69,
        size.width * .37,
        size.height * .64,
        size.width * .53,
        size.height * .80,
      )
      ..cubicTo(
        size.width * .67,
        size.height * .92,
        size.width * .84,
        size.height * .72,
        size.width,
        size.height * .76,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = DawaColors.primary);

    final accent = Path()
      ..moveTo(0, size.height * .602)
      ..cubicTo(
        size.width * .22,
        size.height * .68,
        size.width * .38,
        size.height * .63,
        size.width * .54,
        size.height * .79,
      )
      ..cubicTo(
        size.width * .68,
        size.height * .90,
        size.width * .84,
        size.height * .71,
        size.width,
        size.height * .75,
      );
    canvas.drawPath(
      accent,
      Paint()
        ..color = DawaColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _DawaWelcomeBackgroundPainter oldDelegate) =>
      false;
}

class DawaLoginPage extends StatefulWidget {
  const DawaLoginPage({super.key});

  @override
  State<DawaLoginPage> createState() => _DawaLoginPageState();
}

class _DawaLoginPageState extends State<DawaLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _busy = true);
    final value = _identifier.text.trim();
    final user = value.contains('@')
        ? await authManager.signInWithEmail(context, value, _password.text)
        : await authManager.signInWithPhonePassword(
            context,
            normalizeZambianPhone(value),
            _password.text,
          );
    if (!mounted) return;
    setState(() => _busy = false);
    if (user == null) return;
    final shouldShow = await AppWalkthroughService().shouldShow();
    if (!mounted) return;
    context.go(shouldShow ? '/onboarding' : '/home');
  }

  @override
  Widget build(BuildContext context) => DawaAuthScaffold(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const DawaMomLogo(
                variant: DawaMomLogoVariant.authentication,
                size: 95,
                width: 120,
              ),
              const SizedBox(height: 30),
              Text(
                'Welcome back',
                style: context.dawaDisplay.copyWith(fontSize: 31),
              ),
              const SizedBox(height: 5),
              Text(
                'Log in with your email address\nor mobile number.',
                textAlign: TextAlign.center,
                style: context.dawaBody,
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const ValueKey('dawa-login-identifier'),
                controller: _identifier,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                  AutofillHints.telephoneNumber,
                ],
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Email or phone number',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.tr('Enter your email or phone number.')
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const ValueKey('dawa-login-password'),
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) => (value?.length ?? 0) < 6
                    ? context.tr('Enter your password.')
                    : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgotPassword'),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 82),
              DawaPrimaryButton(
                label: 'Log in',
                busy: _busy,
                onPressed: _login,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/register'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('New to DawaMom?  Create account'),
              ),
              const SizedBox(height: 7),
              const Text(
                '🔒  Your privacy matters. Your data is secured.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
        ),
      );
}

class DawaRegistrationPage extends StatefulWidget {
  const DawaRegistrationPage({super.key});

  @override
  State<DawaRegistrationPage> createState() => _DawaRegistrationPageState();
}

class _DawaRegistrationPageState extends State<DawaRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _phoneMode = false;
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _identifier.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _busy = true);
    final phone = _phoneMode ? normalizeZambianPhone(_identifier.text) : null;
    final user = _phoneMode
        ? await authManager.createAccountWithPhone(
            context,
            phone!,
            _password.text,
            displayName: _name.text,
          )
        : await authManager.createAccountWithEmail(
            context,
            _identifier.text.trim(),
            _password.text,
          );
    if (!mounted) return;
    if (user == null || user.uid == null || user.uid!.isEmpty) {
      setState(() => _busy = false);
      return;
    }
    final id = user.uid!;
    try {
      await SupabaseDatabase.instance.client.from('profiles').update({
        if (!_phoneMode) 'email': _identifier.text.trim(),
        if (_phoneMode) 'phone_number': phone,
        'display_name': _name.text.trim(),
        'role': 'patient',
        'requested_role': 'patient',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
      await MotherRecord.collection.doc(id).set(
            createMotherRecordData(
              userId: UserRecord.collection.doc(id),
              motherId: id,
              name: _name.text.trim(),
              phoneNumber: phone,
            ),
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your account was created. Some profile details can be completed after sign-in.',
            ),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) => DawaAuthScaffold(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const DawaMomLogo(
                variant: DawaMomLogoVariant.authentication,
                size: 78,
                width: 105,
              ),
              const SizedBox(height: 14),
              Text(
                'Create your account',
                style: context.dawaDisplay.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 4),
              Text(
                'Join DawaMom and get care that supports\nyou and your baby.',
                textAlign: TextAlign.center,
                style: context.dawaCaption,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: DawaColors.softBlue,
                  borderRadius: BorderRadius.circular(DawaRadii.pill),
                  border: Border.all(color: DawaColors.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        selected: !_phoneMode,
                        icon: Icons.email_outlined,
                        label: 'Email',
                        onTap: () => setState(() {
                          _phoneMode = false;
                          _identifier.clear();
                        }),
                      ),
                    ),
                    Expanded(
                      child: _ModeButton(
                        selected: _phoneMode,
                        icon: Icons.phone_outlined,
                        label: 'Phone number',
                        onTap: () => setState(() {
                          _phoneMode = true;
                          _identifier.clear();
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: InputDecoration(
                  hintText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 2
                    ? context.tr('Enter your full name.')
                    : null,
              ),
              const SizedBox(height: 11),
              TextFormField(
                controller: _identifier,
                keyboardType: _phoneMode
                    ? TextInputType.phone
                    : TextInputType.emailAddress,
                autofillHints: [
                  _phoneMode
                      ? AutofillHints.telephoneNumber
                      : AutofillHints.email,
                ],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: _phoneMode ? '+260  Phone number' : 'Email address',
                  prefixIcon: Icon(
                    _phoneMode ? Icons.phone_outlined : Icons.email_outlined,
                  ),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (_phoneMode) {
                    return text.replaceAll(RegExp(r'\D'), '').length < 9
                        ? context.tr('Enter a valid phone number.')
                        : null;
                  }
                  return !text.contains('@')
                      ? context.tr('Enter a valid email address.')
                      : null;
                },
              ),
              const SizedBox(height: 11),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Create password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show passwords' : 'Hide passwords',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) => (value?.length ?? 0) < 8
                    ? context.tr('Use at least 8 characters.')
                    : null,
              ),
              const SizedBox(height: 11),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _register(),
                decoration: InputDecoration(
                  hintText: 'Confirm password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (value) => value != _password.text
                    ? context.tr('Passwords do not match.')
                    : null,
              ),
              const SizedBox(height: 11),
              DawaCard(
                padding: const EdgeInsets.all(10),
                color: DawaColors.softBlue,
                child: Row(
                  children: [
                    const Icon(Icons.sync_alt_rounded,
                        color: DawaColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _phoneMode
                            ? 'You can add an email later in your profile.'
                            : 'You can add a phone number later in your profile.',
                        style: context.dawaCaption,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DawaPrimaryButton(
                label: 'Create account',
                busy: _busy,
                onPressed: _register,
              ),
              const SizedBox(height: 9),
              Text(
                'By continuing, you agree to our Terms and Privacy Policy.',
                textAlign: TextAlign.center,
                style: context.dawaCaption.copyWith(fontSize: 9),
              ),
              const SizedBox(height: 54),
              TextButton(
                onPressed: () => context.go('/login'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Already registered?  Log in'),
              ),
            ],
          ),
        ),
      );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(DawaRadii.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DawaRadii.pill),
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DawaRadii.pill),
              border: selected ? Border.all(color: DawaColors.green) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 19,
                    color: selected ? DawaColors.green : DawaColors.muted),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? DawaColors.primary : DawaColors.muted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class DawaPasswordRecoveryPage extends StatefulWidget {
  const DawaPasswordRecoveryPage({super.key});

  @override
  State<DawaPasswordRecoveryPage> createState() =>
      _DawaPasswordRecoveryPageState();
}

class _DawaPasswordRecoveryPageState extends State<DawaPasswordRecoveryPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _code = TextEditingController();
  bool _phoneMode = true;
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _identifier.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _busy = true);
    if (_phoneMode) {
      final sent = await authManager.beginPhoneAuth(
        context: context,
        phoneNumber: normalizeZambianPhone(_identifier.text),
        onCodeSent: (_) {},
      );
      if (mounted) {
        setState(() {
          _busy = false;
          _codeSent = sent == true;
        });
      }
    } else {
      await authManager.resetPassword(
        email: _identifier.text.trim(),
        context: context,
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_code.text.trim().length < 6) return;
    setState(() => _busy = true);
    final user = await authManager.verifySmsCode(
      context: context,
      smsCode: _code.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (user != null) context.go('/settings');
  }

  @override
  Widget build(BuildContext context) => DawaAuthScaffold(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const DawaMomLogo(
                variant: DawaMomLogoVariant.authentication,
                size: 90,
                width: 115,
              ),
              const SizedBox(height: 45),
              Text(
                'Reset your password',
                style: context.dawaDisplay.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 5),
              Text(
                'Choose how you want to recover your account.',
                textAlign: TextAlign.center,
                style: context.dawaBody,
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: DawaColors.softBlue,
                  borderRadius: BorderRadius.circular(DawaRadii.pill),
                  border: Border.all(color: DawaColors.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        selected: !_phoneMode,
                        icon: Icons.email_outlined,
                        label: 'Email',
                        onTap: () => setState(() {
                          _phoneMode = false;
                          _identifier.clear();
                          _codeSent = false;
                        }),
                      ),
                    ),
                    Expanded(
                      child: _ModeButton(
                        selected: _phoneMode,
                        icon: Icons.phone_outlined,
                        label: 'Phone number',
                        onTap: () => setState(() {
                          _phoneMode = true;
                          _identifier.clear();
                          _codeSent = false;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _identifier,
                enabled: !_codeSent,
                keyboardType: _phoneMode
                    ? TextInputType.phone
                    : TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: _phoneMode ? '+260  Phone number' : 'Email address',
                  prefixIcon: Icon(
                    _phoneMode ? Icons.phone_outlined : Icons.email_outlined,
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.tr(
                        'Enter your ${_phoneMode ? 'phone number' : 'email'}.',
                      )
                    : null,
              ),
              if (_codeSent) ...[
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('dawa-recovery-code'),
                  controller: _code,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _verify(),
                  decoration: InputDecoration(
                    hintText: '6-digit verification code',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 9),
              Text(
                _phoneMode
                    ? 'We’ll send a one-time verification code to your phone.'
                    : 'We’ll send a secure password reset link to your email.',
                style: context.dawaCaption,
              ),
              const SizedBox(height: 30),
              DawaPrimaryButton(
                label: _codeSent
                    ? 'Verify code'
                    : _phoneMode
                        ? 'Send reset code'
                        : 'Send reset link',
                busy: _busy,
                onPressed: _codeSent ? _verify : _send,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() {
                  _phoneMode = !_phoneMode;
                  _identifier.clear();
                  _codeSent = false;
                }),
                child: Text(
                  _phoneMode ? 'Use email instead' : 'Use phone instead',
                ),
              ),
              const SizedBox(height: 125),
              TextButton(
                onPressed: () => context.go('/login'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Remembered your password?  Log in'),
              ),
            ],
          ),
        ),
      );
}

String normalizeZambianPhone(String input) {
  final compact = input.replaceAll(RegExp(r'[\s()-]'), '');
  if (compact.startsWith('+')) return compact;
  if (compact.startsWith('260')) return '+$compact';
  if (compact.startsWith('0')) return '+260${compact.substring(1)}';
  return '+260$compact';
}
