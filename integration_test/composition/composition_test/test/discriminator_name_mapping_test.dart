import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';

void main() {
  test('oneOf counter retains the explicit wire discriminator', () {
    const metric = NameMappedMetricCounter(Counter(count: 1));

    final json = metric.toJson();

    expect(json, {'count': 1, 'kind': 'counter'});
    expect(NameMappedMetric.fromJson(json), metric);
  });

  test('oneOf gauge retains the explicit wire discriminator', () {
    const metric = NameMappedMetricGauge(Gauge(level: 2));

    final json = metric.toJson();

    expect(json, {'level': 2, 'kind': 'gauge'});
    expect(NameMappedMetric.fromJson(json), metric);
  });

  test('anyOf counter retains the explicit wire discriminator', () {
    const metric = NameMappedAnyMetric(counter: Counter(count: 3));

    final json = metric.toJson();
    final decoded = NameMappedAnyMetric.fromJson(json);

    expect(json, {'count': 3, 'kind': 'counter'});
    expect(decoded.counter, const Counter(count: 3));
    expect(decoded.gauge, isNull);
  });

  test('anyOf gauge retains the explicit wire discriminator', () {
    const metric = NameMappedAnyMetric(gauge: Gauge(level: 4));

    final json = metric.toJson();
    final decoded = NameMappedAnyMetric.fromJson(json);

    expect(json, {'level': 4, 'kind': 'gauge'});
    expect(decoded.gauge, const Gauge(level: 4));
    expect(decoded.counter, isNull);
  });
}
