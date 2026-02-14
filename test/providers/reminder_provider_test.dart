import 'package:flutter_test/flutter_test.dart';
import 'package:neuranotteai/providers/reminder_provider.dart';

void main() {
  group('ReminderState', () {
    test('has all expected values', () {
      expect(ReminderState.values.length, 6);
      expect(ReminderState.values, contains(ReminderState.initial));
      expect(ReminderState.values, contains(ReminderState.loading));
      expect(ReminderState.values, contains(ReminderState.loaded));
      expect(ReminderState.values, contains(ReminderState.error));
      expect(ReminderState.values, contains(ReminderState.creating));
      expect(ReminderState.values, contains(ReminderState.syncing));
    });

    test('has correct indices for state flow', () {
      expect(ReminderState.initial.index, 0);
      expect(ReminderState.loading.index, 1);
      expect(ReminderState.loaded.index, 2);
      expect(ReminderState.error.index, 3);
      expect(ReminderState.creating.index, 4);
      expect(ReminderState.syncing.index, 5);
    });

    test('state names are correct', () {
      expect(ReminderState.initial.name, 'initial');
      expect(ReminderState.loading.name, 'loading');
      expect(ReminderState.loaded.name, 'loaded');
      expect(ReminderState.error.name, 'error');
      expect(ReminderState.creating.name, 'creating');
      expect(ReminderState.syncing.name, 'syncing');
    });
  });

  group('ReminderState Usage Patterns', () {
    test('can use switch expression for state handling', () {
      String getMessage(ReminderState state) {
        return switch (state) {
          ReminderState.initial => 'Not loaded',
          ReminderState.loading => 'Loading reminders...',
          ReminderState.loaded => 'Reminders loaded',
          ReminderState.error => 'Error loading reminders',
          ReminderState.creating => 'Creating reminder...',
          ReminderState.syncing => 'Syncing with calendar...',
        };
      }

      expect(getMessage(ReminderState.initial), 'Not loaded');
      expect(getMessage(ReminderState.loading), 'Loading reminders...');
      expect(getMessage(ReminderState.loaded), 'Reminders loaded');
      expect(getMessage(ReminderState.error), 'Error loading reminders');
      expect(getMessage(ReminderState.creating), 'Creating reminder...');
      expect(getMessage(ReminderState.syncing), 'Syncing with calendar...');
    });

    test('can check loading states', () {
      bool isLoadingState(ReminderState state) {
        return state == ReminderState.loading ||
            state == ReminderState.creating ||
            state == ReminderState.syncing;
      }

      expect(isLoadingState(ReminderState.initial), false);
      expect(isLoadingState(ReminderState.loading), true);
      expect(isLoadingState(ReminderState.loaded), false);
      expect(isLoadingState(ReminderState.error), false);
      expect(isLoadingState(ReminderState.creating), true);
      expect(isLoadingState(ReminderState.syncing), true);
    });

    test('can check success states', () {
      bool isSuccessState(ReminderState state) {
        return state == ReminderState.loaded;
      }

      expect(isSuccessState(ReminderState.initial), false);
      expect(isSuccessState(ReminderState.loading), false);
      expect(isSuccessState(ReminderState.loaded), true);
      expect(isSuccessState(ReminderState.error), false);
      expect(isSuccessState(ReminderState.creating), false);
      expect(isSuccessState(ReminderState.syncing), false);
    });

    test('can check error states', () {
      bool isErrorState(ReminderState state) {
        return state == ReminderState.error;
      }

      expect(isErrorState(ReminderState.initial), false);
      expect(isErrorState(ReminderState.loading), false);
      expect(isErrorState(ReminderState.loaded), false);
      expect(isErrorState(ReminderState.error), true);
      expect(isErrorState(ReminderState.creating), false);
      expect(isErrorState(ReminderState.syncing), false);
    });

    test('can check if can interact with reminders', () {
      bool canInteract(ReminderState state) {
        return state == ReminderState.loaded || state == ReminderState.error;
      }

      expect(canInteract(ReminderState.initial), false);
      expect(canInteract(ReminderState.loading), false);
      expect(canInteract(ReminderState.loaded), true);
      expect(canInteract(ReminderState.error), true);
      expect(canInteract(ReminderState.creating), false);
      expect(canInteract(ReminderState.syncing), false);
    });

    test('can check active operation states', () {
      bool hasActiveOperation(ReminderState state) {
        return state == ReminderState.creating || state == ReminderState.syncing;
      }

      expect(hasActiveOperation(ReminderState.initial), false);
      expect(hasActiveOperation(ReminderState.loading), false);
      expect(hasActiveOperation(ReminderState.loaded), false);
      expect(hasActiveOperation(ReminderState.error), false);
      expect(hasActiveOperation(ReminderState.creating), true);
      expect(hasActiveOperation(ReminderState.syncing), true);
    });
  });

  group('ReminderState Icon Mapping', () {
    test('can map states to icon names', () {
      String getIconName(ReminderState state) {
        return switch (state) {
          ReminderState.initial => 'hourglass_empty',
          ReminderState.loading => 'refresh',
          ReminderState.loaded => 'check_circle',
          ReminderState.error => 'error',
          ReminderState.creating => 'add_circle',
          ReminderState.syncing => 'sync',
        };
      }

      expect(getIconName(ReminderState.initial), 'hourglass_empty');
      expect(getIconName(ReminderState.loading), 'refresh');
      expect(getIconName(ReminderState.loaded), 'check_circle');
      expect(getIconName(ReminderState.error), 'error');
      expect(getIconName(ReminderState.creating), 'add_circle');
      expect(getIconName(ReminderState.syncing), 'sync');
    });
  });
}
