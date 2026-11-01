import 'package:flutter_test/flutter_test.dart';
import 'package:forums_client/forums_api.dart';
import 'package:forums_client/screens/ui.dart';

void main() {
  group('describeError', () {
    test('network failure names the host', () {
      expect(
        describeError(ApiException(0, 'Could not reach forums.simpleapi.dev. Check your connection and try again.')),
        'Could not reach forums.simpleapi.dev. Check your connection and try again.',
      );
    });

    test('401 for the key', () {
      expect(
        describeError(ApiException(401, 'Unauthorized. Please provide a valid apikey. Get a free key at https://keys.simpleapi.dev/?product=forums')),
        'The API key was not accepted.',
      );
    });

    test('401 for an ended session', () {
      expect(
        describeError(ApiException(401, 'Invalid or expired auth token. Log in again.', sessionEnded: true)),
        'Your session has ended. Please log in again.',
      );
    });

    test('401 on login, 403, 409 and 422 show the API message', () {
      expect(describeError(ApiException(401, 'Invalid email or password.')), 'Invalid email or password.');
      expect(describeError(ApiException(403, 'Only the forum author can do that.')), 'Only the forum author can do that.');
      expect(describeError(ApiException(403, 'The demo account cannot be changed.')), 'The demo account cannot be changed.');
      expect(describeError(ApiException(409, 'Email already registered.')), 'Email already registered.');
      expect(describeError(ApiException(422, 'The title field is required.')), 'The title field is required.');
    });

    test('404 and 429 have their own wording', () {
      expect(describeError(ApiException(404, 'Topic x not found.')), 'Not found. It may already have been deleted.');
      expect(describeError(ApiException(429, 'Rate limit exceeded')), 'Too many requests. Wait a few seconds and try again.');
    });

    test('503 is the shared wording', () {
      expect(describeError(ApiException(503, 'Key service unavailable. Please try again shortly.')), 'The service is busy. Please try again shortly.');
    });

    test('anything else does not leak an exception', () {
      expect(describeError(StateError('boom')), 'Something went wrong. Please try again.');
    });
  });
}
