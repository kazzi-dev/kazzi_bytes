import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repositories.dart';
import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../widgets/app_scope.dart';
import '../widgets/controls.dart';
import '../widgets/illustrations.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/routes.dart';
import 'shell_page.dart';

enum _AuthMode { signIn, signUp }

enum _Busy { none, email, google, apple }

/// Sign in / sign up. Runs against MockAuthRepository until a backend
/// exists; see the TODOs in data/repositories.dart.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  _AuthMode _mode = _AuthMode.signIn;
  _Busy _busy = _Busy.none;
  bool _obscure = true;
  String? _error;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _setMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _error = null;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _run(_Busy busy, Future<void> Function() action) async {
    if (_busy != _Busy.none) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = busy;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _enterApp();
    } on AuthException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _error = e.message);
    } on Object {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.heavyImpact();
      return;
    }
    final AppScope scope = AppScope.of(context);
    _run(_Busy.email, () {
      return _isSignUp
          ? scope.auth.signUp(
              name: _name.text,
              email: _email.text,
              password: _password.text,
            )
          : scope.auth.signIn(email: _email.text, password: _password.text);
    });
  }

  void _social(SocialProvider provider) {
    final AppScope scope = AppScope.of(context);
    _run(
      provider == SocialProvider.google ? _Busy.google : _Busy.apple,
      () => scope.auth.signInWith(provider),
    );
  }

  void _guest() {
    AppScope.of(context).auth.continueAsGuest();
    _enterApp();
  }

  void _enterApp() {
    Navigator.of(context).pushAndRemoveUntil(
      KzRoute<void>(
        style: KzTransition.fadeThrough,
        builder: (BuildContext context) => const ShellPage(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _forgotPassword() async {
    final String? sentTo = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) =>
          _ForgotPasswordSheet(initialEmail: _email.text),
    );
    if (!mounted || sentTo == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Reset link sent to $sentTo')));
  }

  String? _validateEmail(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(v)) return 'That email doesn’t look right';
    return null;
  }

  String? _validatePassword(String? value) {
    final String v = value ?? '';
    if (v.isEmpty) return 'Enter your password';
    if (_isSignUp && v.length < 8) return 'Use at least 8 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final Duration medium = Motion.of(context, Kz.dMedium);
    final bool busy = _busy != _Busy.none;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: MeshBackground(intensity: 0.8)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: Kz.s6,
                  vertical: Kz.s8,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Kz.maxFormWidth),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Entrance(
                            child: Row(
                              children: <Widget>[
                                const BrandMark(size: 44),
                                const SizedBox(width: Kz.s3),
                                Semantics(
                                  label: 'Kazzi Bytes',
                                  excludeSemantics: true,
                                  child: Text.rich(
                                    TextSpan(
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: 'kazzi',
                                          style: TextStyle(
                                            color: kazziInk(context),
                                          ),
                                        ),
                                        const TextSpan(
                                          text: '.',
                                          style: TextStyle(
                                            color: KazziBrand.dot,
                                          ),
                                        ),
                                      ],
                                    ),
                                    style: kazziWordmarkStyle(context, 26),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Kz.s8),
                          AnimatedSwitcher(
                            duration: medium,
                            layoutBuilder:
                                (Widget? current, List<Widget> previous) {
                                  return Stack(
                                    alignment: Alignment.topLeft,
                                    children: <Widget>[...previous, ?current],
                                  );
                                },
                            child: Column(
                              key: ValueKey<_AuthMode>(_mode),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Semantics(
                                  header: true,
                                  child: Text(
                                    _isSignUp
                                        ? 'Create your account'
                                        : 'Welcome back',
                                    style: context.text.headlineMedium,
                                  ),
                                ),
                                const SizedBox(height: Kz.s2),
                                Text(
                                  _isSignUp
                                      ? 'Save favorites, track orders and '
                                            'check out faster.'
                                      : 'Sign in to pick up where you left off.',
                                  style: context.text.bodyLarge?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Kz.s6),
                          SlidingSegmented<_AuthMode>(
                            value: _mode,
                            onChanged: _setMode,
                            segments: const <Segment<_AuthMode>>[
                              Segment<_AuthMode>(
                                value: _AuthMode.signIn,
                                label: 'Sign in',
                              ),
                              Segment<_AuthMode>(
                                value: _AuthMode.signUp,
                                label: 'Sign up',
                              ),
                            ],
                          ),
                          const SizedBox(height: Kz.s5),
                          AnimatedSize(
                            duration: medium,
                            curve: Kz.standard,
                            alignment: Alignment.topCenter,
                            child: _isSignUp
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: Kz.s3,
                                    ),
                                    child: TextFormField(
                                      controller: _name,
                                      enabled: !busy,
                                      textInputAction: TextInputAction.next,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      autofillHints: const <String>[
                                        AutofillHints.name,
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Full name',
                                        prefixIcon: Icon(
                                          Icons.person_outline_rounded,
                                        ),
                                      ),
                                      validator: (String? v) =>
                                          (v?.trim().length ?? 0) < 2
                                          ? 'Tell us your name'
                                          : null,
                                      onFieldSubmitted: (_) =>
                                          _emailFocus.requestFocus(),
                                    ),
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                          TextFormField(
                            controller: _email,
                            focusNode: _emailFocus,
                            enabled: !busy,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            autofillHints: const <String>[AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: _validateEmail,
                            onFieldSubmitted: (_) =>
                                _passwordFocus.requestFocus(),
                          ),
                          const SizedBox(height: Kz.s3),
                          TextFormField(
                            controller: _password,
                            focusNode: _passwordFocus,
                            enabled: !busy,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            autofillHints: <String>[
                              _isSignUp
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Password',
                              helperText: _isSignUp
                                  ? 'At least 8 characters'
                                  : null,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                tooltip: _obscure
                                    ? 'Show password'
                                    : 'Hide password',
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: _validatePassword,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          AnimatedSize(
                            duration: medium,
                            curve: Kz.standard,
                            child: _isSignUp
                                ? const SizedBox(
                                    width: double.infinity,
                                    height: Kz.s4,
                                  )
                                : Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: busy ? null : _forgotPassword,
                                      child: const Text('Forgot password?'),
                                    ),
                                  ),
                          ),
                          AnimatedSize(
                            duration: medium,
                            curve: Kz.standard,
                            child: _error == null
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: Kz.s3,
                                    ),
                                    child: _ErrorBanner(message: _error!),
                                  ),
                          ),
                          const SizedBox(height: Kz.s2),
                          LoadingButton(
                            label: _isSignUp ? 'Create account' : 'Sign in',
                            loading: _busy == _Busy.email,
                            onPressed: busy ? null : _submit,
                          ),
                          const SizedBox(height: Kz.s6),
                          Row(
                            children: <Widget>[
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Kz.s3,
                                ),
                                child: Text(
                                  'or continue with',
                                  style: context.text.labelMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: Kz.s4),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _SocialButton(
                                  label: 'Google',
                                  icon: Icons.g_mobiledata_rounded,
                                  loading: _busy == _Busy.google,
                                  onPressed: busy
                                      ? null
                                      : () => _social(SocialProvider.google),
                                ),
                              ),
                              const SizedBox(width: Kz.s3),
                              Expanded(
                                child: _SocialButton(
                                  label: 'Apple',
                                  icon: Icons.apple_rounded,
                                  loading: _busy == _Busy.apple,
                                  onPressed: busy
                                      ? null
                                      : () => _social(SocialProvider.apple),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Kz.s3),
                          Center(
                            child: TextButton(
                              onPressed: busy ? null : _guest,
                              child: const Text('Continue as guest'),
                            ),
                          ),
                          const SizedBox(height: Kz.s2),
                          Text(
                            'Demo build: any email and password work. '
                            'Use error@kazzi.dev to see a failed sign-in.',
                            textAlign: TextAlign.center,
                            style: context.text.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final Color error = context.colors.error;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Kz.s3),
        decoration: BoxDecoration(
          color: error.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(Kz.rSm),
          border: Border.all(color: error.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: error, size: 20),
            const SizedBox(width: Kz.s2),
            Expanded(
              child: Text(
                message,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: context.colors.surface,
        padding: const EdgeInsets.symmetric(horizontal: Kz.s3),
      ),
      child: AnimatedSwitcher(
        duration: Motion.of(context, Kz.dMedium),
        child: loading
            ? const SizedBox.square(
                key: ValueKey<String>('loading'),
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : FittedBox(
                key: const ValueKey<String>('label'),
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(icon, size: 24),
                    const SizedBox(width: Kz.s2),
                    Text(label),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    final NavigatorState navigator = Navigator.of(context);
    await AppScope.of(context).auth.sendPasswordReset(_email.text.trim());
    if (!mounted) return;
    navigator.pop(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Kz.s6,
        0,
        Kz.s6,
        Kz.s6 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Reset your password', style: context.text.titleLarge),
            const SizedBox(height: Kz.s2),
            Text(
              'We’ll email you a link to choose a new one.',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Kz.s5),
            TextFormField(
              controller: _email,
              autofocus: widget.initialEmail.isEmpty,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (String? v) =>
                  _AuthPageState._emailPattern.hasMatch(v?.trim() ?? '')
                  ? null
                  : 'Enter a valid email',
              onFieldSubmitted: (_) => _send(),
            ),
            const SizedBox(height: Kz.s5),
            LoadingButton(
              label: 'Send reset link',
              loading: _sending,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}
