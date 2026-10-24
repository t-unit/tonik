import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';

void main() {
  test('integer-only counter injects its discriminator and roundtrips', () {
    const metric = MetricCounter(Counter(count: 1));

    final json = metric.toJson();

    expect(json, {'count': 1, 'type': 'counter'});
    expect(Metric.fromJson(json), metric);
  });

  test('integer-only gauge injects its discriminator and roundtrips', () {
    const metric = MetricGauge(Gauge(level: 2));

    final json = metric.toJson();

    expect(json, {'level': 2, 'type': 'gauge'});
    expect(Metric.fromJson(json), metric);
  });

  test('boolean-only variant injects its discriminator', () {
    const metric = MetricFlag(Flag(enabled: true));

    expect(metric.toJson(), {'enabled': true, 'type': 'flag'});
  });

  test('existing discriminator value is preserved', () {
    const metric = MetricTaggedMetric(TaggedMetric(count: 3, $type: 'custom'));

    expect(metric.toJson(), {'count': 3, 'type': 'custom'});
  });

  test('existing null discriminator is preserved', () {
    const metric = MetricTaggedMetric(TaggedMetric(count: 4, $type: null));

    expect(metric.toJson(), {'count': 4, 'type': null});
  });
}
