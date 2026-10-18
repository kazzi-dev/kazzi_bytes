import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_bytes/controllers/account_controllers.dart';
import 'package:kazzi_bytes/data/local_store.dart';
import 'package:kazzi_bytes/data/models.dart';

SavedAddress _address(String id, AddressLabel label) =>
    SavedAddress(id: id, label: label, street: '123 Rizal St', city: 'Manila');

void main() {
  group('CardBrand.detect', () {
    test('recognizes common brands', () {
      expect(CardBrand.detect('4242424242424242'), CardBrand.visa);
      expect(CardBrand.detect('5555555555554444'), CardBrand.mastercard);
      expect(CardBrand.detect('2223003122003222'), CardBrand.mastercard);
      expect(CardBrand.detect('378282246310005'), CardBrand.amex);
      expect(CardBrand.detect('3530111333300000'), CardBrand.jcb);
      expect(CardBrand.detect('6011111111111117'), CardBrand.unknown);
    });
  });

  group('PaymentMethodsController', () {
    test('keeps only display details and persists them', () {
      final LocalStore store = LocalStore.memory();
      final PaymentMethodsController payments = PaymentMethodsController(store);
      final SavedCard card = payments.addFromInput(
        number: '4242 4242 4242 4242',
        expMonth: 8,
        expYear: 2030,
        holder: '  Juan Dela Cruz ',
      );

      expect(card.brand, CardBrand.visa);
      expect(card.last4, '4242');
      expect(card.holder, 'Juan Dela Cruz');
      expect(card.expiry, '08/30');
      expect(store.getString('saved_cards'), isNot(contains('42424242')));

      final PaymentMethodsController reloaded = PaymentMethodsController(store);
      expect(reloaded.defaultItem?.last4, '4242');
    });
  });

  group('AddressesController', () {
    test('first address becomes the default; removal falls back', () {
      final AddressesController addresses = AddressesController(
        LocalStore.memory(),
      );
      final SavedAddress home = _address('a', AddressLabel.home);
      final SavedAddress work = _address('b', AddressLabel.work);
      addresses
        ..save(home)
        ..save(work);
      expect(addresses.isDefault(home), isTrue);

      addresses.setDefault(work);
      expect(addresses.isDefault(work), isTrue);

      final int index = addresses.remove(work);
      expect(addresses.defaultItem, home);

      addresses.restore(work, index, wasDefault: true);
      expect(addresses.items.map((SavedAddress a) => a.id), <String>['a', 'b']);
      expect(addresses.isDefault(work), isTrue);
    });

    test('editing replaces the address in place', () {
      final AddressesController addresses = AddressesController(
        LocalStore.memory(),
      );
      addresses.save(_address('a', AddressLabel.home));
      addresses.save(
        const SavedAddress(
          id: 'a',
          label: AddressLabel.other,
          title: 'Lola’s house',
          street: '9 Mabini',
          city: 'Cebu',
        ),
      );
      expect(addresses.items.single.displayTitle, 'Lola’s house');
    });
  });

  group('NotificationSettingsController', () {
    test('uses defaults, then remembers changes', () {
      final LocalStore store = LocalStore.memory();
      final NotificationSettingsController settings =
          NotificationSettingsController(store);
      expect(settings.isEnabled(NotificationTopic.orderUpdates), isTrue);
      expect(settings.isEnabled(NotificationTopic.newItems), isFalse);

      settings.set(NotificationTopic.orderUpdates, false);
      settings.setAll(false);
      expect(settings.allOff, isTrue);
      expect(
        NotificationSettingsController(store)
            .isEnabled(NotificationTopic.orderUpdates),
        isFalse,
      );
    });
  });
}
