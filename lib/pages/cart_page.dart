import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/cart_controller.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/app_scope.dart';
import '../widgets/cart_widgets.dart';
import '../widgets/controls.dart';
import '../widgets/dish_widgets.dart';
import '../widgets/illustrations.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/routes.dart';
import '../widgets/surfaces.dart';
import 'checkout_page.dart';

void openCart(BuildContext context) {
  Navigator.of(context)
      .push(KzRoute<void>(builder: (BuildContext context) => const CartPage()));
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  static void _removeWithUndo(
    BuildContext context,
    CartController cart,
    CartLine line,
  ) {
    HapticFeedback.lightImpact();
    final int index = cart.removeLine(line);
    if (index < 0) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed ${line.dish.name}'),
          persist: false,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cart.restoreLine(line, index),
          ),
        ),
      );
  }

  static void _clearWithUndo(BuildContext context, CartController cart) {
    HapticFeedback.mediumImpact();
    final List<CartLine> snapshot = cart.lines;
    final String? promo = cart.promoCode;
    cart.clear();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Cart cleared'),
          persist: false,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cart.restoreAll(snapshot, promoCode: promo),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final CartController cart = AppScope.of(context).cart;

    return ListenableBuilder(
      listenable: cart,
      builder: (BuildContext context, Widget? _) {
        final bool empty = cart.isEmpty;
        return Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          appBar: FrostedAppBar(
            title: 'Your cart',
            actions: <Widget>[
              AnimatedSwitcher(
                duration: Motion.of(context, Kz.dMedium),
                child: empty
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: () => _clearWithUndo(context, cart),
                        child: const Text('Clear'),
                      ),
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: Motion.of(context, Kz.dSlow),
            child: empty
                ? Center(
                    key: const ValueKey<String>('empty'),
                    child: SingleChildScrollView(
                      child: EmptyState(
                        icon: Icons.shopping_bag_outlined,
                        accents: const <IconData>[
                          Icons.lunch_dining_rounded,
                          Icons.local_cafe_rounded,
                          Icons.icecream_rounded,
                        ],
                        title: 'Your cart is empty',
                        message:
                            'Add something tasty from the menu to get started.',
                        action: FilledButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text('Browse menu'),
                        ),
                      ),
                    ),
                  )
                : _CartList(
                    key: const ValueKey<String>('list'),
                    cart: cart,
                    onRemove: (CartLine line) =>
                        _removeWithUndo(context, cart, line),
                  ),
          ),
          bottomNavigationBar: empty
              ? null
              : _CheckoutBar(
                  total: cart.breakdown.total,
                  onCheckout: () => Navigator.of(context).push(
                    KzRoute<void>(
                      builder: (BuildContext context) => const CheckoutPage(),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _CartList extends StatelessWidget {
  const _CartList({super.key, required this.cart, required this.onRemove});

  final CartController cart;
  final ValueChanged<CartLine> onRemove;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final EdgeInsets gutter = centeredGutter(
      context,
      maxWidth: Kz.maxReadingWidth,
    );
    final List<CartLine> lines = cart.lines;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: gutter.copyWith(
        top: padding.top + Kz.s3,
        bottom: padding.bottom + Kz.s6,
      ),
      children: <Widget>[
        for (int i = 0; i < lines.length; i++)
          Padding(
            key: ValueKey<String>(lines[i].key),
            padding: const EdgeInsets.only(bottom: Kz.s3),
            child: Dismissible(
              key: ValueKey<String>('dismiss-${lines[i].key}'),
              direction: DismissDirection.endToStart,
              background: const _DeleteBackground(),
              onDismissed: (_) => onRemove(lines[i]),
              child: Entrance(
                delay: Motion.stagger(context, i),
                child: _CartLineCard(
                  line: lines[i],
                  onAdd: () => cart.increment(lines[i]),
                  onRemove: () => lines[i].quantity <= 1
                      ? onRemove(lines[i])
                      : cart.decrement(lines[i]),
                ),
              ),
            ),
          ),
        const SizedBox(height: Kz.s2),
        Entrance(
          delay: Motion.stagger(context, lines.length),
          child: _PromoCodeField(cart: cart),
        ),
        const SizedBox(height: Kz.s3),
        Entrance(
          delay: Motion.stagger(context, lines.length + 1),
          child: PriceBreakdownCard(
            breakdown: cart.breakdown,
            itemCount: cart.itemCount,
            promoCode: cart.promoCode,
          ),
        ),
        const SizedBox(height: Kz.s3),
        Center(
          child: Text(
            'Swipe an item left to remove it',
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: Kz.s6),
      decoration: BoxDecoration(
        color: colors.error,
        borderRadius: BorderRadius.circular(Kz.rLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Remove',
            style: context.text.labelLarge?.copyWith(color: colors.onError),
          ),
          const SizedBox(width: Kz.s2),
          Icon(Icons.delete_outline_rounded, color: colors.onError),
        ],
      ),
    );
  }
}

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({
    required this.line,
    required this.onAdd,
    required this.onRemove,
  });

  final CartLine line;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextStyle? muted = context.text.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return SurfaceCard(
      padding: const EdgeInsets.all(Kz.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox.square(dimension: 76, child: DishImage(dish: line.dish)),
          const SizedBox(width: Kz.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  line.dish.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium,
                ),
                if (line.addOns.isNotEmpty)
                  Text(
                    line.addOns.map((AddOn a) => a.name).join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                Text('${formatPeso(line.unitPrice)} each', style: muted),
                const SizedBox(height: Kz.s2),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RollingNumber.peso(
                          value: line.subtotal,
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: QtyStepper(
                            quantity: line.quantity,
                            itemName: line.dish.name,
                            removeDeletes: true,
                            onAdd: onAdd,
                            onRemove: onRemove,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCodeField extends StatefulWidget {
  const _PromoCodeField({required this.cart});

  final CartController cart;

  @override
  State<_PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends State<_PromoCodeField> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    if (_controller.text.trim().isEmpty) return;
    if (widget.cart.applyPromo(_controller.text)) {
      HapticFeedback.mediumImpact();
      FocusScope.of(context).unfocus();
      _controller.clear();
      setState(() => _error = null);
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _error = 'That code isn’t valid. Try KAZZI10.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final String? applied = widget.cart.promoCode;

    return AnimatedSwitcher(
      duration: Motion.of(context, Kz.dMedium),
      child: applied != null
          ? SurfaceCard(
              key: const ValueKey<String>('applied'),
              padding: const EdgeInsets.fromLTRB(Kz.s4, Kz.s1, Kz.s1, Kz.s1),
              color: context.palette.successContainer,
              borderColor: context.palette.success.withValues(alpha: 0.3),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.local_offer_rounded,
                    color: context.palette.onSuccessContainer,
                  ),
                  const SizedBox(width: Kz.s3),
                  Expanded(
                    child: Text(
                      '$applied applied · you save '
                      '${formatPeso(widget.cart.discount)}',
                      style: context.text.labelLarge?.copyWith(
                        color: context.palette.onSuccessContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove promo code',
                    onPressed: widget.cart.clearPromo,
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.palette.onSuccessContainer,
                    ),
                  ),
                ],
              ),
            )
          : SurfaceCard(
              key: const ValueKey<String>('entry'),
              padding: const EdgeInsets.fromLTRB(Kz.s4, Kz.s1, Kz.s2, Kz.s1),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.local_offer_outlined,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: Kz.s3),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _apply(),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      decoration: InputDecoration(
                        hintText: 'Promo code',
                        errorText: _error,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: Kz.s3,
                        ),
                      ),
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(72, Kz.minTap),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.total, required this.onCheckout});

  final int total;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Frosted(
      border: Border(top: BorderSide(color: context.palette.hairline)),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Kz.maxReadingWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Kz.s5, Kz.s3, Kz.s5, Kz.s3),
              child: Row(
                children: <Widget>[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Total',
                        style: context.text.labelMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      RollingNumber.peso(
                        value: total,
                        style: context.text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: Kz.s4),
                  Expanded(
                    child: LoadingButton(
                      label: 'Checkout',
                      trailing: const Icon(Icons.arrow_forward_rounded),
                      onPressed: onCheckout,
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
