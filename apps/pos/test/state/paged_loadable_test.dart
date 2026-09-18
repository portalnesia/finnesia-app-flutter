/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/page.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/state/paged_loadable.dart';

// A fetch the test finishes by hand. `cursors` is what each request asked for: null for the
// first page, then whatever the page before it said came next.
class PagedFetch {
  final cursors = <String?>[];
  final _pending = <Completer<CursorPage<String>>>[];

  Future<CursorPage<String>> call(String? cursor) {
    cursors.add(cursor);
    final c = Completer<CursorPage<String>>();
    _pending.add(c);
    return c.future;
  }

  int get calls => cursors.length;

  void page(List<String> items, {String? next, int call = 0}) =>
      _pending[call].complete(CursorPage(items: items, nextCursor: next));

  void fail(Object error, {int call = 0}) =>
      _pending[call].completeError(error);
}

PagedLoadable<String> over(PagedFetch fetch) => PagedLoadable(fetch.call);

PagedItems<String> itemsOf(PagedLoadable<String> l) =>
    (l.state as Ready<PagedItems<String>>).data;

Future<PagedLoadable<String>> firstPage(
  PagedFetch fetch, {
  List<String> items = const ['a', 'b'],
  String? next = 'c1',
}) async {
  final l = over(fetch);
  final loading = l.load();
  fetch.page(items, next: next);
  await loading;
  return l;
}

