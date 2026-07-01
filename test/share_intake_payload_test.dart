import 'package:cruiseplanner/models/share/share_intake_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShareIntakeItem.fromJson', () {
    test('keeps pure URL shares as URL items', () {
      final item = ShareIntakeItem.fromJson(<String, dynamic>{
        'kind': 'url',
        'value': 'https://gyg.me/MdDQa9vE',
      });

      expect(item, isNotNull);
      expect(item!.kind, ShareIntakeItemKind.url);
      expect(item.value, 'https://gyg.me/MdDQa9vE');
    });

    test('extracts embedded URL from shared text', () {
      final item = ShareIntakeItem.fromJson(<String, dynamic>{
        'kind': 'text',
        'value':
            'Sehen Sie sich diese Aktivität auf GetYourGuide an! https://gyg.me/MdDQa9vE',
      });

      expect(item, isNotNull);
      expect(item!.kind, ShareIntakeItemKind.url);
      expect(item.value, 'https://gyg.me/MdDQa9vE');
    });

    test('trims trailing punctuation from extracted URL', () {
      final item = ShareIntakeItem.fromJson(<String, dynamic>{
        'kind': 'text',
        'value': 'Read this: https://example.com/ticket).',
      });

      expect(item, isNotNull);
      expect(item!.kind, ShareIntakeItemKind.url);
      expect(item.value, 'https://example.com/ticket');
    });

    test('keeps plain text without URL as text item', () {
      final item = ShareIntakeItem.fromJson(<String, dynamic>{
        'kind': 'text',
        'value': 'Nur ein normaler Text ohne Link',
      });

      expect(item, isNotNull);
      expect(item!.kind, ShareIntakeItemKind.text);
      expect(item.value, 'Nur ein normaler Text ohne Link');
    });
  });
}
