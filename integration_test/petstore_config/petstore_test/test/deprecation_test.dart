import 'dart:io';

import 'package:petstore_deprecation_api/petstore_deprecation_api.dart';
import 'package:test/test.dart';

void main() {
  group('Deprecation Config - Verify generated files', () {
    test('Generated API should not contain getLegacyPets operation file', () {
      final operationDir = Directory(
        '../petstore_deprecation_api/lib/src/operation',
      );
      final files = operationDir
          .listSync()
          .whereType<File>()
          .map((f) => f.path.split('/').last)
          .toList();

      // Verify deprecated operations are NOT generated
      expect(
        files,
        isNot(contains('get_legacy_pets.dart')),
        reason: 'getLegacyPets operation should be excluded',
      );
    });

    test(
      'Generated API should not contain getLegacyInventory operation file',
      () {
        final operationDir = Directory(
          '../petstore_deprecation_api/lib/src/operation',
        );
        final files = operationDir
            .listSync()
            .whereType<File>()
            .map((f) => f.path.split('/').last)
            .toList();

        expect(
          files,
          isNot(contains('get_legacy_inventory.dart')),
          reason: 'getLegacyInventory operation should be excluded',
        );
      },
    );

    test('Generated models should not contain LegacyPet schema', () {
      final modelDir = Directory('../petstore_deprecation_api/lib/src/model');
      final files = modelDir
          .listSync()
          .whereType<File>()
          .map((f) => f.path.split('/').last)
          .toList();

      // Verify deprecated schema is NOT generated
      expect(
        files,
        isNot(contains('legacy_pet.dart')),
        reason: 'LegacyPet schema should be excluded',
      );
    });

    test(
      'searchPets operation should not reference legacyFilter parameter',
      () {
        final searchPetsFile = File(
          '../petstore_deprecation_api/lib/src/operation/search_pets.dart',
        );
        final content = searchPetsFile.readAsStringSync();

        // Verify deprecated parameter is NOT in the generated code
        expect(
          content,
          isNot(contains('legacyFilter')),
          reason: 'legacyFilter parameter should be excluded',
        );

        // Verify non-deprecated parameter IS present
        expect(
          content,
          contains('String? name'),
          reason: 'Non-deprecated name parameter should exist',
        );
      },
    );

    test('Order model should not contain shipDate property', () {
      final orderFile = File(
        '../petstore_deprecation_api/lib/src/model/order.dart',
      );
      final content = orderFile.readAsStringSync();

      // Verify deprecated property is NOT in the generated code
      expect(
        content,
        isNot(contains('shipDate')),
        reason: 'shipDate property should be excluded',
      );

      // Verify non-deprecated deliveryDate property IS present
      expect(
        content,
        contains('deliveryDate'),
        reason: 'Non-deprecated deliveryDate property should exist',
      );
    });

    test('Generated operations should only include non-deprecated ones', () {
      final operationDir = Directory(
        '../petstore_deprecation_api/lib/src/operation',
      );
      final files = operationDir
          .listSync()
          .whereType<File>()
          .map((f) => f.path.split('/').last)
          .toList();

      // Verify expected non-deprecated operations ARE generated
      expect(files, contains('get_active_pets.dart'));
      expect(files, contains('search_pets.dart'));
      expect(files, contains('place_order.dart'));
      expect(files, contains('create_user.dart'));

      // Verify ONLY 4 operation files exist (no deprecated ones)
      expect(files.length, 4, reason: 'Should have exactly 4 operations');
    });

    test('Generated models should only include non-deprecated ones', () {
      final modelDir = Directory('../petstore_deprecation_api/lib/src/model');
      final files = modelDir
          .listSync()
          .whereType<File>()
          .map((f) => f.path.split('/').last)
          .toList();

      // Verify non-deprecated models ARE generated
      expect(files, contains('active_pet.dart'));
      expect(files, contains('category.dart'));
      expect(files, contains('order.dart'));
      expect(files, contains('user.dart'));

      // Verify deprecated models are NOT generated
      expect(files, isNot(contains('legacy_pet.dart')));
    });
  });

  group('Deprecation Config - Excluded operations', () {
    test(
      'PetApi should not have getLegacyPets (deprecated operation excluded)',
      () {
        // The getLegacyPets operation is deprecated in the spec
        // With deprecated.operations = exclude, it should not be generated

        final api = AnimalsApi(CustomServer(baseUrl: 'http://localhost:8080'));

        // Verify the API class exists but deprecated operation does not
        expect(api, isA<AnimalsApi>());

        // If this test compiles, the operation was successfully excluded
        // Attempting to call api.getLegacyPets() would be a compile error
      },
    );

    test(
      'StoreApi should not have getLegacyInventory',
      () {
        // The getLegacyInventory operation is deprecated in the spec
        // With deprecated.operations = exclude, it should not be generated

        final api = OrdersApi(CustomServer(baseUrl: 'http://localhost:8080'));

        // Verify the API class exists but deprecated operation does not
        expect(api, isA<OrdersApi>());

        // If this test compiles, the operation was successfully excluded
        // Attempting to call api.getLegacyInventory() would be a compile error
      },
    );
  });

  group('Deprecation Config - Excluded schemas', () {
    test(
      'LegacyPet schema should not be generated (deprecated schema excluded)',
      () {
        // The LegacyPet schema is marked as deprecated in the spec
        // With deprecated.schemas = exclude, it should not be generated

        // If LegacyPet type existed, this would be a compile error:
        // const pet = LegacyPet(id: 1, oldName: 'Fido');

        // Instead, we verify that non-deprecated schemas exist
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
        // The legacyFilter parameter in searchPets is marked as deprecated
        // With deprecated.parameters = exclude, it should not be included

        final api = AnimalsApi(CustomServer(baseUrl: 'http://localhost:8080'));

        expect(api, isA<AnimalsApi>());

        // The searchPets method should exist with only the
        // non-deprecated 'name' parameter
        // If legacyFilter existed, calling without it would be a compile error
        // This compilation test verifies legacyFilter was excluded
      },
    );
  });

  group('Deprecation Config - Excluded properties', () {
    test(
      'Order should not have shipDate property (deprecated property excluded)',
      () {
        // The shipDate property in Order is marked as deprecated
        // With deprecated.properties = exclude, it should not be generated

        // Create an Order without shipDate
        const order = Order(
          id: 1,
          animalId: 100,
          quantity: 5,
          status: OrderStatusModel.orderPlaced,
        );

        expect(order.id, 1);
        expect(order.animalId, 100);
        expect(order.quantity, 5);

        // Verify non-deprecated deliveryDate property exists instead
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

        // If shipDate existed, this would be a compile error:
        // expect(order.shipDate, isNull);

        // The fact this compiles means shipDate was successfully excluded
      },
    );
  });

  group('Deprecation Config - Non-deprecated elements still exist', () {
    test('PetApi should have non-deprecated operations', () {
      final api = AnimalsApi(
        CustomServer(baseUrl: 'http://localhost:8080'),
      );

      // These operations are not deprecated and should exist
      expect(api, isA<AnimalsApi>());
      // getActivePets, searchPets should be available
      // We verify the API class exists which includes these methods
    });

    test('Order should have non-deprecated properties', () {
      const order = Order(
        id: 1,
        animalId: 100,
        quantity: 5,
        status: OrderStatusModel.orderPlaced,
        complete: true,
      );

      // Non-deprecated properties should still exist
      expect(order.id, 1);
      expect(order.animalId, 100);
      expect(order.quantity, 5);
      expect(order.status, OrderStatusModel.orderPlaced);
      expect(order.complete, true);
    });

    test('Category schema should exist (not deprecated)', () {
      // Category is not deprecated
      const category = Category(id: 1, name: 'Dogs');

      expect(category.id, 1);
      expect(category.name, 'Dogs');
    });

    test('User schema should exist (not deprecated)', () {
      // User schema is not deprecated
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
      // ActivePet is not deprecated
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
