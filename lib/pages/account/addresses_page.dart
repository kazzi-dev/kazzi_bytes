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

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  static Future<void> openEditor(
    BuildContext context, {
    SavedAddress? initial,
  }) async {
    await showFormSheet<void>(
      context,
      (BuildContext sheetContext) => _AddressForm(
        initial: initial,
        initialIsDefault:
            initial != null &&
            AppScope.of(context).addresses.isDefault(initial),
      ),
    );
  }

  void _delete(BuildContext context, SavedAddress address) {
    final AddressesController addresses = AppScope.of(context).addresses;
    final bool wasDefault = addresses.isDefault(address);
    HapticFeedback.lightImpact();
    final int index = addresses.remove(address);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          persist: false,
          content: Text('Removed ${address.displayTitle}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () =>
                addresses.restore(address, index, wasDefault: wasDefault),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final AddressesController addresses = AppScope.of(context).addresses;

    return ListenableBuilder(
      listenable: addresses,
      builder: (BuildContext context, Widget? _) {
        final List<SavedAddress> items = addresses.items;
        return AccountPageScaffold(
          title: 'Saved addresses',
          bottomAction: LoadingButton(
            label: 'Add new address',
            leading: const Icon(Icons.add_location_alt_rounded),
            onPressed: () => openEditor(context),
          ),
          children: <Widget>[
            if (items.isEmpty)
              const EmptyState(
                icon: Icons.location_on_rounded,
                accents: <IconData>[
                  Icons.home_rounded,
                  Icons.work_rounded,
                  Icons.place_rounded,
                ],
                title: 'No saved addresses yet',
                message:
                    'Save home, work or anywhere you order from, so checkout '
                    'takes one tap.',
              )
            else ...<Widget>[
              for (final SavedAddress address in items)
                Padding(
                  key: ValueKey<String>(address.id),
                  padding: const EdgeInsets.only(bottom: Kz.s3),
                  child: Dismissible(
                    key: ValueKey<String>('dismiss-${address.id}'),
                    direction: DismissDirection.endToStart,
                    background: const _DeleteBackground(),
                    onDismissed: (_) => _delete(context, address),
                    child: _AddressCard(
                      address: address,
                      isDefault: addresses.isDefault(address),
                      onEdit: () => openEditor(context, initial: address),
                      onSetDefault: () {
                        HapticFeedback.selectionClick();
                        addresses.setDefault(address);
                      },
                      onDelete: () => _delete(context, address),
                    ),
                  ),
                ),
              const SizedBox(height: Kz.s2),
              const InfoNote(
                icon: Icons.swipe_left_rounded,
                text:
                    'Tap an address to edit it, or swipe left to remove it. '
                    'Your default address is filled in automatically.',
              ),
            ],
          ],
        );
      },
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isDefault,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  final SavedAddress address;
  final bool isDefault;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    return SurfaceCard(
      onTap: onEdit,
      borderColor: isDefault ? colors.primary : null,
      padding: const EdgeInsets.fromLTRB(Kz.s4, Kz.s3, Kz.s1, Kz.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(Kz.rSm),
            ),
            child: Icon(address.label.icon, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: Kz.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: Kz.s2,
                  runSpacing: Kz.s1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(address.displayTitle, style: context.text.titleMedium),
                    AnimatedSwitcher(
                      duration: Motion.of(context, Kz.dMedium),
                      child: isDefault
                          ? const KzTag(
                              key: ValueKey<String>('default'),
                              label: 'Default',
                              icon: Icons.check_rounded,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  address.oneLine,
                  style: context.text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (address.notes.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: Kz.s1),
                  Text(
                    '“${address.notes.trim()}”',
                    style: context.text.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More options for ${address.displayTitle}',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (String value) => switch (value) {
              'edit' => onEdit(),
              'default' => onSetDefault(),
              _ => onDelete(),
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
              if (!isDefault)
                const PopupMenuItem<String>(
                  value: 'default',
                  child: Text('Set as default'),
                ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: Kz.s6),
      decoration: BoxDecoration(
        color: context.colors.error,
        borderRadius: BorderRadius.circular(Kz.rLg),
      ),
      child: Icon(Icons.delete_outline_rounded, color: context.colors.onError),
    );
  }
}

class _AddressForm extends StatefulWidget {
  const _AddressForm({this.initial, this.initialIsDefault = false});

  final SavedAddress? initial;
  final bool initialIsDefault;

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AddressLabel _label = widget.initial?.label ?? AddressLabel.home;
  late final TextEditingController _title = TextEditingController(
    text: widget.initial?.title,
  );
  late final TextEditingController _street = TextEditingController(
    text: widget.initial?.street,
  );
  late final TextEditingController _details = TextEditingController(
    text: widget.initial?.details,
  );
  late final TextEditingController _city = TextEditingController(
    text: widget.initial?.city,
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.initial?.notes,
  );
  late bool _makeDefault = widget.initialIsDefault;

  @override
  void dispose() {
    _title.dispose();
    _street.dispose();
    _details.dispose();
    _city.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.heavyImpact();
      return;
    }
    final AddressesController addresses = AppScope.of(context).addresses;
    addresses.save(
      SavedAddress(
        id: widget.initial?.id ?? AddressesController.newId(),
        label: _label,
        title: _label == AddressLabel.other ? _title.text.trim() : '',
        street: _street.text.trim(),
        details: _details.text.trim(),
        city: _city.text.trim(),
        notes: _notes.text.trim(),
      ),
      makeDefault: _makeDefault,
    );
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  String? _required(String? value, String message) =>
      (value?.trim().isEmpty ?? true) ? message : null;

  @override
  Widget build(BuildContext context) {
    final bool editing = widget.initial != null;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            editing ? 'Edit address' : 'New address',
            style: context.text.titleLarge,
          ),
          const SizedBox(height: Kz.s5),
          SlidingSegmented<AddressLabel>(
            value: _label,
            onChanged: (AddressLabel l) => setState(() => _label = l),
            segments: <Segment<AddressLabel>>[
              for (final AddressLabel l in AddressLabel.values)
                Segment<AddressLabel>(value: l, label: l.label, icon: l.icon),
            ],
          ),
          AnimatedSize(
            duration: Motion.of(context, Kz.dMedium),
            curve: Kz.standard,
            child: _label == AddressLabel.other
                ? Padding(
                    padding: const EdgeInsets.only(top: Kz.s3),
                    child: TextFormField(
                      controller: _title,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Name this place',
                        hintText: 'e.g. Mom’s place',
                        prefixIcon: Icon(Icons.bookmark_outline_rounded),
                      ),
                      validator: (String? v) =>
                          _required(v, 'Give this address a name'),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: Kz.s3),
          TextFormField(
            controller: _street,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.streetAddressLine1],
            decoration: const InputDecoration(
              labelText: 'Street address',
              prefixIcon: Icon(Icons.signpost_outlined),
            ),
            validator: (String? v) => _required(v, 'Enter the street address'),
          ),
          const SizedBox(height: Kz.s3),
          TextFormField(
            controller: _details,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.streetAddressLine2],
            decoration: const InputDecoration(
              labelText: 'Unit, floor or landmark (optional)',
              prefixIcon: Icon(Icons.apartment_rounded),
            ),
          ),
          const SizedBox(height: Kz.s3),
          TextFormField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.addressCity],
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_city_rounded),
            ),
            validator: (String? v) => _required(v, 'Enter the city'),
          ),
          const SizedBox(height: Kz.s3),
          TextFormField(
            controller: _notes,
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Gate code, which building, etc.',
              prefixIcon: Icon(Icons.sticky_note_2_outlined),
            ),
          ),
          SwitchListTile(
            value: _makeDefault,
            onChanged: (bool v) => setState(() => _makeDefault = v),
            contentPadding: EdgeInsets.zero,
            title: const Text('Set as default address'),
          ),
          const SizedBox(height: Kz.s3),
          LoadingButton(
            label: editing ? 'Save changes' : 'Save address',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
