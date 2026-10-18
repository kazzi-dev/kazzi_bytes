import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/account_controllers.dart';
import '../controllers/cart_controller.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/app_scope.dart';
import '../widgets/cart_widgets.dart';
import '../widgets/controls.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/routes.dart';
import '../widgets/surfaces.dart';
import 'account/payment_methods_page.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _note = TextEditingController();
  OrderType _type = OrderType.dineIn;
  PaymentMethod _payment = PaymentMethod.cash;
  bool _placing = false;

  /// Frozen copy of the cart while the order is placed, so the page doesn't
  /// flash empty as the cart clears during the exit transition.
  ({List<CartLine> lines, PriceBreakdown breakdown, int count, String? promo})?
  _frozen;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    // Preselect the saved default card, like one-tap checkout in big apps.
    if (AppScope.of(context).payments.defaultItem != null) {
      _payment = PaymentMethod.card;
    }
  }

  Future<void> _selectPayment(PaymentMethod method) async {
    HapticFeedback.selectionClick();
    final PaymentMethodsController payments = AppScope.of(context).payments;
    if (method == PaymentMethod.card && payments.isEmpty) {
      await PaymentMethodsPage.openAddCard(context);
      if (!mounted || payments.isEmpty) return;
    }
    setState(() => _payment = method);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_placing) return;
    final AppScope scope = AppScope.of(context);
    final CartController cart = scope.cart;
    if (cart.isEmpty) return;

    FocusScope.of(context).unfocus();
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() {
      _placing = true;
      _frozen = (
        lines: cart.lines,
        breakdown: cart.breakdown,
        count: cart.itemCount,
        promo: cart.promoCode,
      );
    });

    try {
      final PlacedOrder order = await scope.orders.place(
        lines: _frozen!.lines,
        type: _type,
        payment: _payment,
        breakdown: _frozen!.breakdown,
        note: _note.text.trim(),
      );
      cart.clear();
      HapticFeedback.mediumImpact();
      navigator.pushAndRemoveUntil(
        KzRoute<void>(
          style: KzTransition.fadeThrough,
          builder: (BuildContext context) => OrderSuccessPage(order: order),
        ),
        (Route<dynamic> route) => route.isFirst,
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _placing = false;
        _frozen = null;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e is OrderException
                ? e.message
                : 'We couldn’t place your order. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final CartController cart = AppScope.of(context).cart;
    final PaymentMethodsController payments = AppScope.of(context).payments;
    final EdgeInsets gutter = centeredGutter(
      context,
      maxWidth: Kz.maxReadingWidth,
    );

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[cart, payments]),
      builder: (BuildContext context, Widget? _) {
        final SavedCard? savedCard = payments.defaultItem;
        final List<CartLine> lines = _frozen?.lines ?? cart.lines;
        final PriceBreakdown breakdown = _frozen?.breakdown ?? cart.breakdown;
        final int itemCount = _frozen?.count ?? cart.itemCount;
        final String? promo = _frozen == null ? cart.promoCode : _frozen!.promo;
        int slowest = 0;
        for (final CartLine line in lines) {
          if (line.dish.prepMinutes > slowest) slowest = line.dish.prepMinutes;
        }
        final int eta = slowest + 5;

        final List<Widget> sections = <Widget>[
          const _Heading('How are you eating?'),
          SlidingSegmented<OrderType>(
            value: _type,
            onChanged: (OrderType t) => setState(() => _type = t),
            segments: <Segment<OrderType>>[
              for (final OrderType t in OrderType.values)
                Segment<OrderType>(value: t, label: t.label, icon: t.icon),
            ],
          ),
          const SizedBox(height: Kz.s3),
          AnimatedSwitcher(
            duration: Motion.of(context, Kz.dMedium),
            child: _InfoNote(
              key: ValueKey<OrderType>(_type),
              icon: _type == OrderType.dineIn
                  ? Icons.table_restaurant_rounded
                  : Icons.shopping_bag_rounded,
              text: _type == OrderType.dineIn
                  ? 'We’ll bring it to your table in about $eta min. '
                        'Your table number is on the receipt.'
                  : 'Packed and ready at the counter in about $eta min.',
            ),
          ),
          const _Heading('Payment'),
          for (final PaymentMethod method in PaymentMethod.values)
            Padding(
              padding: const EdgeInsets.only(bottom: Kz.s2),
              child: _PaymentTile(
                method: method,
                selected: method == _payment,
                detail: method == PaymentMethod.card && savedCard != null
                    ? '${savedCard.masked} · Expires ${savedCard.expiry}'
                    : method == PaymentMethod.card
                    ? 'Add a card to pay in one tap'
                    : null,
                onTap: () => _selectPayment(method),
              ),
            ),
          const _Heading('Notes for the kitchen'),
          TextField(
            controller: _note,
            maxLength: 140,
            maxLines: 2,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'No onions, extra spicy… (optional)',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const _Heading('Order summary'),
          SurfaceCard(
            padding: const EdgeInsets.all(Kz.s4),
            child: Column(
              children: <Widget>[
                for (final CartLine line in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Kz.s1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${line.quantity}×',
                            style: context.text.labelLarge?.copyWith(
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                line.dish.name,
                                style: context.text.bodyLarge,
                              ),
                              if (line.addOns.isNotEmpty)
                                Text(
                                  line.addOns
                                      .map((AddOn a) => a.name)
                                      .join(', '),
                                  style: context.text.bodySmall?.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          formatPeso(line.subtotal),
                          style: context.text.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Kz.s3),
          PriceBreakdownCard(
            breakdown: breakdown,
            itemCount: itemCount,
            promoCode: promo,
          ),
        ];

        return Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          appBar: const FrostedAppBar(title: 'Checkout'),
          // Builder: read the padding the Scaffold gives its body (it
          // includes the app bar and bottom bar heights).
          body: Builder(
            builder: (BuildContext context) {
              final EdgeInsets padding = MediaQuery.paddingOf(context);
              return ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: gutter.copyWith(
                  top: padding.top + Kz.s2,
                  bottom: padding.bottom + Kz.s6,
                ),
                children: <Widget>[
                  for (int i = 0; i < sections.length; i++)
                    Entrance(
                      delay: Motion.stagger(
                        context,
                        i,
                        step: const Duration(milliseconds: 25),
                      ),
                      child: sections[i],
                    ),
                ],
              );
            },
          ),
          bottomNavigationBar: lines.isEmpty
              ? null
              : Frosted(
                  border: Border(
                    top: BorderSide(color: context.palette.hairline),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Center(
                      heightFactor: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: Kz.maxReadingWidth,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Kz.s5,
                            Kz.s3,
                            Kz.s5,
                            Kz.s3,
                          ),
                          child: LoadingButton(
                            label: 'Place order',
                            loading: _placing,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Text('· '),
                                RollingNumber.peso(value: breakdown.total),
                              ],
                            ),
                            onPressed: _placeOrder,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Kz.s6, bottom: Kz.s3),
      child: Semantics(
        header: true,
        child: Text(text, style: context.text.titleMedium),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Kz.s3),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(Kz.rMd),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: context.colors.onPrimaryContainer),
          const SizedBox(width: Kz.s3),
          Expanded(
            child: Text(
              text,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.method,
    this.detail,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  /// Replaces the method description, e.g. the saved card.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final Duration duration = Motion.of(context, Kz.dMedium);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '${method.label}. ${detail ?? method.description}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: duration,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Kz.rLg),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Material(
          color: selected
              ? colors.primary.withValues(alpha: 0.05)
              : colors.surface,
          borderRadius: BorderRadius.circular(Kz.rLg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Kz.rLg),
            child: Padding(
              padding: const EdgeInsets.all(Kz.s3),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(Kz.rSm),
                    ),
                    child: Icon(method.icon, color: colors.onPrimaryContainer),
                  ),
                  const SizedBox(width: Kz.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(method.label, style: context.text.titleSmall),
                        Text(
                          detail ?? method.description,
                          style: context.text.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedScale(
                    duration: duration,
                    curve: Curves.easeOutBack,
                    scale: selected ? 1 : 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: colors.primary,
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
