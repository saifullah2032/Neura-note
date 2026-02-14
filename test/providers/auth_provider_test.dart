import 'package:flutter_test/flutter_test.dart';
import 'package:neuranotteai/providers/auth_provider.dart';

void main() {
  group('AuthState', () {
    test('has all expected values', () {
      expect(AuthState.values.length, 5);
      expect(AuthState.values, contains(AuthState.initial));
      expect(AuthState.values, contains(AuthState.authenticating));
      expect(AuthState.values, contains(AuthState.authenticated));
      expect(AuthState.values, contains(AuthState.unauthenticated));
      expect(AuthState.values, contains(AuthState.error));
    });

    test('initial is the first state', () {
      expect(AuthState.initial.index, 0);
    });

    test('has correct indices for state flow', () {
      expect(AuthState.initial.index, 0);
      expect(AuthState.authenticating.index, 1);
      expect(AuthState.authenticated.index, 2);
      expect(AuthState.unauthenticated.index, 3);
      expect(AuthState.error.index, 4);
    });

    test('state names are correct', () {
      expect(AuthState.initial.name, 'initial');
      expect(AuthState.authenticating.name, 'authenticating');
      expect(AuthState.authenticated.name, 'authenticated');
      expect(AuthState.unauthenticated.name, 'unauthenticated');
      expect(AuthState.error.name, 'error');
    });
  });

  group('AuthState Usage Patterns', () {
    test('can use switch expression for state handling', () {
      String getMessage(AuthState state) {
        return switch (state) {
          AuthState.initial => 'Initializing...',
          AuthState.authenticating => 'Signing in...',
          AuthState.authenticated => 'Welcome!',
          AuthState.unauthenticated => 'Please sign in',
          AuthState.error => 'Something went wrong',
        };
      }

      expect(getMessage(AuthState.initial), 'Initializing...');
      expect(getMessage(AuthState.authenticating), 'Signing in...');
      expect(getMessage(AuthState.authenticated), 'Welcome!');
      expect(getMessage(AuthState.unauthenticated), 'Please sign in');
      expect(getMessage(AuthState.error), 'Something went wrong');
    });

    test('can check loading states', () {
      bool isLoadingState(AuthState state) {
        return state == AuthState.initial || state == AuthState.authenticating;
      }

      expect(isLoadingState(AuthState.initial), true);
      expect(isLoadingState(AuthState.authenticating), true);
      expect(isLoadingState(AuthState.authenticated), false);
      expect(isLoadingState(AuthState.unauthenticated), false);
      expect(isLoadingState(AuthState.error), false);
    });

    test('can check success states', () {
      bool isSuccessState(AuthState state) {
        return state == AuthState.authenticated;
      }

      expect(isSuccessState(AuthState.initial), false);
      expect(isSuccessState(AuthState.authenticating), false);
      expect(isSuccessState(AuthState.authenticated), true);
      expect(isSuccessState(AuthState.unauthenticated), false);
      expect(isSuccessState(AuthState.error), false);
    });

    test('can check error states', () {
      bool isErrorState(AuthState state) {
        return state == AuthState.error || state == AuthState.unauthenticated;
      }

      expect(isErrorState(AuthState.initial), false);
      expect(isErrorState(AuthState.authenticating), false);
      expect(isErrorState(AuthState.authenticated), false);
      expect(isErrorState(AuthState.unauthenticated), true);
      expect(isErrorState(AuthState.error), true);
    });
  });
}
