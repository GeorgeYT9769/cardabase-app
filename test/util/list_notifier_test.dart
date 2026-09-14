import 'package:cardabase/util/list_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListNotifier', () {
    /// Counts how often the notifier told its listeners something changed.
    ({ListNotifier<String> list, int Function() notifications}) listWith(
      List<String> elements,
    ) {
      final list = ListNotifier(elements);
      var notifications = 0;
      list.addListener(() => notifications++);
      addTearDown(list.dispose);
      return (list: list, notifications: () => notifications);
    }

    test('takes a copy of the list it is given', () {
      final source = ['a'];
      final list = ListNotifier(source);

      source.add('b');

      expect(
        list,
        ['a'],
        reason: 'changing the source should not change the notifier',
      );
    });

    test('can grow even when it was built from a fixed-length list', () {
      final list = ListNotifier(List<String>.unmodifiable(['a']));

      expect(() => list.add('b'), returnsNormally);
    });

    group('value', () {
      test('hands out a copy which cannot be changed underneath it', () {
        final list = ListNotifier(['a']);

        expect(list.value, ['a']);
        expect(() => list.value.add('b'), throwsUnsupportedError);
        expect(list, ['a']);
      });

      test('replacing it notifies, and takes a copy as well', () {
        final (:list, :notifications) = listWith(['a']);
        final replacement = ['b', 'c'];

        list.value = replacement;
        replacement.add('d');

        expect(list, ['b', 'c']);
        expect(notifications(), 1);
      });
    });

    group('moving elements around', () {
      test('swap exchanges two elements', () {
        final (:list, :notifications) = listWith(['a', 'b', 'c']);

        list.swap(0, 2);

        expect(list, ['c', 'b', 'a']);
        expect(notifications(), 1);
      });

      test('move takes an element out and puts it back somewhere else', () {
        final (:list, :notifications) = listWith(['a', 'b', 'c']);

        list.move(0, 2);

        expect(list, ['b', 'c', 'a']);
        expect(notifications(), 1);
      });

      test('moveUp swaps an element with the one before it', () {
        final (:list, :notifications) = listWith(['a', 'b', 'c']);

        list.moveUp('b');

        expect(list, ['b', 'a', 'c']);
        expect(notifications(), 1);
      });

      test('moveUp leaves the first element where it is', () {
        final (:list, :notifications) = listWith(['a', 'b']);

        list.moveUp('a');

        expect(list, ['a', 'b']);
        expect(notifications(), 0, reason: 'nothing changed');
      });

      test('moveDown swaps an element with the one after it', () {
        final (:list, :notifications) = listWith(['a', 'b', 'c']);

        list.moveDown('b');

        expect(list, ['a', 'c', 'b']);
        expect(notifications(), 1);
      });

      test('moveDown leaves the last element where it is', () {
        final (:list, :notifications) = listWith(['a', 'b']);

        list.moveDown('b');

        expect(list, ['a', 'b']);
        expect(notifications(), 0, reason: 'nothing changed');
      });

      test('moving an element which is not in the list adds it at the end', () {
        final (:list, :notifications) = listWith(['a']);

        list
          ..moveUp('b')
          ..moveDown('c');

        expect(list, ['a', 'b', 'c']);
        expect(notifications(), 2);
      });
    });

    group('notifies when the list changes', () {
      test('add and addAll', () {
        final (:list, :notifications) = listWith([]);

        list
          ..add('a')
          ..addAll(['b', 'c']);

        expect(list, ['a', 'b', 'c']);
        expect(notifications(), 2);
      });

      test('insert and insertAll', () {
        final (:list, :notifications) = listWith(['c']);

        list
          ..insert(0, 'a')
          ..insertAll(1, ['b']);

        expect(list, ['a', 'b', 'c']);
        expect(notifications(), 2);
      });

      test('assigning an element', () {
        final (:list, :notifications) = listWith(['a']);

        list[0] = 'b';

        expect(list, ['b']);
        expect(notifications(), 1);
      });

      test('first, last and length', () {
        final (:list, :notifications) = listWith(['a', 'b', 'c']);

        list
          ..first = 'x'
          ..last = 'y'
          ..length = 2;

        expect(list, ['x', 'b']);
        expect(notifications(), 3);
      });

      test('remove', () {
        final (:list, :notifications) = listWith(['a', 'b']);

        expect(list.remove('a'), isTrue);
        expect(list, ['b']);
        expect(notifications(), 1);
      });

      test('remove notifies even when there was nothing to remove', () {
        final (:list, :notifications) = listWith(['a']);

        expect(list.remove('b'), isFalse);
        expect(
          notifications(),
          1,
          reason: 'today it notifies unconditionally; the list is unchanged',
        );
      });

      test('removeAt and removeLast hand back what they removed', () {
        final (:list, :notifications) = listWith(['a', 'b', 'c']);

        expect(list.removeAt(0), 'a');
        expect(list.removeLast(), 'c');
        expect(list, ['b']);
        expect(notifications(), 2);
      });

      test('removeRange, removeWhere and retainWhere', () {
        final (:list, :notifications) = listWith(['a', 'b', 'c', 'd']);

        list
          ..removeRange(0, 1)
          ..removeWhere((element) => element == 'b')
          ..retainWhere((element) => element == 'c');

        expect(list, ['c']);
        expect(notifications(), 3);
      });

      test('clear', () {
        final (:list, :notifications) = listWith(['a']);

        list.clear();

        expect(list, isEmpty);
        expect(notifications(), 1);
      });

      test('sort and shuffle', () {
        final (:list, :notifications) = listWith(['b', 'a']);

        list
          ..sort()
          ..shuffle();

        expect(list, containsAll(['a', 'b']));
        expect(notifications(), 2);
      });

      test('fillRange, setAll, setRange and replaceRange', () {
        final (:list, :notifications) = listWith(['a', 'b', 'c', 'd']);

        list
          ..fillRange(0, 1, 'x')
          ..setAll(1, ['y'])
          ..setRange(2, 3, ['z'])
          ..replaceRange(3, 4, ['w']);

        expect(list, ['x', 'y', 'z', 'w']);
        expect(notifications(), 4);
      });
    });

    test('stays quiet when the list is only read', () {
      final (:list, :notifications) = listWith(['a', 'b']);

      list
        ..where((element) => element == 'a').toList()
        ..map((element) => element.toUpperCase()).toList()
        ..contains('a')
        ..indexOf('b')
        ..sublist(0, 1)
        ..toList()
        ..toSet()
        ..join(',');

      expect(notifications(), 0);
    });
  });
}
