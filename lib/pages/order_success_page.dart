import 'package:flutter/material.dart';

import '../data/format.dart';
import '../data/models.dart';
import '../theme/context_ext.dart';
import '../theme/tokens.dart';
import '../widgets/app_scope.dart';
import '../widgets/controls.dart';
import '../widgets/illustrations.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/surfaces.dart';

/// Celebration screen: a drawn checkmark, confetti and a staggered reveal.
class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key, required this.order});

  final PlacedOrder order;

  void _close(BuildContext context, {required int tab}) {
    AppScope.of(context).tabIndex.value = tab;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final String? name = scope.auth.user?.isGuest ?? true
        ? null
        : scope.auth.user?.firstName;

    Widget reveal(int step, Widget child) => Entrance(
      delay: Duration(milliseconds: 520 + step * 90),
      child: child,
    );

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: MeshBackground(intensity: 0.6)),
          const Positioned.fill(child: ConfettiBurst()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Kz.s6),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Kz.maxFormWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Center(child: AnimatedCheck(size: 128)),
                      const SizedBox(height: Kz.s7),
                      reveal(
                        0,
                        Semantics(
                          liveRegion: true,
                          header: true,
                          child: Text(
                            'Order placed!',
                            textAlign: TextAlign.center,
                            style: context.text.headlineMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: Kz.s2),
                      reveal(
                        1,
                        Text(
                          name == null
                              ? 'Thanks! The kitchen is on it.'
                              : 'Thanks, $name! The kitchen is on it.',
                          textAlign: TextAlign.center,
                          style: context.text.bodyLarge?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: Kz.s6),
                      reveal(2, _Ticket(order: order)),
                      const SizedBox(height: Kz.s7),
                      reveal(
                        3,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            LoadingButton(
                              label: 'Track order',
                              leading: const Icon(Icons.radar_rounded),
                              onPressed: () => _close(context, tab: 1),
                            ),
                            const SizedBox(height: Kz.s2),
                            TextButton(
                              onPressed: () => _close(context, tab: 0),
                              child: const Text('Back to menu'),
                            ),
                          ],
                        ),
                      ),
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
}

class _Ticket extends StatelessWidget {
  const _Ticket({required this.order});

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    final TextStyle? label = context.text.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final TextStyle? value = context.text.bodyLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );

    Widget row(String l, String v, IconData icon) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Kz.s1 + 2),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
          const SizedBox(width: Kz.s2),
          Text(l, style: label),
          const SizedBox(width: Kz.s3),
          Expanded(
            child: Text(v, textAlign: TextAlign.end, style: value),
          ),
        ],
      ),
    );

    return SurfaceCard(
      padding: const EdgeInsets.all(Kz.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Order number', style: label),
                    Text(
                      order.number,
                      style: context.text.headlineSmall?.copyWith(
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              KzTag(
                label: order.status.label,
                icon: order.status.icon,
                tone: TagTone.success,
              ),
            ],
          ),
          const SizedBox(height: Kz.s4),
          const Divider(),
          const SizedBox(height: Kz.s2),
          row('Order type', order.type.label, order.type.icon),
          row('Payment', order.payment.label, order.payment.icon),
          row(
            'Ready in',
            'about ${order.etaMinutes} min',
            Icons.schedule_rounded,
          ),
          row(
            'Total',
            '${formatPeso(order.breakdown.total)} · ${pluralItems(order.itemCount)}',
            Icons.receipt_rounded,
          ),
        ],
      ),
    );
  }
}
