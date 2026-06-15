import 'package:defaulted_api/defaulted_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

Dio _newDio({required void Function(RequestOptions) onRequest}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest(options);
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  group('DefaultedPrimitives — primitive const defaults', () {
    test('constructor with no args yields all defaults', () {
      const value = DefaultedPrimitives();
      expect(value.name, 'anon');
      expect(value.count, 0);
      expect(value.rate, 1.5);
      expect(value.active, isTrue);
      expect(value.nickname, isNull);
      expect(value.title, 'Mx.');
    });

    test('public static const exposes default value', () {
      expect(DefaultedPrimitives.nameDefault, 'anon');
      expect(DefaultedPrimitives.countDefault, 0);
      expect(DefaultedPrimitives.rateDefault, 1.5);
      expect(DefaultedPrimitives.activeDefault, isTrue);
      expect(DefaultedPrimitives.titleDefault, 'Mx.');
    });

    test('fromJson with empty map yields all defaults', () {
      final value = DefaultedPrimitives.fromJson(const <String, Object?>{});
      expect(value.name, 'anon');
      expect(value.count, 0);
      expect(value.rate, 1.5);
      expect(value.active, isTrue);
      expect(value.nickname, isNull);
      expect(value.title, 'Mx.');
    });

    test('fromJson supplied keys override defaults', () {
      final value = DefaultedPrimitives.fromJson(const <String, Object?>{
        'name': 'alice',
        'count': 7,
        'rate': 9.25,
        'active': false,
      });
      expect(value.name, 'alice');
      expect(value.count, 7);
      expect(value.rate, 9.25);
      expect(value.active, isFalse);
    });

    test(
      'explicit null on a nullable defaulted field decodes to null, '
      'NOT the default',
      () {
        final value = DefaultedPrimitives.fromJson(const <String, Object?>{
          'title': null,
        });
        expect(value.title, isNull);
      },
    );

    test(
      'missing key on nullable defaulted field falls through to default',
      () {
        final value = DefaultedPrimitives.fromJson(const <String, Object?>{
          'name': 'alice',
        });
        expect(value.title, 'Mx.');
      },
    );

    test(
      'nickname (nullable + default: null) carries no default — '
      'explicit null decodes to null',
      () {
        final value = DefaultedPrimitives.fromJson(const <String, Object?>{
          'nickname': null,
        });
        expect(value.nickname, isNull);
      },
    );

    test(
      'nickname (nullable + default: null) carries no default — '
      'missing key decodes to null',
      () {
        final value = DefaultedPrimitives.fromJson(const <String, Object?>{});
        expect(value.nickname, isNull);
      },
    );

    test('missing key falls through to default', () {
      final value = DefaultedPrimitives.fromJson(const <String, Object?>{
        'name': 'alice',
      });
      expect(value.name, 'alice');
      expect(value.count, 0);
      expect(value.rate, 1.5);
      expect(value.active, isTrue);
      expect(value.nickname, isNull);
      expect(value.title, 'Mx.');
    });

    test('round-trip: fromJson(toJson(...)) yields an equal instance', () {
      const original = DefaultedPrimitives();
      final encoded = original.toJson()! as Map<String, Object?>;
      final decoded = DefaultedPrimitives.fromJson(encoded);
      expect(decoded, original);
    });

    test('round-trip with custom values', () {
      const original = DefaultedPrimitives(
        name: 'alice',
        count: 5,
        rate: 2.5,
        active: false,
        nickname: 'al',
        title: 'Dr.',
      );
      final encoded = original.toJson()! as Map<String, Object?>;
      final decoded = DefaultedPrimitives.fromJson(encoded);
      expect(decoded, original);
    });
  });

  group('DefaultedPrimitives.fromSimple', () {
    test('all keys present uses supplied values', () {
      final value = DefaultedPrimitives.fromSimple(
        'name=alice,count=7,rate=9.25,active=false,nickname=al,title=Dr.',
        explode: true,
      );
      expect(value.name, 'alice');
      expect(value.count, 7);
      expect(value.rate, 9.25);
      expect(value.active, isFalse);
      expect(value.nickname, 'al');
      expect(value.title, 'Dr.');
    });

    test('some keys absent fall through to defaults', () {
      final value = DefaultedPrimitives.fromSimple(
        'name=alice',
        explode: true,
      );
      expect(value.name, 'alice');
      expect(value.count, 0);
      expect(value.rate, 1.5);
      expect(value.active, isTrue);
      expect(value.nickname, isNull);
      expect(value.title, 'Mx.');
    });
  });

  group('DefaultedPrimitives.fromForm', () {
    test('all keys present uses supplied values', () {
      final value = DefaultedPrimitives.fromForm(
        'name=alice&count=7&rate=9.25&active=false&nickname=al&title=Dr.',
        explode: true,
      );
      expect(value.name, 'alice');
      expect(value.count, 7);
      expect(value.rate, 9.25);
      expect(value.active, isFalse);
      expect(value.nickname, 'al');
      expect(value.title, 'Dr.');
    });

    test('some keys absent fall through to defaults', () {
      final value = DefaultedPrimitives.fromForm(
        'name=alice',
        explode: true,
      );
      expect(value.name, 'alice');
      expect(value.count, 0);
      expect(value.rate, 1.5);
      expect(value.active, isTrue);
      expect(value.nickname, isNull);
      expect(value.title, 'Mx.');
    });
  });

  group('Subscription — enum const defaults', () {
    test('constructor with no args yields enum defaults', () {
      const value = Subscription();
      expect(value.priority, SubscriptionPriorityModel.medium);
      expect(value.level, SubscriptionLevelModel.two);
      expect(value.status, Status.active);
      expect(value.tier, Tier.two);
      expect(value.fallbackPriority, isNull);
    });

    test('public static const exposes enum default values', () {
      expect(Subscription.priorityDefault, SubscriptionPriorityModel.medium);
      expect(Subscription.levelDefault, SubscriptionLevelModel.two);
      expect(Subscription.statusDefault, Status.active);
      expect(Subscription.tierDefault, Tier.two);
    });

    test('fromJson with empty map yields enum defaults', () {
      final value = Subscription.fromJson(const <String, Object?>{});
      expect(value.priority, SubscriptionPriorityModel.medium);
      expect(value.level, SubscriptionLevelModel.two);
      expect(value.status, Status.active);
      expect(value.tier, Tier.two);
      expect(value.fallbackPriority, isNull);
    });

    test('fromJson supplied wire values override the defaults', () {
      final value = Subscription.fromJson(const <String, Object?>{
        'priority': 'high',
        'level': 3,
        'status': 'inactive',
        'tier': 3,
      });
      expect(value.priority, SubscriptionPriorityModel.high);
      expect(value.level, SubscriptionLevelModel.three);
      expect(value.status, Status.inactive);
      expect(value.tier, Tier.three);
    });

    test('round-trip: fromJson(toJson(...)) yields an equal instance', () {
      final original = Subscription(
        startsAt: DateTime.utc(2024),
        homepage: Uri.parse('https://example.com'),
        pricing: Subscription.pricingDefault,
      );
      final encoded = original.toJson()! as Map<String, Object?>;
      final decoded = Subscription.fromJson(encoded);
      expect(decoded, original);
    });

    test(
      'default value NOT in enum values is dropped — the field keeps the '
      'no-default behaviour and remains null when the key is missing',
      () {
        final value = Subscription.fromJson(const <String, Object?>{});
        expect(value.fallbackPriority, isNull);
      },
    );
  });

  group('Filters — collection const defaults', () {
    test('constructor with no args yields all defaults', () {
      const value = Filters();
      expect(value.tags, const <String>['new', 'featured']);
      expect(value.counts, const <String, int>{'x': 1, 'y': 2});
      expect(
        value.raw,
        const <String, Object?>{
          'any': 'value',
          'nested': <Object?>[1, 2, 3],
        },
      );
    });

    test('public static const exposes default value', () {
      expect(Filters.tagsDefault, const <String>['new', 'featured']);
      expect(Filters.countsDefault, const <String, int>{'x': 1, 'y': 2});
      expect(
        Filters.rawDefault,
        const <String, Object?>{
          'any': 'value',
          'nested': <Object?>[1, 2, 3],
        },
      );
    });

    test('defaults are identical-by-reference across instances', () {
      const a = Filters();
      const b = Filters();
      expect(identical(a.tags, b.tags), isTrue);
      expect(identical(a.counts, b.counts), isTrue);
      expect(identical(a.raw, b.raw), isTrue);
    });

    test('static const default is identical to constructor-default field', () {
      const value = Filters();
      expect(identical(value.tags, Filters.tagsDefault), isTrue);
      expect(identical(value.counts, Filters.countsDefault), isTrue);
      expect(identical(value.raw, Filters.rawDefault), isTrue);
    });

    test('fromJson with empty map yields all defaults', () {
      final value = Filters.fromJson(const <String, Object?>{});
      expect(value.tags, const <String>['new', 'featured']);
      expect(value.counts, const <String, int>{'x': 1, 'y': 2});
      expect(
        value.raw,
        const <String, Object?>{
          'any': 'value',
          'nested': <Object?>[1, 2, 3],
        },
      );
    });

    test('fromJson preserves const identity of defaults on missing keys', () {
      final value = Filters.fromJson(const <String, Object?>{});
      expect(identical(value.tags, Filters.tagsDefault), isTrue);
      expect(identical(value.counts, Filters.countsDefault), isTrue);
      expect(identical(value.raw, Filters.rawDefault), isTrue);
    });

    test('fromJson supplied keys override defaults', () {
      final value = Filters.fromJson(const <String, Object?>{
        'tags': <Object?>['custom'],
        'counts': <String, Object?>{'z': 9},
        'raw': <String, Object?>{'kind': 'override'},
      });
      expect(value.tags, const <String>['custom']);
      expect(value.counts, const <String, int>{'z': 9});
      expect(value.raw, const <String, Object?>{'kind': 'override'});
    });

    test('missing key falls through to default; supplied key uses value', () {
      final value = Filters.fromJson(const <String, Object?>{
        'tags': <Object?>['alpha', 'beta'],
      });
      expect(value.tags, const <String>['alpha', 'beta']);
      expect(value.counts, const <String, int>{'x': 1, 'y': 2});
      expect(
        value.raw,
        const <String, Object?>{
          'any': 'value',
          'nested': <Object?>[1, 2, 3],
        },
      );
    });

    test('round-trip: fromJson(toJson(...)) yields an equal instance', () {
      const original = Filters();
      final encoded = original.toJson()! as Map<String, Object?>;
      final decoded = Filters.fromJson(encoded);
      expect(decoded, original);
    });

    test('round-trip with custom values', () {
      const original = Filters(
        tags: <String>['alpha', 'beta'],
        counts: <String, int>{'a': 10},
        raw: <String, Object?>{'kind': 'custom'},
      );
      final encoded = original.toJson()! as Map<String, Object?>;
      final decoded = Filters.fromJson(encoded);
      expect(decoded, original);
    });
  });

  group(
    'operation parameter primitive defaults — public static const accessors',
    () {
      test('query string default is reachable', () {
        expect(ListThings.regionDefault, 'us');
      });

      test('required-with-default query integer default is reachable', () {
        expect(ListThings.pageDefault, 1);
      });

      test('header integer default is reachable', () {
        expect(ListThings.retriesDefault, 5);
      });

      test('cookie boolean default is reachable', () {
        expect(ListThings.trackingDefault, isFalse);
      });

      test('path string default is reachable', () {
        expect(GetThing.idDefault, 'x');
      });
    },
  );

  group(
    'operation parameter runtime-fallback defaults — DateTime via static '
    'getter',
    () {
      test('query date-time default is reachable via the runtime getter', () {
        expect(ListThings.sinceDefault, DateTime.utc(2024));
      });
    },
  );

  group('operation call() with no arguments uses defaults', () {
    test(
      'omitted query/header/cookie parameters serialise the default values',
      () async {
        RequestOptions? captured;
        final dio = _newDio(onRequest: (o) => captured = o);

        await ListThings(dio).call();

        final options = captured!;
        final uri = options.uri;

        expect(uri.queryParameters['region'], 'us');
        expect(uri.queryParameters['page'], '1');

        final headers = options.headers;
        expect(headers['X-Retries'], '5');

        final cookie = headers['Cookie']! as String;
        expect(cookie, contains('tracking=false'));
      },
    );

    test(
      'omitted path parameter substitutes the default into the URL template',
      () async {
        RequestOptions? captured;
        final dio = _newDio(onRequest: (o) => captured = o);

        await GetThing(dio).call();

        expect(captured!.uri.path, endsWith('/things/x'));
      },
    );
  });

  group('operation call() with explicit args overrides defaults', () {
    test('explicit query/header/cookie values replace the defaults', () async {
      RequestOptions? captured;
      final dio = _newDio(onRequest: (o) => captured = o);

      await ListThings(dio).call(
        region: 'eu',
        page: 7,
        retries: 9,
        tracking: true,
      );

      final options = captured!;
      final uri = options.uri;

      expect(uri.queryParameters['region'], 'eu');
      expect(uri.queryParameters['page'], '7');
      expect(options.headers['X-Retries'], '9');
      expect(options.headers['Cookie']! as String, contains('tracking=true'));
    });

    test('explicit path value replaces the default in the URL', () async {
      RequestOptions? captured;
      final dio = _newDio(onRequest: (o) => captured = o);

      await GetThing(dio).call(id: 'custom');

      expect(captured!.uri.path, endsWith('/things/custom'));
    });
  });

  group(
    'operation parameter enum defaults — public static const accessors',
    () {
      test('query enum default is reachable on the operation class', () {
        expect(ListSubscriptions.statusDefault, Status.active);
      });
    },
  );

  group('Subscription — runtime-fallback defaults', () {
    test('non-const leaf default reachable via static getter', () {
      expect(Subscription.startsAtDefault, DateTime.utc(2024));
    });

    test('Uri default reachable via static getter', () {
      expect(Subscription.homepageDefault, Uri.parse('https://example.com'));
    });

    test('fromJson populates Uri and DateTime defaults on missing keys', () {
      final value = Subscription.fromJson(const <String, Object?>{});
      expect(value.homepage, Uri.parse('https://example.com'));
      expect(value.startsAt, DateTime.utc(2024));
    });

    test('composite default reachable via static getter', () {
      final pricing = Subscription.pricingDefault;
      expect(pricing.amount.toString(), '9.99');
      expect(pricing.currency, 'USD');
    });

    test('computed getter is not cached — successive accesses are NOT '
        'identical', () {
      final a = Subscription.startsAtDefault;
      final b = Subscription.startsAtDefault;
      expect(identical(a, b), isFalse);
    });
  });

  group('Order — runtime-fallback oneOf default via discriminator', () {
    test('static getter resolves the discriminator to the right variant', () {
      final pet = Order.petDefault;
      expect(pet, isA<PetCat>());
      final cat = (pet as PetCat).value;
      expect(cat.kind, 'cat');
      expect(cat.livesLeft, 9);
    });

    test('Order.fromJson({}) populates the pet default', () {
      final order = Order.fromJson(const <String, Object?>{});
      expect(order.pet, isA<PetCat>());
    });
  });

  group('operation call() — enum query parameter wire encoding', () {
    test(
      'omitted enum query parameter serialises the default variant on the wire',
      () async {
        RequestOptions? captured;
        final dio = _newDio(onRequest: (o) => captured = o);

        await ListSubscriptions(dio).call();

        expect(captured!.uri.queryParameters['status'], 'active');
      },
    );

    test('explicit enum value replaces the default on the wire', () async {
      RequestOptions? captured;
      final dio = _newDio(onRequest: (o) => captured = o);

      await ListSubscriptions(dio).call(status: Status.archived);

      expect(captured!.uri.queryParameters['status'], 'archived');
    });
  });

  group('operation call() — enum header parameter wire encoding', () {
    test(
      'omitted enum header parameter serialises the default variant on the '
      'wire',
      () async {
        RequestOptions? captured;
        final dio = _newDio(onRequest: (o) => captured = o);

        await ListSubscriptions(dio).call();

        expect(captured!.headers['X-Mode'], 'auto');
      },
    );

    test(
      'explicit enum header value replaces the default on the wire',
      () async {
        RequestOptions? captured;
        final dio = _newDio(onRequest: (o) => captured = o);

        await ListSubscriptions(
          dio,
        ).call(mode: SubscriptionsParametersModel2.manual);

        expect(captured!.headers['X-Mode'], 'manual');
      },
    );
  });

  group('BadlyDefaulted — runtime fallback validates on access', () {
    // OffsetDateTime.parse rewrites the first space to T before reporting,
    // so the spec literal `"not a date"` reaches InvalidFormatException.value
    // as `"notTa date"`.
    const offendingValue = 'notTa date';

    test(
      'the static getter throws an InvalidFormatException whose structured '
      'value and format fields identify the offending default and expected '
      'format',
      () {
        expect(
          () => BadlyDefaulted.$whenDefault,
          throwsA(
            isA<InvalidFormatException>()
                .having((e) => e.value, 'value', offendingValue)
                .having((e) => e.format, 'format', contains('ISO8601')),
          ),
        );
      },
    );

    test(
      'fromJson on missing key propagates the same InvalidFormatException via '
      'the default fall-through path',
      () {
        expect(
          () => BadlyDefaulted.fromJson(const <String, Object?>{}),
          throwsA(
            isA<InvalidFormatException>()
                .having((e) => e.value, 'value', offendingValue)
                .having((e) => e.format, 'format', contains('ISO8601')),
          ),
        );
      },
    );
  });

  group('RwoDefaults — readOnly / writeOnly defaults', () {
    test('readOnly default applies on decode', () {
      final value = RwoDefaults.fromJson(const <String, Object?>{});
      expect(value.readOnlyTag, 'ro-tag');
    });

    test(
      'writeOnly field is excluded from fromJson, so the constructor default '
      'still applies because the field is omitted from the decoded map',
      () {
        final value = RwoDefaults.fromJson(const <String, Object?>{});
        expect(value.writeOnlyToken, 'wo-token');
      },
    );

    test(
      'writeOnly field is excluded from fromJson — wire value is ignored, '
      'default still applies',
      () {
        final value = RwoDefaults.fromJson(const <String, Object?>{
          'writeOnlyToken': 'on-wire',
        });
        expect(value.writeOnlyToken, 'wo-token');
      },
    );

    test('toJson omits readOnly field even when set to a non-default value',
        () {
      const value = RwoDefaults(
        readOnlyTag: 'custom-ro',
        writeOnlyToken: 'custom-wo',
        plain: 'p',
      );
      final encoded = value.toJson()! as Map<String, Object?>;
      expect(encoded.containsKey('readOnlyTag'), isFalse);
      expect(encoded['writeOnlyToken'], 'custom-wo');
      expect(encoded['plain'], 'p');
    });

    test('public static const exposes defaults for all three fields', () {
      expect(RwoDefaults.readOnlyTagDefault, 'ro-tag');
      expect(RwoDefaults.writeOnlyTokenDefault, 'wo-token');
      expect(RwoDefaults.plainDefault, 'plain');
    });
  });

  group(
    'RwoSchemaLevel — schema-level readOnly with defaulted properties',
    () {
      test(
        'decoding a JSON missing the defaulted keys yields the defaults',
        () {
          final value = RwoSchemaLevel.fromJson(const <String, Object?>{});
          expect(value.label, 'schema-ro');
          expect(value.count, 42);
        },
      );

      test('encoding throws because the whole schema is read-only', () {
        const value = RwoSchemaLevel();
        expect(
          value.toJson,
          throwsA(
            isA<EncodingException>().having(
              (e) => e.message,
              'message',
              allOf(contains('RwoSchemaLevel'), contains('read-only')),
            ),
          ),
        );
      });

      test('static defaults are emitted and reachable', () {
        expect(RwoSchemaLevel.labelDefault, 'schema-ro');
        expect(RwoSchemaLevel.countDefault, 42);
      });
    },
  );

  group('AliasChainHolder — alias chain default propagation', () {
    test(
      'AliasA -> AliasB -> AliasC default propagates three levels '
      'to the property',
      () {
        const value = AliasChainHolder();
        expect(value.viaChain, 'c-default');
      },
    );

    test(
      'sibling default on outer alias overrides the chain target default',
      () {
        const value = AliasChainHolder();
        expect(value.viaOuter, 'outer-default');
      },
    );

    test('public static const exposes both defaults', () {
      expect(AliasChainHolder.viaChainDefault, 'c-default');
      expect(AliasChainHolder.viaOuterDefault, 'outer-default');
    });

    test(
      'fromJson({}) propagates alias-chain defaults through the decoder',
      () {
        final value = AliasChainHolder.fromJson(const <String, Object?>{});
        expect(value.viaChain, 'c-default');
        expect(value.viaOuter, 'outer-default');
      },
    );

    test('fromJson supplied keys override the alias-chain defaults', () {
      final value = AliasChainHolder.fromJson(const <String, Object?>{
        'viaChain': 'override',
      });
      expect(value.viaChain, 'override');
      expect(value.viaOuter, 'outer-default');
    });
  });

  group('ApDefaults — composite defaults against additionalProperties shapes',
      () {
    test(
      'additionalProperties: true — extras in the spec default populate the '
      'untyped AP map at runtime',
      () {
        final value = ApDefaults.fromJson(const <String, Object?>{});
        final anyExtras = value.anyExtras!;
        expect(anyExtras.name, 'n');
        expect(anyExtras.additionalProperties, <String, Object?>{
          'extraA': 'value',
          'extraB': 42,
        });
      },
    );

    test(
      'additionalProperties typed int — extras in the default decode into the '
      'typed AP map at runtime',
      () {
        final value = ApDefaults.fromJson(const <String, Object?>{});
        final typedExtras = value.typedExtras!;
        expect(typedExtras.name, 'n');
        expect(typedExtras.additionalProperties, <String, int>{'count': 7});
      },
    );

    test(
      'additionalProperties: false — extras absent from the class because no '
      'AP field is generated; round-trip drops them structurally',
      () {
        final strict = ApDefaults.strictExtrasDefault;
        expect(strict.name, 'n');
        final roundTrip = strict.toJson()! as Map<String, Object?>;
        expect(roundTrip.containsKey('ignored'), isFalse);
        expect(roundTrip['name'], 'n');
      },
    );

    test(
      'public static getters expose composite defaults; getter is not cached',
      () {
        final a = ApDefaults.anyExtrasDefault;
        final b = ApDefaults.anyExtrasDefault;
        expect(identical(a, b), isFalse);
        expect(a.additionalProperties['extraB'], 42);
      },
    );
  });

  group('AllOfDefaultHolder — allOf default merges across members', () {
    test('static getter decodes the merged default through the allOf wrapper',
        () {
      final merged = AllOfDefaultHolder.mergedDefault;
      expect(merged.allOfBaseA.a, 'a-val');
      expect(merged.allOfBaseB.b, 9);
    });

    test('fromJson with missing key falls through to the merged default', () {
      final value = AllOfDefaultHolder.fromJson(const <String, Object?>{});
      expect(value.merged!.allOfBaseA.a, 'a-val');
      expect(value.merged!.allOfBaseB.b, 9);
    });
  });

  group(
    'OneOfNoDiscHolder — oneOf without discriminator',
    () {
      test(
        'default matching exactly one variant decodes to that variant',
        () {
          final single = OneOfNoDiscHolder.singleDefault;
          expect(single, isA<OneOfNoDiscOneOfShapeA>());
          expect(
            (single as OneOfNoDiscOneOfShapeA).value.onlyA,
            'from-default',
          );
        },
      );

      test(
        'default matching multiple variants decodes to the first matching '
        'variant (existing decoder contract)',
        () {
          final ambiguous = OneOfNoDiscHolder.ambiguousDefault;
          expect(ambiguous, isA<OneOfNoDiscAmbiguousOneOfShapeShared>());
        },
      );

      test('OneOfNoDiscHolder.fromJson({}) populates both defaults', () {
        final holder = OneOfNoDiscHolder.fromJson(const <String, Object?>{});
        expect(holder.single, isA<OneOfNoDiscOneOfShapeA>());
        expect(holder.ambiguous, isA<OneOfNoDiscAmbiguousOneOfShapeShared>());
      });
    },
  );

  group(
    'OneOfNoDiscRoutedHolder — oneOf routes to the second variant when the '
    'first variant rejects the default',
    () {
      test(
        'static getter resolves to the second variant when the first cannot '
        'decode the default',
        () {
          final routed = OneOfNoDiscRoutedHolder.routedDefault;
          expect(routed, isA<OneOfNoDiscRoutedOneOfRouteSecondOnly>());
          final second =
              (routed as OneOfNoDiscRoutedOneOfRouteSecondOnly).value;
          expect(second.flexible, 'matches-second');
        },
      );

      test(
        'fromJson with missing key falls through to the routed default',
        () {
          final holder = OneOfNoDiscRoutedHolder.fromJson(
            const <String, Object?>{},
          );
          expect(holder.routed, isA<OneOfNoDiscRoutedOneOfRouteSecondOnly>());
        },
      );
    },
  );

  group('AnyOfDefaultHolder — anyOf default with multiple matches', () {
    test(
      'default matching multiple variants decodes into all matching variant '
      'fields (existing decoder contract)',
      () {
        final any = AnyOfDefaultHolder.anyDefault;
        expect(any.anyOfShapeA, isNotNull);
        expect(any.anyOfShapeA!.a, 'a-val');
        expect(any.anyOfShapeB, isNotNull);
        expect(any.anyOfShapeB!.b, 5);
      },
    );

    test('AnyOfDefaultHolder.fromJson({}) populates both fields', () {
      final holder = AnyOfDefaultHolder.fromJson(const <String, Object?>{});
      expect(holder.any, isNotNull);
      expect(holder.any!.anyOfShapeA, isNotNull);
      expect(holder.any!.anyOfShapeA!.a, 'a-val');
      expect(holder.any!.anyOfShapeB, isNotNull);
      expect(holder.any!.anyOfShapeB!.b, 5);
    });
  });

  group(
    'Node — nullable self-referential default-null collapse',
    () {
      test(
        'nullable self-referential default null collapses to no default '
        '— nextOrNull accepts a null literal directly',
        () {
          const root = Node(label: 'root');
          expect(root.nextOrNull, isNull);
          expect(root.label, 'root');
        },
      );
    },
  );

  group('DirectDecimal — non-const leaf default at the field root', () {
    test(
      'BigDecimal default reachable via static getter and decodes the '
      'spec literal',
      () {
        expect(DirectDecimal.amountDefault.toString(), '12.34');
      },
    );

    test(
      'fromJson with missing key falls through to the BigDecimal default',
      () {
        final value = DirectDecimal.fromJson(const <String, Object?>{});
        expect(value.amount!.toString(), '12.34');
      },
    );
  });

  group(
    'RequiredRuntimeDefault — required + non-const default keeps constructor '
    'required and exposes a static getter',
    () {
      test('static getter exposes the decoded DateTime default', () {
        expect(RequiredRuntimeDefault.startsAtDefault, DateTime.utc(2024));
      });

      test(
        'explicit construction with the static getter produces the default',
        () {
          final value = RequiredRuntimeDefault(
            startsAt: RequiredRuntimeDefault.startsAtDefault,
          );
          expect(value.startsAt, DateTime.utc(2024));
        },
      );

      test('fromJson with missing key falls through to the default', () {
        final value =
            RequiredRuntimeDefault.fromJson(const <String, Object?>{});
        expect(value.startsAt, DateTime.utc(2024));
      });
    },
  );

  group('BinaryDefaults — binary and base64 non-const leaf defaults', () {
    test(
      'binary (format: binary) default decodes the spec literal as raw bytes',
      () {
        final blob = BinaryDefaults.blobDefault;
        expect(blob.toBytes(), <int>[65, 81, 73, 68]);
      },
    );

    test(
      'base64 (format: byte) default decodes the spec literal into the '
      'underlying bytes',
      () {
        final encoded = BinaryDefaults.encodedDefault;
        expect(encoded.toBytes(), <int>[72, 101, 108, 108, 111]);
      },
    );

    test('fromJson with missing keys falls through to both defaults', () {
      final value = BinaryDefaults.fromJson(const <String, Object?>{});
      expect(value.blob!.toBytes(), <int>[65, 81, 73, 68]);
      expect(value.encoded!.toBytes(), <int>[72, 101, 108, 108, 111]);
    });
  });
}
