import 'package:flutter/material.dart';

import '../data/format.dart';
import '../data/models.dart';
import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/app_scope.dart';
import '../widgets/dish_widgets.dart';
import '../widgets/illustrations.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/surfaces.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final Set<String> _seen = <String>{};

  void _openDetails(PlacedOrder order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => _OrderDetailSheet(orderId: order.id),
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

    return ListenableBuilder(
      listenable: scope.orders,
      builder: (BuildContext context, Widget? _) {
        final List<PlacedOrder> orders = scope.orders.orders;
        final int active = scope.orders.activeCount;

        return CustomScrollView(
          slivers: <Widget>[
            SliverPersistentHeader(
              pinned: true,
              delegate: FrostedHeaderDelegate(
                height: padding.top + TabTitle.heightFor(context),
                child: Padding(
                  padding: EdgeInsets.only(top: padding.top),
                  child: TabTitle(
                    title: 'Orders',
                    subtitle: orders.isEmpty
                        ? null
                        : active == 0
                        ? 'All caught up'
                        : '$active in progress',
                  ),
                ),
              ),
            ),
            if (orders.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EmptyState(
                    icon: Icons.receipt_long_rounded,
                    accents: const <IconData>[
                      Icons.soup_kitchen_rounded,
                      Icons.schedule_rounded,
                      Icons.room_service_rounded,
                    ],
                    title: 'No orders yet',
                    message:
                        'Your orders will show up here, with live status '
                        'while the kitchen gets cooking.',
                    action: FilledButton(
                      onPressed: () => scope.tabIndex.value = 0,
                      child: const Text('Browse menu'),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: gutter.copyWith(
                  top: Kz.s4,
                  bottom: padding.bottom + Kz.s6,
                ),
                sliver: SliverList.separated(
                  itemCount: orders.length,
                  separatorBuilder: (BuildContext context, int i) =>
                      const SizedBox(height: Kz.s3),
                  itemBuilder: (BuildContext context, int i) {
                    final PlacedOrder order = orders[i];
                    return Entrance(
                      key: ValueKey<String>(order.id),
                      animate: _seen.add(order.id),
                      delay: Motion.stagger(context, i),
                      child: _OrderCard(
                        order: order,
                        onTap: () => _openDetails(order),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

String _timeAgo(BuildContext context, DateTime time) {
  final Duration diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  return TimeOfDay.fromDateTime(time).format(context);
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final PlacedOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    return PressScale(
      pressedScale: 0.985,
      child: SurfaceCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox.square(
                  dimension: 48,
                  child: DishImage(
                    dish: order.lines.first.dish,
                    radius: Kz.rSm,
                  ),
                ),
                const SizedBox(width: Kz.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(order.number, style: context.text.titleMedium),
                      Text(
                        '${_timeAgo(context, order.placedAt)} · '
                        '${pluralItems(order.itemCount)}',
                        style: context.text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Kz.s2),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: Kz.s3),
            Text(
              order.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: Kz.s3),
            _StatusProgress(status: order.status),
            const SizedBox(height: Kz.s3),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${order.type.label} · ${order.payment.label}',
                    style: context.text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  formatPeso(order.breakdown.total),
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final TagTone tone = switch (status) {
      OrderStatus.received => TagTone.brand,
      OrderStatus.preparing => TagTone.warm,
      OrderStatus.ready => TagTone.success,
      OrderStatus.completed => TagTone.neutral,
    };
    return AnimatedSwitcher(
      duration: Motion.of(context, Kz.dMedium),
      transitionBuilder: (Widget child, Animation<double> animation) =>
          ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
      child: KzTag(
        key: ValueKey<OrderStatus>(status),
        label: status.label,
        icon: status.icon,
        tone: tone,
      ),
    );
  }
}

class _StatusProgress extends StatelessWidget {
  const _StatusProgress({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final double target = (status.index + 1) / OrderStatus.values.length;
    return Semantics(
      label: 'Status: ${status.label}',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: target),
        duration: Motion.of(context, Kz.dSlower),
        curve: Kz.emphasized,
        builder: (BuildContext context, double value, Widget? _) {
          return LinearProgressIndicator(
            value: value,
            minHeight: 6,
            borderRadius: BorderRadius.circular(Kz.rPill),
            color: status == OrderStatus.completed
                ? context.colors.onSurfaceVariant
                : context.colors.primary,
          );
        },
      ),
    );
  }
}

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);

    return ListenableBuilder(
      listenable: scope.orders,
      builder: (BuildContext context, Widget? _) {
        final PlacedOrder? order = scope.orders.byId(orderId);
        if (order == null) return const SizedBox.shrink();

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Kz.s6, 0, Kz.s6, Kz.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          order.number,
                          style: context.text.headlineSmall,
                        ),
                      ),
                    ),
                    _StatusChip(status: order.status),
                  ],
                ),
                const SizedBox(height: Kz.s1),
                Text(
                  '${order.type.label} · ${order.payment.label} · '
                  'placed ${_timeAgo(context, order.placedAt).toLowerCase()}',
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Kz.s6),
                for (int i = 0; i < OrderStatus.values.length; i++)
                  _TimelineStep(
                    status: OrderStatus.values[i],
                    order: order,
                    isLast: i == OrderStatus.values.length - 1,
                  ),
                const SizedBox(height: Kz.s4),
                const Divider(),
                const SizedBox(height: Kz.s4),
                for (final CartLine line in order.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Kz.s1),
                    child: Row(
                      children: <Widget>[
                        Text(
                          '${line.quantity}×',
                          style: context.text.labelLarge?.copyWith(
                            color: context.colors.primary,
                          ),
                        ),
                        const SizedBox(width: Kz.s3),
                        Expanded(
                          child: Text(
                            line.dish.name,
                            style: context.text.bodyLarge,
                          ),
                        ),
                        Text(
                          formatPeso(line.subtotal),
                          style: context.text.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                if (order.note.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Kz.s3),
                  Text(
                    '“${order.note}”',
                    style: context.text.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: Kz.s4),
                Row(
                  children: <Widget>[
                    Text('Total', style: context.text.titleMedium),
                    const Spacer(),
                    Text(
                      formatPeso(order.breakdown.total),
                      style: context.text.titleLarge?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.order,
    required this.isLast,
  });

  final OrderStatus status;
  final PlacedOrder order;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final Duration duration = Motion.of(context, Kz.dSlow);
    final bool reached = order.status.index >= status.index;
    final bool current = order.status == status && status.isActive;
    final bool nextReached = order.status.index > status.index;
    final DateTime? time = order.statusTimes[status];

    return Semantics(
      label: '${status.label}, ${reached ? 'done' : 'pending'}',
      excludeSemantics: true,
      // A Stack instead of IntrinsicHeight: the text sets the height and
      // the connector line is positioned alongside it.
      child: Stack(
        children: <Widget>[
          if (!isLast)
            Positioned(
              left: 17,
              top: 40,
              bottom: Kz.s1,
              width: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(1),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: AnimatedFractionallySizedBox(
                    duration: duration,
                    curve: Kz.emphasized,
                    heightFactor: nextReached ? 1 : 0,
                    widthFactor: 1,
                    child: ColoredBox(color: colors.primary),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            top: 0,
            child: PulseHalo(
              active: current,
              color: colors.primary,
              child: AnimatedContainer(
                duration: duration,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: reached ? colors.primary : context.palette.surfaceAlt,
                ),
                child: Icon(
                  status.icon,
                  size: 18,
                  color: reached ? colors.onPrimary : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 36 + Kz.s4,
              top: Kz.s1,
              bottom: isLast ? 0 : Kz.s7,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      status.label,
                      style: context.text.titleSmall?.copyWith(
                        color: reached
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      time != null
                          ? '${status.description} · '
                                '${TimeOfDay.fromDateTime(time).format(context)}'
                          : status.description,
                      style: context.text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
