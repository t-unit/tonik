import 'package:form_urlencoded_api/form_urlencoded_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('decodes binary scalar and list form values exactly once', () {
    final form = BinaryForm.fromForm(
      'data=H+i%C3%A9%2B&files=%2B,%25,%2541,%FF,%2C'
      '&aliases=%252B&variants=%2B,%25,%FF',
      explode: true,
    );

    expect(form.data, const TonikFileBytes([72, 32, 105, 195, 169, 43]));
    expect(form.files, const [
      TonikFileBytes([43]),
      TonikFileBytes([37]),
      TonikFileBytes([37, 52, 49]),
      TonikFileBytes([255]),
      TonikFileBytes([44]),
    ]);
    expect(form.aliases, const [
      TonikFileBytes([37, 50, 66]),
    ]);
    expect(form.variants, const [
      BinaryFormValueBinary(TonikFileBytes([43])),
      BinaryFormValueBinary(TonikFileBytes([37])),
      BinaryFormValueBinary(TonikFileBytes([255])),
    ]);
    expect(form.optionalFiles, isNull);
  });

  test('decodes optional binary lists and preserves encoded commas', () {
    final form = BinaryForm.fromForm(
      'data=&files=&aliases=&variants=&optionalFiles=%2C,%FF',
      explode: true,
    );

    expect(form.data, const TonikFileBytes([]));
    expect(form.files, isEmpty);
    expect(form.aliases, isEmpty);
    expect(form.variants, isEmpty);
    expect(form.optionalFiles, const [
      TonikFileBytes([44]),
      TonikFileBytes([255]),
    ]);
  });

  test('keeps empty optional binary lists nullable', () {
    final form = BinaryForm.fromForm(
      'data=&files=&aliases=&variants=&optionalFiles=',
      explode: true,
    );

    expect(form.optionalFiles, isNull);
  });
}
