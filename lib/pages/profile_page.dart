import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repositories.dart';
import '../theme/context_ext.dart';
import '../theme/tokens.dart';
import '../widgets/app_scope.dart';
import '../widgets/controls.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/routes.dart';
import '../widgets/surfaces.dart';
import 'account/addresses_page.dart';
import 'account/notifications_page.dart';
import 'account/payment_methods_page.dart';
import 'auth_page.dart';
import 'onboarding_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature is coming soon')));
  }

  void _open(Widget page) {
    Navigator.of(context)
        .push(KzRoute<void>(builder: (BuildContext context) => page));
  }

  void _goToAuth() {
    final AppScope scope = AppScope.of(context);
    scope.cart.clear();
    scope.tabIndex.value = 0;
    Navigator.of(context).pushAndRemoveUntil(
      KzRoute<void>(
        style: KzTransition.fadeThrough,
        builder: (BuildContext context) => const AuthPage(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _signOut() async {
    final AppScope scope = AppScope.of(context);
    final bool guest = scope.auth.isGuest;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(guest ? 'Leave guest mode?' : 'Sign out?'),
        content: const Text('Your cart will be cleared.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(guest ? 'Leave' : 'Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await scope.auth.signOut();
    if (!mounted) return;
    _goToAuth();
  }

  void _replayOnboarding() {
    AppScope.of(context).auth.resetOnboarding();
    Navigator.of(context).push(
      KzRoute<void>(
        style: KzTransition.fadeThrough,
        builder: (BuildContext context) => const OnboardingPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final EdgeInsets gutter = centeredGutter(
      context,
      maxWidth: Kz.maxReadingWidth,
    );
    final MenuRepository repository = scope.catalog.repository;

    final List<Widget> sections = <Widget>[
      ListenableBuilder(
        listenable: scope.auth,
        builder: (BuildContext context, Widget? _) =>
            _ProfileCard(user: scope.auth.user, onSignIn: _goToAuth),
      ),
      const _SectionLabel('Appearance'),
      ListenableBuilder(
        listenable: scope.theme,
        builder: (BuildContext context, Widget? _) {
          return SlidingSegmented<ThemeMode>(
            value: scope.theme.mode,
            onChanged: scope.theme.setMode,
            segments: const <Segment<ThemeMode>>[
              Segment<ThemeMode>(
                value: ThemeMode.system,
                label: 'System',
                icon: Icons.brightness_auto_rounded,
              ),
              Segment<ThemeMode>(
                value: ThemeMode.light,
                label: 'Light',
                icon: Icons.light_mode_rounded,
              ),
              Segment<ThemeMode>(
                value: ThemeMode.dark,
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
              ),
            ],
          );
        },
      ),
      const _SectionLabel('Account'),
      ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          scope.addresses,
          scope.payments,
          scope.notifications,
        ]),
        builder: (BuildContext context, Widget? _) {
          final int addressCount = scope.addresses.items.length;
          final SavedCard? card = scope.payments.defaultItem;
          return _Group(
            children: <Widget>[
              _NavRow(
                icon: Icons.location_on_outlined,
                label: 'Saved addresses',
                value: addressCount == 0
                    ? 'None yet'
                    : scope.addresses.defaultItem!.displayTitle +
                          (addressCount > 1 ? ' +${addressCount - 1}' : ''),
                onTap: () => _open(const AddressesPage()),
              ),
              _NavRow(
                icon: Icons.credit_card_rounded,
                label: 'Payment methods',
                value: card == null ? 'Cash, GCash' : '•••• ${card.last4}',
                onTap: () => _open(const PaymentMethodsPage()),
              ),
              _NavRow(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                value: scope.notifications.allOff ? 'Off' : 'On',
                onTap: () => _open(const NotificationsPage()),
              ),
              _NavRow(
                icon: Icons.help_outline_rounded,
                label: 'Help & support',
                onTap: () => _comingSoon('Help & support'),
              ),
            ],
          );
        },
      ),
      const _SectionLabel('Demo controls'),
      _Group(
        children: <Widget>[
          if (repository is MockMenuRepository)
            SwitchListTile(
              value: repository.simulateFailure,
              onChanged: (bool value) =>
                  setState(() => repository.simulateFailure = value),
              secondary: const Icon(Icons.wifi_off_rounded),
              title: const Text('Simulate network error'),
              subtitle: const Text(
                'Pull to refresh the menu to see the error state.',
              ),
            ),
          _NavRow(
            icon: Icons.auto_stories_outlined,
            label: 'Replay onboarding',
            onTap: _replayOnboarding,
          ),
        ],
      ),
      const SizedBox(height: Kz.s6),
      OutlinedButton.icon(
        onPressed: _signOut,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.colors.error,
          side: BorderSide(color: context.colors.error.withValues(alpha: 0.4)),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: Text(scope.auth.isGuest ? 'Leave guest mode' : 'Sign out'),
      ),
      const SizedBox(height: Kz.s4),
      Text(
        'Kazzi Bytes · v1.0.0',
        textAlign: TextAlign.center,
        style: context.text.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ];

    return CustomScrollView(
      slivers: <Widget>[
        SliverPersistentHeader(
          pinned: true,
          delegate: FrostedHeaderDelegate(
            height: padding.top + TabTitle.heightFor(context),
            child: Padding(
              padding: EdgeInsets.only(top: padding.top),
              child: const TabTitle(title: 'Profile'),
            ),
          ),
        ),
        SliverPadding(
          padding: gutter.copyWith(top: Kz.s4, bottom: padding.bottom + Kz.s6),
          sliver: SliverList.list(
            children: <Widget>[
              for (int i = 0; i < sections.length; i++)
                Entrance(
                  delay: Duration(milliseconds: 25 * i),
                  child: sections[i],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.onSignIn});

  final AppUser? user;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final bool guest = user?.isGuest ?? true;

    return SurfaceCard(
      padding: const EdgeInsets.all(Kz.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[colors.primary, context.palette.meshC],
                  ),
                ),
                child: guest
                    ? Icon(
                        Icons.person_rounded,
                        color: colors.onPrimary,
                        size: 30,
                      )
                    : Text(
                        user!.initials,
                        style: context.text.titleLarge?.copyWith(
                          color: colors.onPrimary,
                        ),
                      ),
              ),
              const SizedBox(width: Kz.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      guest ? 'Guest' : user!.name,
                      style: context.text.titleLarge,
                    ),
                    Text(
                      guest ? 'Browsing without an account' : user!.email,
                      style: context.text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (guest) ...<Widget>[
            const SizedBox(height: Kz.s4),
            FilledButton(
              onPressed: onSignIn,
              child: const Text('Sign in or create an account'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Kz.s1, Kz.s6, 0, Kz.s2),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: context.text.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const Divider(indent: Kz.s16),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Current setting shown on the right, e.g. "On" or "•••• 4242".
  final String? value;

  @override
  Widget build(BuildContext context) {
    final Color muted = context.colors.onSurfaceVariant;
    return ListTile(
      onTap: onTap,
      minTileHeight: 56,
      leading: Icon(icon),
      title: Text(label, style: context.text.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (value != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(color: muted),
              ),
            ),
          Icon(Icons.chevron_right_rounded, color: muted),
        ],
      ),
    );
  }
}
