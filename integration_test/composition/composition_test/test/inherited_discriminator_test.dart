import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('PetChoice (oneOf with inherited discriminator)', () {
    group('Cat variant', () {
      late PetChoice petChoice;

      setUp(() {
        petChoice = const PetChoiceCat(
          Cat(
            pet: Pet(petType: 'cat', name: 'Whiskers'),
            catModel: CatModel(meow: 'purr'),
          ),
        );
      });

      test('toJson includes petType discriminator', () {
        final json = petChoice.toJson();
        expect(json, isA<Map<String, Object?>>());
        final map = json! as Map<String, Object?>;
        expect(map['petType'], 'cat');
        expect(map['name'], 'Whiskers');
        expect(map['meow'], 'purr');
      });

      test('json roundtrip', () {
        final json = petChoice.toJson();
        final reconstructed = PetChoice.fromJson(json);
        expect(reconstructed, isA<PetChoiceCat>());
        final cat = (reconstructed as PetChoiceCat).value;
        expect(cat.pet.name, 'Whiskers');
        expect(cat.catModel.meow, 'purr');
      });

      test('fromJson with discriminator dispatches correctly', () {
        final json = {
          'petType': 'cat',
          'name': 'Fluffy',
          'meow': 'meow meow',
        };
        final result = PetChoice.fromJson(json);
        expect(result, isA<PetChoiceCat>());
        final cat = (result as PetChoiceCat).value;
        expect(cat.pet.name, 'Fluffy');
        expect(cat.catModel.meow, 'meow meow');
      });

      test('toForm - explode true', () {
        final form = petChoice.toForm(explode: true, allowEmpty: true);
        expect(form, contains('petType=cat'));
        expect(form, contains('name=Whiskers'));
        expect(form, contains('meow=purr'));
      });

      test('toSimple - explode true', () {
        final simple = petChoice.toSimple(explode: true, allowEmpty: true);
        expect(simple, contains('petType=cat'));
        expect(simple, contains('name=Whiskers'));
        expect(simple, contains('meow=purr'));
      });

      test('currentEncodingShape', () {
        expect(petChoice.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('Dog variant', () {
      late PetChoice petChoice;

      setUp(() {
        petChoice = const PetChoiceDog(
          Dog(
            pet: Pet(petType: 'dog', name: 'Buddy'),
            dogModel: DogModel(bark: 'woof'),
          ),
        );
      });

      test('toJson includes petType discriminator', () {
        final json = petChoice.toJson();
        expect(json, isA<Map<String, Object?>>());
        final map = json! as Map<String, Object?>;
        expect(map['petType'], 'dog');
        expect(map['name'], 'Buddy');
        expect(map['bark'], 'woof');
      });

      test('json roundtrip', () {
        final json = petChoice.toJson();
        final reconstructed = PetChoice.fromJson(json);
        expect(reconstructed, isA<PetChoiceDog>());
        final dog = (reconstructed as PetChoiceDog).value;
        expect(dog.pet.name, 'Buddy');
        expect(dog.dogModel.bark, 'woof');
      });

      test('fromJson with discriminator dispatches correctly', () {
        final json = {
          'petType': 'dog',
          'name': 'Rex',
          'bark': 'bark bark',
        };
        final result = PetChoice.fromJson(json);
        expect(result, isA<PetChoiceDog>());
        final dog = (result as PetChoiceDog).value;
        expect(dog.pet.name, 'Rex');
        expect(dog.dogModel.bark, 'bark bark');
      });

      test('toForm - explode true', () {
        final form = petChoice.toForm(explode: true, allowEmpty: true);
        expect(form, contains('petType=dog'));
        expect(form, contains('name=Buddy'));
        expect(form, contains('bark=woof'));
      });

      test('toSimple - explode true', () {
        final simple = petChoice.toSimple(explode: true, allowEmpty: true);
        expect(simple, contains('petType=dog'));
        expect(simple, contains('name=Buddy'));
        expect(simple, contains('bark=woof'));
      });

      test('currentEncodingShape', () {
        expect(petChoice.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('discriminator dispatch', () {
      test('unknown discriminator value falls back to trying all variants', () {
        // When discriminator value doesn't match any mapping,
        // fallback logic tries each variant until one succeeds
        final json = {
          'petType': 'unknown_animal',
          'name': 'Mystery',
          'meow': 'soft meow',
        };
        final result = PetChoice.fromJson(json);
        // Falls back to Cat since it can parse successfully (has petType, name)
        expect(result, isA<PetChoiceCat>());
        final cat = (result as PetChoiceCat).value;
        expect(cat.pet.name, 'Mystery');
        // petType is passed through (even if unknown to discriminator)
        expect(cat.pet.petType, 'unknown_animal');
        expect(cat.catModel.meow, 'soft meow');
      });

      test('missing required fields throws DecodingException', () {
        // When JSON is missing required fields for all variants, throws
        // Pet requires petType, so this JSON cannot be parsed by Cat or Dog
        final json = {
          'name': 'Anonymous',
          'meow': 'soft meow',
        };
        expect(
          () => PetChoice.fromJson(json),
          throwsA(isA<DecodingException>()),
        );
      });

      test('extra fields are ignored during fallback', () {
        // When discriminator doesn't match but JSON has required fields,
        // variant parses successfully (extra fields are ignored)
        final json = {
          'petType': 'fish',
          'name': 'Goldie',
          'fins': 4, // This is ignored
        };
        final result = PetChoice.fromJson(json);
        // Falls back to Cat since it has petType and name
        expect(result, isA<PetChoiceCat>());
        final cat = (result as PetChoiceCat).value;
        expect(cat.pet.name, 'Goldie');
        expect(cat.pet.petType, 'fish');
        // CatModel.meow is optional, so null is fine
        expect(cat.catModel.meow, isNull);
      });
    });
  });

  group('PetAnyChoice (anyOf with inherited discriminator)', () {
    group('Cat variant', () {
      late PetAnyChoice petAnyChoice;

      setUp(() {
        petAnyChoice = const PetAnyChoice(
          cat: Cat(
            pet: Pet(petType: 'cat', name: 'Mittens'),
            catModel: CatModel(meow: 'purr purr'),
          ),
        );
      });

      test('toJson includes petType discriminator', () {
        final json = petAnyChoice.toJson();
        expect(json, isA<Map<String, Object?>>());
        final map = json! as Map<String, Object?>;
        expect(map['petType'], 'cat');
        expect(map['name'], 'Mittens');
        expect(map['meow'], 'purr purr');
      });

      test('json roundtrip', () {
        final json = petAnyChoice.toJson();
        final reconstructed = PetAnyChoice.fromJson(json);
        expect(reconstructed.cat, isNotNull);
        expect(reconstructed.cat!.pet.name, 'Mittens');
        expect(reconstructed.cat!.catModel.meow, 'purr purr');
      });
    });

    group('Dog variant', () {
      late PetAnyChoice petAnyChoice;

      setUp(() {
        petAnyChoice = const PetAnyChoice(
          dog: Dog(
            pet: Pet(petType: 'dog', name: 'Rover'),
            dogModel: DogModel(bark: 'arf'),
          ),
        );
      });

      test('toJson includes petType discriminator', () {
        final json = petAnyChoice.toJson();
        expect(json, isA<Map<String, Object?>>());
        final map = json! as Map<String, Object?>;
        expect(map['petType'], 'dog');
        expect(map['name'], 'Rover');
        expect(map['bark'], 'arf');
      });

      test('json roundtrip', () {
        final json = petAnyChoice.toJson();
        final reconstructed = PetAnyChoice.fromJson(json);
        expect(reconstructed.dog, isNotNull);
        expect(reconstructed.dog!.pet.name, 'Rover');
        expect(reconstructed.dog!.dogModel.bark, 'arf');
      });
    });
  });

  group('VehicleChoice (oneOf with inferred discriminator values)', () {
    group('Bike variant', () {
      late VehicleChoice vehicleChoice;

      setUp(() {
        vehicleChoice = const VehicleChoiceBike(
          Bike(
            vehicle: Vehicle(vehicleType: 'Bike', brand: 'Trek'),
            bikeModel: BikeModel(gears: 21),
          ),
        );
      });

      test('toJson includes vehicleType discriminator', () {
        final json = vehicleChoice.toJson();
        expect(json, isA<Map<String, Object?>>());
        final map = json! as Map<String, Object?>;
        expect(map['vehicleType'], 'Bike');
        expect(map['brand'], 'Trek');
        expect(map['gears'], 21);
      });

      test('json roundtrip', () {
        final json = vehicleChoice.toJson();
        final reconstructed = VehicleChoice.fromJson(json);
        expect(reconstructed, isA<VehicleChoiceBike>());
        final bike = (reconstructed as VehicleChoiceBike).value;
        expect(bike.vehicle.brand, 'Trek');
        expect(bike.bikeModel.gears, 21);
      });

      test('fromJson with discriminator dispatches correctly', () {
        final json = {
          'vehicleType': 'Bike',
          'brand': 'Giant',
          'gears': 18,
        };
        final result = VehicleChoice.fromJson(json);
        expect(result, isA<VehicleChoiceBike>());
        final bike = (result as VehicleChoiceBike).value;
        expect(bike.vehicle.brand, 'Giant');
        expect(bike.bikeModel.gears, 18);
      });
    });

    group('Truck variant', () {
      late VehicleChoice vehicleChoice;

      setUp(() {
        vehicleChoice = const VehicleChoiceTruck(
          Truck(
            vehicle: Vehicle(vehicleType: 'Truck', brand: 'Volvo'),
            truckModel: TruckModel(capacity: 40000),
          ),
        );
      });

      test('toJson includes vehicleType discriminator', () {
        final json = vehicleChoice.toJson();
        expect(json, isA<Map<String, Object?>>());
        final map = json! as Map<String, Object?>;
        expect(map['vehicleType'], 'Truck');
        expect(map['brand'], 'Volvo');
        expect(map['capacity'], 40000);
      });

      test('json roundtrip', () {
        final json = vehicleChoice.toJson();
        final reconstructed = VehicleChoice.fromJson(json);
        expect(reconstructed, isA<VehicleChoiceTruck>());
        final truck = (reconstructed as VehicleChoiceTruck).value;
        expect(truck.vehicle.brand, 'Volvo');
        expect(truck.truckModel.capacity, 40000);
      });

      test('fromJson with discriminator dispatches correctly', () {
        final json = {
          'vehicleType': 'Truck',
          'brand': 'Mack',
          'capacity': 15000,
        };
        final result = VehicleChoice.fromJson(json);
        expect(result, isA<VehicleChoiceTruck>());
        final truck = (result as VehicleChoiceTruck).value;
        expect(truck.vehicle.brand, 'Mack');
        expect(truck.truckModel.capacity, 15000);
      });
    });
  });

  group('Cat (allOf child with inherited discriminator)', () {
    test('toJson includes all properties from Pet and CatModel', () {
      const cat = Cat(
        pet: Pet(petType: 'cat', name: 'Luna'),
        catModel: CatModel(meow: 'meow'),
      );
      final json = cat.toJson();
      expect(json, isA<Map<String, Object?>>());
      final map = json! as Map<String, Object?>;
      expect(map['petType'], 'cat');
      expect(map['name'], 'Luna');
      expect(map['meow'], 'meow');
    });

    test('fromJson constructs Cat correctly', () {
      final json = {
        'petType': 'cat',
        'name': 'Cleo',
        'meow': 'quiet',
      };
      final cat = Cat.fromJson(json);
      expect(cat.pet.petType, 'cat');
      expect(cat.pet.name, 'Cleo');
      expect(cat.catModel.meow, 'quiet');
    });
  });

  group('Dog (allOf child with inherited discriminator)', () {
    test('toJson includes all properties from Pet and DogModel', () {
      const dog = Dog(
        pet: Pet(petType: 'dog', name: 'Max'),
        dogModel: DogModel(bark: 'loud bark'),
      );
      final json = dog.toJson();
      expect(json, isA<Map<String, Object?>>());
      final map = json! as Map<String, Object?>;
      expect(map['petType'], 'dog');
      expect(map['name'], 'Max');
      expect(map['bark'], 'loud bark');
    });

    test('fromJson constructs Dog correctly', () {
      final json = {
        'petType': 'dog',
        'name': 'Duke',
        'bark': 'growl',
      };
      final dog = Dog.fromJson(json);
      expect(dog.pet.petType, 'dog');
      expect(dog.pet.name, 'Duke');
      expect(dog.dogModel.bark, 'growl');
    });
  });
}
