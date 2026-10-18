import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/format.dart';
import '../data/models.dart';
import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/app_scope.dart';
import '../widgets/controls.dart';
import '../widgets/dish_widgets.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/routes.dart';
import '../widgets/surfaces.dart';
import 'cart_page.dart';

/// Draggable dish detail sheet. Opened with [SheetRoute] so the dish image
/// flies in from the card via Hero.
class DishDetailSheet extends StatefulWidget {
  const DishDetailSheet({super.key, required this.dish, required this.heroTag});

  final Dish dish;
  final Object heroTag;

  @override
  State<DishDetailSheet> createState() => _DishDetailSheetState();
}

class _DishDetailSheetState extends State<DishDetailSheet> {
  int _quantity = 1;
  final Set<String> _addOnIds = <String>{};
  bool _closing = false;

  Dish get _dish => widget.dish;

  List<AddOn> get _selectedAddOns => <AddOn>[
    for (final AddOn addOn in _dish.addOns)
      if (_addOnIds.contains(addOn.id)) addOn,
  ];

  int get _unitPrice =>
      _dish.price +
      _selectedAddOns.fold<int>(0, (int sum, AddOn a) => sum + a.price);

  int get _total => _unitPrice * _quantity;

  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  void _toggleAddOn(AddOn addOn) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_addOnIds.remove(addOn.id)) _addOnIds.add(addOn.id);
    });
  }

  void _addToCart() {
    final AppScope scope = AppScope.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final int quantity = _quantity;

    scope.cart.add(_dish, addOns: _selectedAddOns, quantity: quantity);
    _closing = true;
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Added $quantity× ${_dish.name}'),
          persist: false,
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () => navigator.push(
              KzRoute<void>(
                builder: (BuildContext context) => const CartPage(),
              ),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: _close,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Kz.maxReadingWidth),
            child: NotificationListener<DraggableScrollableNotification>(
              onNotification: (DraggableScrollableNotification n) {
                // Dragging well below the resting height dismisses.
                if (n.extent < 0.5) _close();
                return false;
              },
              child: DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.3,
                maxChildSize: 0.96,
                builder: (BuildContext context, ScrollController scroll) {
                  return _buildSheet(context, scroll);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSheet(BuildContext context, ScrollController scroll) {
    final ColorScheme colors = context.colors;

    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Kz.rXl)),
      ),
      child: Stack(
        children: <Widget>[
          CustomScrollView(
            controller: scroll,
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Semantics(
                  label: 'Close dish details',
                  button: true,
                  onTap: _close,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: Kz.s3),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(Kz.rPill),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Kz.s5),
                sliver: SliverList.list(
                  children: <Widget>[
                    AspectRatio(
                      aspectRatio: 1.45,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          DishImage(
                            dish: _dish,
                            heroTag: widget.heroTag,
                            radius: Kz.rXl,
                          ),
                          Positioned(
                            top: Kz.s3,
                            right: Kz.s3,
                            child: FavoriteButton(dish: _dish, onImage: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Kz.s5),
                    Entrance(
                      delay: Motion.of(
                        context,
                        const Duration(milliseconds: 120),
                      ),
                      child: _details(context),
                    ),
                    const SizedBox(height: Kz.s4),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 112 + MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Frosted(
              border: Border(top: BorderSide(color: context.palette.hairline)),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Kz.s5,
                    Kz.s3,
                    Kz.s5,
                    Kz.s3,
                  ),
                  child: Row(
                    children: <Widget>[
                      QtyStepper(
                        quantity: _quantity,
                        itemName: _dish.name,
                        onAdd: () => setState(() => _quantity++),
                        onRemove: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      const SizedBox(width: Kz.s3),
                      Expanded(
                        child: LoadingButton(
                          label: 'Add',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text('· '),
                              RollingNumber.peso(value: _total),
                            ],
                          ),
                          onPressed: _addToCart,
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

  Widget _details(BuildContext context) {
    final ColorScheme colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: Kz.s2,
          runSpacing: Kz.s2,
          children: <Widget>[
            if (_dish.isPopular || _dish.isNew) DishBadge(dish: _dish),
            KzTag(label: _dish.category, tone: TagTone.neutral),
          ],
        ),
        const SizedBox(height: Kz.s3),
        Semantics(
          header: true,
          child: Text(_dish.name, style: context.text.headlineSmall),
        ),
        const SizedBox(height: Kz.s1),
        Text(
          formatPeso(_dish.price),
          style: context.text.titleLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: Kz.s4),
        DishMeta(dish: _dish, showCalories: true),
        const SizedBox(height: Kz.s4),
        Text(
          _dish.description,
          style: context.text.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        if (_dish.addOns.isNotEmpty) ...<Widget>[
          const SizedBox(height: Kz.s7),
          SectionTitle('Make it yours', subtitle: 'Optional add-ons'),
          const SizedBox(height: Kz.s3),
          for (final AddOn addOn in _dish.addOns)
            Padding(
              padding: const EdgeInsets.only(bottom: Kz.s2),
              child: _AddOnTile(
                addOn: addOn,
                selected: _addOnIds.contains(addOn.id),
                onTap: () => _toggleAddOn(addOn),
              ),
            ),
        ],
      ],
    );
  }
}

class _AddOnTile extends StatelessWidget {
  const _AddOnTile({
    required this.addOn,
    required this.selected,
    required this.onTap,
  });

  final AddOn addOn;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final BorderRadius radius = BorderRadius.circular(Kz.rMd);

    return MergeSemantics(
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.06)
            : colors.surface,
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: Motion.of(context, Kz.dMedium),
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: Kz.s2),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Checkbox(value: selected, onChanged: (_) => onTap()),
                Expanded(
                  child: Text(addOn.name, style: context.text.bodyLarge),
                ),
                const SizedBox(width: Kz.s2),
                Text(
                  addOn.price == 0 ? 'Free' : '+${formatPeso(addOn.price)}',
                  style: context.text.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: Kz.s3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
