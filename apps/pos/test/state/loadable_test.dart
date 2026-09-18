/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pos/state/loadable.dart';

// A fetch the test finishes by hand, so it can look at the state while a request is out.
class Fetch<T> {
  final calls = <Completer<T>>[];

  Future<T> call() {
    final c = Completer<T>();
    calls.add(c);
    return c.future;
  }

  void succeed(T value, {int call = 0}) => calls[call].complete(value);
  void fail(Object error, {int call = 0}) => calls[call].completeError(error);
}

Loadable<String> over(Fetch<String> fetch) => Loadable(fetch.call);

T readyData<T>(LoadState<T> s) => (s as Ready<T>).data;

void main() {
  group('a loadable', () {
    test('is loading until it is asked to load', () {
      final loadable = over(Fetch());

      expect(loadable.state, isA<Loading<String>>());
    });

    test(
      'is ready with the data once the fetch answers, and says so',
      () async {
        final fetch = Fetch<String>();
        final loadable = over(fetch);
        var notified = 0;
        loadable.addListener(() => notified++);

        final loading = loadable.load();
        fetch.succeed('kopi');
        await loading;

        expect(readyData(loadable.state), 'kopi');
        expect((loadable.state as Ready<String>).refreshing, isFalse);
        expect(notified, 1);
      },
    );

    test('is failed with the ApiError the server gave', () async {
      final fetch = Fetch<String>();
      final loadable = over(fetch);
      final error = ApiError('Forbidden', status: 403);

      final loading = loadable.load();
      fetch.fail(error);
      await loading;

      expect((loadable.state as Failed<String>).error, same(error));
    });

    test('is failed when the network is down', () async {
      final fetch = Fetch<String>();
      final loadable = over(fetch);
      final error = TransportException('down');

      final loading = loadable.load();
      fetch.fail(error);
      await loading;

      expect((loadable.state as Failed<String>).error, same(error));
    });

    test(
      'is failed, and still lets a bug through, for anything else',
      () async {
        // A bug must stay visible; but the cashier must not be left on a spinner for it.
        final fetch = Fetch<String>();
        final loadable = over(fetch);

        final loading = loadable.load();
        fetch.fail(StateError('bug'));

        await expectLater(loading, throwsStateError);
        expect(loadable.state, isA<Failed<String>>());
      },
    );
  });

  group('loading again', () {
    Future<Loadable<String>> readyWith(Fetch<String> fetch, String data) async {
      final loadable = over(fetch);
      final first = loadable.load();
      fetch.succeed(data);
      await first;
      return loadable;
    }

    test(
      'keeps the old data on screen while the new answer is on its way',
      () async {
        final fetch = Fetch<String>();
        final loadable = await readyWith(fetch, 'kopi');

        final again = loadable.load();

        final state = loadable.state as Ready<String>;
        expect(state.data, 'kopi');
        expect(state.refreshing, isTrue);
        fetch.succeed('teh', call: 1);
        await again;
      },
    );

    test('shows the new data, no longer refreshing, when it arrives', () async {
      final fetch = Fetch<String>();
      final loadable = await readyWith(fetch, 'kopi');

      final again = loadable.load();
      fetch.succeed('teh', call: 1);
      await again;

      final state = loadable.state as Ready<String>;
      expect(state.data, 'teh');
      expect(state.refreshing, isFalse);
    });

    test('drops the old data when the new answer is a failure', () async {
      // The old data was for the old request. Left up, it would read as the answer to this one.
      final fetch = Fetch<String>();
      final loadable = await readyWith(fetch, 'kopi');

      final again = loadable.load();
      fetch.fail(ApiError('down', status: 500), call: 1);
      await again;

      expect(loadable.state, isA<Failed<String>>());
    });

    test('goes back to loading after a failure, not to the failure', () async {
      final fetch = Fetch<String>();
      final loadable = over(fetch);
      final first = loadable.load();
      fetch.fail(TransportException('down'));
      await first;

      final again = loadable.load();

      expect(loadable.state, isA<Loading<String>>());
      fetch.succeed('kopi', call: 1);
      await again;
      expect(readyData(loadable.state), 'kopi');
    });
  });

  group('an answer that is no longer wanted', () {
    test('does not replace a newer one that arrived first', () async {
      // Two taps on two categories: the second answer comes back first.
      final fetch = Fetch<String>();
      final loadable = over(fetch);

      final first = loadable.load();
      final second = loadable.load();
      fetch.succeed('teh', call: 1);
      await second;
      fetch.succeed('kopi', call: 0);
      await first;

      expect(readyData(loadable.state), 'teh');
    });

    test('does not turn a newer answer into a failure either', () async {
      final fetch = Fetch<String>();
      final loadable = over(fetch);

      final first = loadable.load();
      final second = loadable.load();
      fetch.succeed('teh', call: 1);
      await second;
      fetch.fail(ApiError('late', status: 500), call: 0);
      await first;

      expect(readyData(loadable.state), 'teh');
    });

    test('is still waited for by the newest, not by the one it replaced', () async {
      final fetch = Fetch<String>();
      final loadable = over(fetch);
      var notified = 0;
      loadable.addListener(() => notified++);

      final first = loadable.load();
      final second = loadable.load();
      fetch.succeed('kopi', call: 0);
      await first;

      // The first answer is stale: the screen has not been told there is data.
      expect(loadable.state, isA<Loading<String>>());
      expect(notified, 0);
      fetch.succeed('teh', call: 1);
      await second;
    });
  });

  group('a loadable that is disposed', () {
    test('ignores the answer that comes after, and does not throw', () async {
      final fetch = Fetch<String>();
      final loadable = over(fetch);

      final loading = loadable.load();
      loadable.dispose();
      fetch.succeed('kopi');

      await expectLater(loading, completes);
    });

    test('ignores a failure that comes after, and does not throw', () async {
      final fetch = Fetch<String>();
      final loadable = over(fetch);

      final loading = loadable.load();
      loadable.dispose();
      fetch.fail(TransportException('down'));

      await expectLater(loading, completes);
    });
  });

  // What a failed read says on screen. Two screens read the server's sentence (the Menu, and
  // the shift gate), and the rule is about the error rather than either screen, so it lives in
  // one place — the two copies had already drifted: the gate showed its own "check the
  // connection" wording for a 402 SUBSCRIPTION_EXPIRED, which retrying cannot fix.
  group('the sentence for a failed read', () {
    test('is the server\'s own when it refused', () {
      expect(
        failedReadText(
          ApiError(
            'Masa berlaku langganan untuk perusahaan ini telah berakhir',
            status: 402,
          ),
          'Periksa koneksi lalu coba lagi.',
        ),
        'Masa berlaku langganan untuk perusahaan ini telah berakhir',
      );
    });

    test('falls back to the caller\'s wording when nobody answered', () {
      expect(
        failedReadText(
          TransportException('down'),
          'Periksa koneksi lalu coba lagi.',
        ),
        'Periksa koneksi lalu coba lagi.',
      );
    });

    // An `ApiError` with no sentence has nothing to quote, and an empty title would render as a
    // blank header with a retry button under it.
    test('falls back when the server refused without saying why', () {
      expect(
        failedReadText(ApiError(''), 'Periksa koneksi'),
        'Periksa koneksi',
      );
    });

    // The failed state is only built for these two; anything else is a bug that `Loadable`
    // rethrows. Quoting a random object's `toString` would put a stack trace on screen.
    test('falls back for anything that is not a server or network failure', () {
      expect(
        failedReadText(StateError('bug'), 'Periksa koneksi'),
        'Periksa koneksi',
      );
    });
  });
}
