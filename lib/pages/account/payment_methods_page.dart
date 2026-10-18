import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/account_controllers.dart';
import '../../data/models.dart';
import '../../theme/context_ext.dart';
import '../../theme/motion.dart';
import '../../theme/tokens.dart';
import '../../widgets/account_widgets.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/controls.dart';
import '../../widgets/illustrations.dart';
import '../../widgets/surfaces.dart';

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  static Future<void> openAddCard(BuildContext context) async {
    await showFormSheet<void>(
      context,
      (BuildContext context) => const _AddCardForm(),
    );
  }

  void _delete(BuildContext context, SavedCard card) {
    final PaymentMethodsController payments = AppScope.of(context).payments;
    final bool wasDefault = payments.isDefault(card);
    HapticFeedback.lightImpact();
    final int index = payments.remove(card);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          persist: false,
          content: Text('Removed ${card.masked}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () =>
                payments.restore(card, index, wasDefault: wasDefault),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final PaymentMethodsController payments = AppScope.of(context).payments;

    return ListenableBuilder(
      listenable: payments,
      builder: (BuildContext context, Widget? _) {
        final List<SavedCard> cards = payments.items;
        final SavedCard? preferred = payments.defaultItem;

        return AccountPageScaffold(
          title: 'Payment methods',
          bottomAction: LoadingButton(
            label: 'Add a card',
            leading: const Icon(Icons.add_card_rounded),
            onPressed: () => openAddCard(context),
          ),
          children: <Widget>[
            if (cards.isEmpty)
              const EmptyState(
                icon: Icons.credit_card_rounded,
                accents: <IconData>[
                  Icons.lock_rounded,
                  Icons.bolt_rounded,
                  Icons.qr_code_2_rounded,
                ],
                title: 'No saved cards',
                message:
                    'Add a card to check out in one tap. You can still pay '
                    'with cash or GCash at the counter.',
              )
            else ...<Widget>[
              AnimatedSwitcher(
                duration: Motion.of(context, Kz.dSlow),
                transitionBuilder: (Widget child, Animation<double> a) =>
                    FadeTransition(
                      opacity: a,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.94, end: 1).animate(a),
                        child: child,
                      ),
                    ),
                child: CardFace(
                  key: ValueKey<String>(preferred!.id),
                  brand: preferred.brand,
                  number: '•••• •••• •••• ${preferred.last4}',
                  holder: preferred.holder,
                  expiry: preferred.expiry,
                ),
              ),
              const GroupLabel('Your cards'),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < cards.length; i++) ...<Widget>[
                      if (i > 0) const Divider(indent: 72),
                      _CardRow(
                        card: cards[i],
                        selected: payments.isDefault(cards[i]),
                        onSelect: () {
                          HapticFeedback.selectionClick();
                          payments.setDefault(cards[i]);
                        },
                        onDelete: () => _delete(context, cards[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const GroupLabel('Pay at the counter'),
            const SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  _StaticMethodRow(method: PaymentMethod.cash),
                  Divider(indent: 72),
                  _StaticMethodRow(method: PaymentMethod.gcash),
                ],
              ),
            ),
            const SizedBox(height: Kz.s5),
            const InfoNote(
              icon: Icons.lock_rounded,
              text:
                  'Kazzi Bytes never stores your full card number or CVV, '
                  'only the brand, last 4 digits and expiry date.',
            ),
          ],
        );
      },
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.card,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
  });

  final SavedCard card;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: ListTile(
        onTap: onSelect,
        minTileHeight: 64,
        leading: _BrandChip(brand: card.brand),
        title: Text(card.masked, style: context.text.titleSmall),
        subtitle: Text(
          card.isExpired ? 'Expired ${card.expiry}' : 'Expires ${card.expiry}',
          style: context.text.bodySmall?.copyWith(
            color: card.isExpired ? colors.error : colors.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedScale(
              duration: Motion.of(context, Kz.dMedium),
              curve: Curves.easeOutBack,
              scale: selected ? 1 : 0,
              child: Icon(Icons.check_circle_rounded, color: colors.primary),
            ),
            IconButton(
              tooltip: 'Remove ${card.masked}',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticMethodRow extends StatelessWidget {
  const _StaticMethodRow({required this.method});

  final PaymentMethod method;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 64,
      leading: Container(
        width: 44,
        height: 32,
        decoration: BoxDecoration(
          color: context.colors.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          method.icon,
          size: 20,
          color: context.colors.onPrimaryContainer,
        ),
      ),
      title: Text(method.label, style: context.text.titleSmall),
      subtitle: Text(
        method.description,
        style: context.text.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({required this.brand});

  final CardBrand brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(colors: brand.colors),
      ),
      child: Text(
        _brandShort(brand),
        style: context.text.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _brandShort(CardBrand brand) => switch (brand) {
  CardBrand.visa => 'VISA',
  CardBrand.mastercard => 'MC',
  CardBrand.amex => 'AMEX',
  CardBrand.jcb => 'JCB',
  CardBrand.unknown => 'CARD',
};

/// A credit-card-shaped visual, used for the default card and as the live
/// preview while adding a card.
class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.brand,
    required this.number,
    required this.holder,
    required this.expiry,
  });

  final CardBrand brand;
  final String number;
  final String holder;
  final String expiry;

  @override
  Widget build(BuildContext context) {
    const Color onCard = Colors.white;
    final TextStyle mono = (context.text.titleLarge ?? const TextStyle())
        .copyWith(
          color: onCard,
          letterSpacing: 2,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        );

    final String digits = number.replaceAll(RegExp(r'\D'), '');
    return Semantics(
      label: digits.length >= 4
          ? '${brand.label} card ending ${digits.substring(digits.length - 4)}'
          : '${brand.label} card',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: AnimatedContainer(
          duration: Motion.of(context, Kz.dSlow),
          curve: Kz.standard,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Kz.rLg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: brand.colors,
            ),
            boxShadow: context.isDark ? null : Kz.glow(brand.colors.first),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Kz.rLg),
            child: Stack(
              children: <Widget>[
                Positioned(
                  right: -60,
                  top: -80,
                  child: _Glow(
                    size: 240,
                    color: onCard.withValues(alpha: 0.14),
                  ),
                ),
                Positioned(
                  left: -50,
                  bottom: -110,
                  child: _Glow(
                    size: 220,
                    color: onCard.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Kz.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const BrandMark(size: 30),
                          const Spacer(),
                          AnimatedSwitcher(
                            duration: Motion.of(context, Kz.dMedium),
                            child: Text(
                              brand == CardBrand.unknown
                                  ? ''
                                  : _brandShort(brand),
                              key: ValueKey<CardBrand>(brand),
                              style: context.text.titleMedium?.copyWith(
                                color: onCard,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.contactless_rounded, color: onCard),
                      const SizedBox(height: Kz.s2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(number, style: mono),
                      ),
                      const SizedBox(height: Kz.s3),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              holder.isEmpty
                                  ? 'YOUR NAME'
                                  : holder.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelMedium?.copyWith(
                                color: onCard.withValues(alpha: 0.9),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Text(
                            expiry.isEmpty ? 'MM/YY' : expiry,
                            style: context.text.labelMedium?.copyWith(
                              color: onCard.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add card form
// ---------------------------------------------------------------------------

class _AddCardForm extends StatefulWidget {
  const _AddCardForm();

  @override
  State<_AddCardForm> createState() => _AddCardFormState();
}

class _AddCardFormState extends State<_AddCardForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _holder = TextEditingController();
  final TextEditingController _expiry = TextEditingController();
  final TextEditingController _cvv = TextEditingController();
  bool _makeDefault = true;
  bool _saving = false;

  String get _digits => _number.text.replaceAll(RegExp(r'\D'), '');
  CardBrand get _brand => CardBrand.detect(_digits);

  @override
  void initState() {
    super.initState();
    for (final TextEditingController c in <TextEditingController>[
      _number,
      _holder,
      _expiry,
    ]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _number.dispose();
    _holder.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  /// Number shown on the preview: typed digits, the rest as dots.
  String get _previewNumber {
    final String padded = _digits.padRight(16, '•');
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < padded.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(padded[i]);
    }
    return b.toString();
  }

  static bool _luhn(String digits) {
    int sum = 0;
    bool doubleIt = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int d = digits.codeUnitAt(i) - 48;
      if (doubleIt) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      doubleIt = !doubleIt;
    }
    return sum % 10 == 0;
  }

  String? _validateNumber(String? _) {
    final String d = _digits;
    if (d.isEmpty) return 'Enter your card number';
    if (d.length < 13 || d.length > 19 || !_luhn(d)) {
      return 'That card number doesn’t look right';
    }
    return null;
  }

  (int, int)? _parseExpiry() {
    final RegExpMatch? m = RegExp(r'^(\d{2})/(\d{2})$')
        .firstMatch(_expiry.text);
    if (m == null) return null;
    final int month = int.parse(m.group(1)!);
    final int year = 2000 + int.parse(m.group(2)!);
    if (month < 1 || month > 12) return null;
    return (month, year);
  }

  String? _validateExpiry(String? _) {
    final (int, int)? parsed = _parseExpiry();
    if (parsed == null) return 'Use MM/YY';
    final DateTime now = DateTime.now();
    final (int month, int year) = parsed;
    if (year < now.year || (year == now.year && month < now.month)) {
      return 'This card has expired';
    }
    return null;
  }

  String? _validateCvv(String? value) {
    final int needed = _brand == CardBrand.amex ? 4 : 3;
    return (value?.length ?? 0) == needed ? null : '$needed digits';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _saving = true);
    // Simulates the round trip to a payment provider for tokenization.
    await Future<void>.delayed(
      Motion.of(context, const Duration(milliseconds: 900)),
    );
    if (!mounted) return;
    final (int month, int year) = _parseExpiry()!;
    final SavedCard card = AppScope.of(context).payments.addFromInput(
      number: _digits,
      expMonth: month,
      expYear: year,
      holder: _holder.text,
      makeDefault: _makeDefault,
    );
    HapticFeedback.mediumImpact();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text('${card.masked} added')));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Add a card', style: context.text.titleLarge),
            const SizedBox(height: Kz.s4),
            CardFace(
              brand: _brand,
              number: _previewNumber,
              holder: _holder.text,
              expiry: _expiry.text,
            ),
            const SizedBox(height: Kz.s5),
            TextFormField(
              controller: _number,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.creditCardNumber],
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19),
                _CardNumberFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Card number',
                hintText: '4242 4242 4242 4242',
                prefixIcon: Icon(Icons.credit_card_rounded),
              ),
              validator: _validateNumber,
            ),
            const SizedBox(height: Kz.s3),
            TextFormField(
              controller: _holder,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.creditCardName],
              decoration: const InputDecoration(
                labelText: 'Name on card',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (String? v) => (v?.trim().length ?? 0) < 2
                  ? 'Enter the cardholder name'
                  : null,
            ),
            const SizedBox(height: Kz.s3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _expiry,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[
                      AutofillHints.creditCardExpirationDate,
                    ],
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Expiry',
                      hintText: 'MM/YY',
                      prefixIcon: Icon(Icons.event_rounded),
                    ),
                    validator: _validateExpiry,
                  ),
                ),
                const SizedBox(width: Kz.s3),
                Expanded(
                  child: TextFormField(
                    controller: _cvv,
                    enabled: !_saving,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[
                      AutofillHints.creditCardSecurityCode,
                    ],
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    validator: _validateCvv,
                    onFieldSubmitted: (_) => _save(),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              value: _makeDefault,
              onChanged: _saving
                  ? null
                  : (bool v) => setState(() => _makeDefault = v),
              contentPadding: EdgeInsets.zero,
              title: const Text('Use as default payment method'),
            ),
            const SizedBox(height: Kz.s2),
            LoadingButton(
              label: 'Save card',
              leading: const Icon(Icons.lock_rounded),
              loading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: Kz.s3),
            Text(
              'Demo build: use a test number such as 4242 4242 4242 4242 '
              'with any future expiry. Never enter a real card here.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Groups card digits as "4242 4242 4242 4242".
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(' ', '');
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(digits[i]);
    }
    final String text = b.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Inserts the slash in "MM/YY".
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll('/', '');
    final String text = digits.length > 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