void main() {
  group('the first page', () {
    test('is loading until it is asked to load', () {
      expect(over(PagedFetch()).state, isA<Loading<PagedItems<String>>>());
    });

    test('asks for no cursor, and shows what came back', () async {
      final fetch = PagedFetch();
      final l = await firstPage(fetch);

      expect(fetch.cursors, [null]);
      expect(itemsOf(l).items, ['a', 'b']);
    });

    test('says there is more when the page names a next cursor', () async {
      final l = await firstPage(PagedFetch(), next: 'c1');

      expect(itemsOf(l).hasMore, isTrue);
    });

    test('says there is no more on the last page', () async {
      final l = await firstPage(PagedFetch(), next: null);

      expect(itemsOf(l).hasMore, isFalse);
    });

    test('is failed when the server or the network says so', () async {
      for (final error in <Object>[
        ApiError('Forbidden', status: 403),
        TransportException('down'),
      ]) {
        final fetch = PagedFetch();
        final l = over(fetch);

        final loading = l.load();
        fetch.fail(error);
        await loading;

        expect((l.state as Failed<PagedItems<String>>).error, same(error));
      }
    });
  });

  group('the next page', () {
    test(
      'is asked for with the cursor the last page named, and added after it',
      () async {
        final fetch = PagedFetch();
        final l = await firstPage(fetch, next: 'c1');

        final more = l.loadMore();
        fetch.page(['c', 'd'], next: null, call: 1);
        await more;

        expect(fetch.cursors, [null, 'c1']);
        expect(itemsOf(l).items, ['a', 'b', 'c', 'd']);
        expect(itemsOf(l).hasMore, isFalse);
      },
    );

    test('is one request however many times the list asks while it is out', () async {
      // A scroll view fires its end-of-list event on every frame near the end.
      final fetch = PagedFetch();
      final l = await firstPage(fetch);

      final a = l.loadMore();
      final b = l.loadMore();
      final c = l.loadMore();
      fetch.page(['c'], next: null, call: 1);
      await Future.wait([a, b, c]);

      expect(fetch.calls, 2);
      expect(itemsOf(l).items, ['a', 'b', 'c']);
    });

    test('says it is loading more while the request is out', () async {
      final fetch = PagedFetch();
      final l = await firstPage(fetch);

      final more = l.loadMore();

      expect(itemsOf(l).loadingMore, isTrue);
      expect(itemsOf(l).items, ['a', 'b']);
      fetch.page(['c'], next: null, call: 1);
      await more;
      expect(itemsOf(l).loadingMore, isFalse);
    });

    test('is not asked for after the last page', () async {
      final fetch = PagedFetch();
      final l = await firstPage(fetch, next: null);

      await l.loadMore();

      expect(fetch.calls, 1);
    });

    test('is not asked for before the first page has arrived', () async {
      final fetch = PagedFetch();
      final l = over(fetch);

      final loading = l.load();
      await l.loadMore();

      expect(fetch.calls, 1);
      fetch.page(['a'], next: 'c1');
      await loading;
    });

    test('is not asked for after the first page failed', () async {
      final fetch = PagedFetch();
      final l = over(fetch);
      final loading = l.load();
      fetch.fail(TransportException('down'));
      await loading;

      await l.loadMore();

      expect(fetch.calls, 1);
    });
  });

  group('a next page that fails', () {
    test(
      'leaves the rows on screen, and says why the list stopped growing',
      () async {
        final fetch = PagedFetch();
        final l = await firstPage(fetch);
        final error = TransportException('down');

        final more = l.loadMore();
        fetch.fail(error, call: 1);
        await more;

        final shown = itemsOf(l);
        expect(shown.items, ['a', 'b']);
        expect(shown.hasMore, isTrue);
        expect(shown.loadingMore, isFalse);
        expect(shown.moreError, same(error));
      },
    );

    test('is tried again from the same cursor, and clears the error', () async {
      final fetch = PagedFetch();
      final l = await firstPage(fetch, next: 'c1');
      final failing = l.loadMore();
      fetch.fail(TransportException('down'), call: 1);
      await failing;

      final again = l.loadMore();
      fetch.page(['c'], next: null, call: 2);
      await again;

      expect(fetch.cursors, [null, 'c1', 'c1']);
      expect(itemsOf(l).items, ['a', 'b', 'c']);
      expect(itemsOf(l).moreError, isNull);
    });

    test('still lets a bug through, and leaves the list usable', () async {
      final fetch = PagedFetch();
      final l = await firstPage(fetch);

      final more = l.loadMore();
      fetch.fail(StateError('bug'), call: 1);

      await expectLater(more, throwsStateError);
      expect(itemsOf(l).loadingMore, isFalse);
    });
  });

  group('loading the first page again', () {
    test(
      'keeps the rows on screen meanwhile, and asks from the start',
      () async {
        final fetch = PagedFetch();
        final l = await firstPage(fetch, next: 'c1');

        final again = l.load();

        final state = l.state as Ready<PagedItems<String>>;
        expect(state.refreshing, isTrue);
        expect(state.data.items, ['a', 'b']);
        expect(fetch.cursors.last, isNull);
        fetch.page(['x'], next: null, call: 1);
        await again;
      },
    );

    test('replaces the rows, and does not add to them', () async {
      final fetch = PagedFetch();
      final l = await firstPage(fetch);

      final again = l.load();
      fetch.page(['x', 'y'], next: null, call: 1);
      await again;

      expect(itemsOf(l).items, ['x', 'y']);
      expect((l.state as Ready<PagedItems<String>>).refreshing, isFalse);
    });

    test('drops the rows when the new answer is a failure', () async {
      final fetch = PagedFetch();
      final l = await firstPage(fetch);

      final again = l.load();
      fetch.fail(ApiError('down', status: 500), call: 1);
      await again;

      expect(l.state, isA<Failed<PagedItems<String>>>());
    });

    test('is not undone by a next page that was still on its way', () async {
      // The category changed while the list was scrolling: the page of the old category must
      // not land in the new one.
      final fetch = PagedFetch();
      final l = await firstPage(fetch, next: 'c1');
      final more = l.loadMore();

      final again = l.load();
      fetch.page(['old'], next: null, call: 1);
      await more;
      fetch.page(['x'], next: 'cx', call: 2);
      await again;

      expect(itemsOf(l).items, ['x']);
    });

    test('is not interrupted by a request for a next page', () async {
      // Rows of the old list are on screen while the new first page loads. A next page asked
      // for now would belong to the old list and make the reload stale.
      final fetch = PagedFetch();
      final l = await firstPage(fetch, next: 'c1');

      final again = l.load();
      await l.loadMore();
      fetch.page(['x'], next: null, call: 1);
      await again;

      expect(fetch.calls, 2);
      expect(itemsOf(l).items, ['x']);
    });

    test('is not replaced by a first page that was overtaken', () async {
      final fetch = PagedFetch();
      final l = over(fetch);

      final first = l.load();
      final second = l.load();
      fetch.page(['new'], next: null, call: 1);
      await second;
      fetch.page(['stale'], next: null, call: 0);
      await first;

      expect(itemsOf(l).items, ['new']);
    });
  });

  group('a cursor that does not move', () {
    test(
      'ends the list, rather than asking for the same page forever',
      () async {
        final fetch = PagedFetch();
        final l = await firstPage(fetch, next: 'c1');

        final more = l.loadMore();
        fetch.page(['c'], next: 'c1', call: 1);
        await more;

        expect(itemsOf(l).hasMore, isFalse);
      },
    );
  });

  group('a paged loadable that is disposed', () {
    test('ignores the page that comes after, and does not throw', () async {
      final fetch = PagedFetch();
      final l = over(fetch);

      final loading = l.load();
      l.dispose();
      fetch.page(['a'], next: null);

      await expectLater(loading, completes);
    });

    test('ignores a next page that comes after, and does not throw', () async {
      final fetch = PagedFetch();
      final l = await firstPage(fetch);

      final more = l.loadMore();
      l.dispose();
      fetch.page(['c'], next: null, call: 1);

      await expectLater(more, completes);
    });
  });
}
