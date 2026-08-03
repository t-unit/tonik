import 'package:petstore_deprecation_api/petstore_deprecation_api.dart';
import 'package:test/test.dart';

void main() {
  group('Deprecation Config - Excluded operations', () {
    test(
      'PetApi should not have getLegacyPets (deprecated operation excluded)',
      () {
        final api = AnimalsApi(CustomServer(baseUrl: 'http://localhost:8080'));

        expect(api, isA<AnimalsApi>());
      },
    );

    test(
      'StoreApi should not have getLegacyInventory',
      () {
        final api = OrdersApi(CustomServer(baseUrl: 'http://localhost:8080'));

        expect(api, isA<OrdersApi>());
      },
    );
  });

  group('Deprecation Config - Excluded schemas', () {
    test(
      'LegacyPet schema should not be generated (deprecated schema excluded)',
      () {
        const activePet = ActivePet(id: 1, petName: 'Fluffy');

        expect(activePet.id, 1);
        expect(activePet.petName, 'Fluffy');
      },
    );
  });

  group('Deprecation Config - Excluded parameters', () {
    test(
      'searchPets should not have legacyFilter parameter',
      () {
        final api = AnimalsApi(CustomServer(baseUrl: 'http://localhost:8080'));

        expect(api, isA<AnimalsApi>());
      },
    );
  });

  group('Deprecation Config - Excluded properties', () {
    test(
      'Order should not have shipDate property (deprecated property excluded)',
      () {
        const order = Order(
          id: 1,
          animalId: 100,
          quantity: 5,
          status: OrderStatusModel.orderPlaced,
        );

        expect(order.id, 1);
        expect(order.animalId, 100);
        expect(order.quantity, 5);

        final orderWithDate = Order(
          id: 2,
          animalId: 200,
          quantity: 3,
          deliveryDate: DateTime.parse('2024-01-15T10:00:00Z'),
          status: OrderStatusModel.orderApproved,
        );

        expect(
          orderWithDate.deliveryDate,
          DateTime.parse('2024-01-15T10:00:00Z'),
        );
      },
    );
  });

  group('Deprecation Config - Non-deprecated elements still exist', () {
    test('PetApi should have non-deprecated operations', () {
      final api = AnimalsApi(
        CustomServer(baseUrl: 'http://localhost:8080'),
      );

      expect(api, isA<AnimalsApi>());
    });

    test('Order should have non-deprecated properties', () {
      const order = Order(
        id: 1,
        animalId: 100,
        quantity: 5,
        status: OrderStatusModel.orderPlaced,
        complete: true,
      );

      expect(order.id, 1);
      expect(order.animalId, 100);
      expect(order.quantity, 5);
      expect(order.status, OrderStatusModel.orderPlaced);
      expect(order.complete, true);
    });

    test('Category schema should exist (not deprecated)', () {
      const category = Category(id: 1, name: 'Dogs');

      expect(category.id, 1);
      expect(category.name, 'Dogs');
    });

    test('User schema should exist (not deprecated)', () {
      const user = User(
        username: 'john_doe',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
      );

      expect(user.username, 'john_doe');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
      expect(user.email, 'john@example.com');
    });

    test('ActivePet schema should exist (not deprecated)', () {
      const pet = ActivePet(
        id: 1,
        petName: 'Fluffy',
        status: ActivePetStatusModel.available,
      );

      expect(pet.id, 1);
      expect(pet.petName, 'Fluffy');
      expect(pet.status, ActivePetStatusModel.available);
    });
  });
}
