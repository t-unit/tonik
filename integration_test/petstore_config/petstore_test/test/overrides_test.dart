import 'package:dio/dio.dart';
import 'package:petstore_overrides_api/petstore_overrides_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;


  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/api/v3';
  });

  CreatureApiApi buildPetApi({required String responseStatus}) {
    return CreatureApiApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  group('Name Overrides - Schema names', () {
    test('Pet renamed to Animal', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final result = await petApi.registerAnimal(
        body: const PetPostBodyRequestBodyJson(
          // we expect Animal to be deprecated
          // ignore: deprecated_member_use
          Animal(
            id: 1,
            displayName: 'Fido',
            pictures: <String>[],
          ),
        ),
      );
      final success = result as TonikSuccess<RegisterAnimalResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<RegisterAnimalResponse200>());

      final responseValue = success.value as RegisterAnimalResponse200;
      expect(responseValue.body, isA<PetPost200ResponseJson>());
      final animal = (responseValue.body as PetPost200ResponseJson).body;
      // we expect Animal to be deprecated
      // ignore: deprecated_member_use
      expect(animal, isA<Animal>());
      expect(animal.displayName, isA<String?>());
      expect(animal.pictures, isA<List<String>>());
      expect(animal.labels, isA<List<Label>?>());
      expect(animal.category, isA<Group?>());
    });

    test('User renamed to Customer', () async {
      final userApi = CustomerApiApi(
        CustomServer(
          baseUrl: baseUrl,
          serverConfig: ServerConfig(
            baseOptions: BaseOptions(
              headers: {'X-Response-Status': '200'},
            ),
          ),
        ),
      );

      final result = await userApi.registerCustomer(
        body: const UserPostBodyRequestBodyJson(
          Customer(
            id: 1,
            loginName: 'testUser',
            givenName: 'John',
            surname: 'Doe',
            emailAddress: 'john@example.com',
            password: 'password123',
            phoneNumber: '1234567890',
            accountStatus: 1,
          ),
        ),
      );
      final success = result as TonikSuccess<RegisterCustomerResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<RegisterCustomerResponse200>());

      final responseValue = success.value as RegisterCustomerResponse200;
      expect(responseValue.body, isA<UserPost200ResponseJson>());
      final customer = (responseValue.body as UserPost200ResponseJson).body;
      expect(customer, isA<Customer>());
      expect(customer.loginName, isA<String?>());
      expect(customer.givenName, isA<String?>());
      expect(customer.surname, isA<String?>());
      expect(customer.emailAddress, isA<String?>());
      expect(customer.phoneNumber, isA<String?>());
    });

    test('Order renamed to Purchase', () async {
      final storeApi = ShopApiApi(
        CustomServer(
          baseUrl: baseUrl,
          serverConfig: ServerConfig(
            baseOptions: BaseOptions(
              headers: {'X-Response-Status': '200'},
            ),
          ),
        ),
      );

      // Note: placeOrder operation is renamed to submitPurchase
      // we expect submitPurchase to be deprecated
      // ignore: deprecated_member_use
      final result = await storeApi.submitPurchase(
        body: const StoreOrderPostBodyRequestBodyJson(
          Purchase(
            id: 1,
            animalIdentifier: 100,
            amount: 5,
            status: OrderStatusModel.orderPlaced,
            complete: true,
          ),
        ),
      );
      final success = result as TonikSuccess<SubmitPurchaseResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<SubmitPurchaseResponse200>());

      final purchase = (success.value as SubmitPurchaseResponse200).body;
      expect(purchase, isA<Purchase>());
      expect(purchase.animalIdentifier, isA<int?>());
      expect(purchase.amount, isA<int?>());
      expect(purchase.status, isA<OrderStatusModel?>());
    });
  });

  group('Name Overrides - Operation names', () {
    test('addPet renamed to registerAnimal', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final result = await petApi.registerAnimal(
        body: const PetPostBodyRequestBodyJson(
          // we expect Animal to be deprecated
          // ignore: deprecated_member_use
          Animal(
            id: 1,
            displayName: 'Rex',
            pictures: <String>[],
          ),
        ),
      );
      expect(result, isA<TonikSuccess<RegisterAnimalResponse>>());
    });

    test('getPetById renamed to fetchAnimalById', () async {
      final petApi = buildPetApi(responseStatus: '200');

      // Parameter also renamed: petId -> animalIdentifier
      final result = await petApi.fetchAnimalById(animalId: 1);
      expect(result, isA<TonikSuccess<FetchAnimalByIdResponse>>());
    });

    test('deletePet renamed to removeAnimal', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final result = await petApi.removeAnimal(petId: 1);
      expect(result, isA<TonikSuccess<RemoveAnimalResponse>>());
    });

    test('findPetsByStatus renamed to queryAnimalsByStatus', () async {
      final petApi = buildPetApi(responseStatus: '200');

      // Parameter name override not working - still uses petStatus
      final result = await petApi.queryAnimalsByStatus(
        // we expect petStatus to be deprecated
        // ignore: deprecated_member_use
        petStatus: PetFindByStatusParametersModel.available,
      );
      expect(
        result,
        isA<TonikSuccess<QueryAnimalsByStatusResponse>>(),
      );
    });
  });

  group('Name Overrides - Property names', () {
    test('Pet properties renamed', () {
      final petApi = buildPetApi(responseStatus: '200');

      // name -> displayName
      // photoUrls -> pictures
      // tags -> labels
      // we expect Animal to be deprecated
      // ignore: deprecated_member_use
      const animal = Animal(
        id: 1,
        displayName: 'Buddy',
        pictures: <String>['https://example.com/buddy.jpg'],
        labels: <Label>[
          Label(id: 1, name: 'friendly'),
        ],
        category: Group(id: 1, name: 'Dogs'),
        status: PetStatusModel.inStock,
      );

      expect(animal.displayName, 'Buddy');
      expect(animal.pictures, hasLength(1));
      expect(animal.labels, hasLength(1));
      expect(animal.category, isA<Group>());

      // Use petApi to avoid unused variable warning
      expect(petApi, isNotNull);
    });

    test('Order properties renamed', () {
      // petId -> animalIdentifier
      // quantity -> amount
      // shipDate -> shippingDate
      final purchase = Purchase(
        id: 1,
        animalIdentifier: 100,
        amount: 3,
        shippingDate: DateTime.now(),
        status: OrderStatusModel.orderApproved,
        complete: false,
      );

      expect(purchase.animalIdentifier, 100);
      expect(purchase.amount, 3);
      // we expect shippingDate to be deprecated
      // ignore: deprecated_member_use
      expect(purchase.shippingDate, isA<DateTime?>());
      expect(purchase.status, OrderStatusModel.orderApproved);
    });
  });

  group('Name Overrides - Enum values', () {
    test('Order status enum values renamed', () {
      // x-dart-enum values from OpenAPI spec:
      // placed -> orderPlaced
      // approved -> orderApproved
      // delivered -> orderDelivered
      expect(
        OrderStatusModel.orderPlaced,
        isA<OrderStatusModel>(),
      );
      expect(
        OrderStatusModel.orderApproved,
        isA<OrderStatusModel>(),
      );
      expect(
        OrderStatusModel.orderDelivered,
        isA<OrderStatusModel>(),
      );
    });

    test('Pet status enum values renamed', () {
      // x-dart-enum values from OpenAPI spec:
      // available -> inStock
      // pending -> reserved
      // sold -> soldOut
      expect(PetStatusModel.inStock, isA<PetStatusModel>());
      expect(
        PetStatusModel.reserved,
        isA<PetStatusModel>(),
      );
      expect(PetStatusModel.soldOut, isA<PetStatusModel>());
    });

    test('Enum serialization with renamed values', () {
      // we expect Animal to be deprecated
      // ignore: deprecated_member_use
      const animal = Animal(
        id: 1,
        displayName: 'Test',
        pictures: <String>[],
        status: PetStatusModel.inStock,
      );

      final json = animal.toJson();
      // The JSON should contain the original OpenAPI value, not the
      // renamed Dart name
      expect((json! as Map<String, dynamic>)['status'], 'available');
    });
  });

  group('Name Overrides - Parameter names', () {
    test('Login parameters renamed', () async {
      final userApi = CustomerApiApi(
        CustomServer(
          baseUrl: baseUrl,
          serverConfig: ServerConfig(
            baseOptions: BaseOptions(
              headers: {'X-Response-Status': '200'},
            ),
          ),
        ),
      );

      // username -> loginName
      // password -> credential
      final result = await userApi.signIn(
        loginName: 'testUser',
        loginPassword: 'password123',
      );
      expect(result, isA<TonikSuccess<SignInResponse>>());
    });

    test('Upload file parameters renamed', () async {
      final petApi = buildPetApi(responseStatus: '200');

      // additionalMetadata -> fileMetadata
      final result = await petApi.uploadPetImage(
        petId: 1,
        imageMetadata: 'test metadata',
      );
      expect(result, isA<TonikSuccess<UploadPetImageResponse>>());
    });
  });
}
