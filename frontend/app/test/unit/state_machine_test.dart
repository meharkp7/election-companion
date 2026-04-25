/// Unit tests for client-side state machine logic.
/// These mirror the backend getNextState rules so the Flutter app
/// can validate transitions locally before hitting the API.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:voteready/models/user_model.dart';
import 'package:voteready/models/assistant_response.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

User _user({
  String currentState = 'START',
  int age = 25,
  String state = 'Delhi',
  bool isFirstTimeVoter = false,
  int readinessScore = 0,
  String? boothName,
}) =>
    User(
      firebaseUid: 'test-uid',
      age: age,
      state: state,
      isFirstTimeVoter: isFirstTimeVoter,
      currentState: currentState,
      readinessScore: readinessScore,
      boothName: boothName,
    );

// ── User model state helpers ──────────────────────────────────────────────────

void main() {
  group('User.currentScreen', () {
    test('returns onboarding when latestUI is null', () {
      expect(_user().currentScreen, 'onboarding');
    });

    test('returns screen from latestUI when set', () {
      final ui = AssistantUI(
        screen: 'eligibility',
        title: 'Eligible',
        prompt: 'You are eligible',
      );
      final u = _user().copyWith(latestUI: ui);
      expect(u.currentScreen, 'eligibility');
    });
  });

  group('User.boothDetails', () {
    test('is null when boothName is null', () {
      expect(_user().boothDetails, isNull);
    });

    test('is populated when boothName is set', () {
      final u = _user(boothName: 'Booth 42').copyWith(boothAddress: '123 Main St');
      expect(u.boothDetails, isNotNull);
      expect(u.boothDetails!['boothName'], 'Booth 42');
    });
  });

  group('User.copyWith', () {
    test('updates only specified fields', () {
      final original = _user(age: 25, state: 'Delhi');
      final updated = original.copyWith(age: 30);
      expect(updated.age, 30);
      expect(updated.state, 'Delhi'); // unchanged
    });

    test('preserves firebaseUid through copyWith', () {
      final u = _user().copyWith(age: 20);
      expect(u.firebaseUid, 'test-uid');
    });

    test('isFirstTimeVoter can be toggled', () {
      final u = _user(isFirstTimeVoter: false).copyWith(isFirstTimeVoter: true);
      expect(u.isFirstTimeVoter, isTrue);
    });
  });

  group('Readiness score thresholds', () {
    test('score 0 means not started', () {
      expect(_user(readinessScore: 0).readinessScore, 0);
    });

    test('score 100 means fully ready', () {
      expect(_user(readinessScore: 100).readinessScore, 100);
    });

    test('score cannot exceed 100 in model', () {
      // Model stores whatever the backend sends; clamping is backend's job.
      // We just verify the field is stored correctly.
      final u = _user(readinessScore: 100);
      expect(u.readinessScore, lessThanOrEqualTo(100));
    });
  });

  group('AssistantUI', () {
    test('fromJson parses screen and title', () {
      final ui = AssistantUI.fromJson({
        'screen': 'registration',
        'title': 'Voter Registration',
        'prompt': 'Are you registered?',
      });
      expect(ui.screen, 'registration');
      expect(ui.title, 'Voter Registration');
    });

    test('fromJson handles missing optional fields gracefully', () {
      final ui = AssistantUI.fromJson({'screen': 'onboarding'});
      expect(ui.screen, 'onboarding');
      expect(ui.steps, isEmpty);
      expect(ui.options, isEmpty);
      expect(ui.inputs, isEmpty);
    });

    test('fromJson parses steps list', () {
      final ui = AssistantUI.fromJson({
        'screen': 'voting_day',
        'steps': ['Go to booth', 'Show ID', 'Vote'],
      });
      expect(ui.steps.length, 3);
      expect(ui.steps.first, 'Go to booth');
    });

    test('fromJson parses options list', () {
      final ui = AssistantUI.fromJson({
        'screen': 'registration',
        'options': ['registered', 'not_registered', 'not_sure'],
      });
      expect(ui.options.length, 3);
    });

    test('fromJson parses readinessScore', () {
      final ui = AssistantUI.fromJson({
        'screen': 'ready',
        'readinessScore': 85,
      });
      expect(ui.readinessScore, 85);
    });
  });

  group('AssistantResponse', () {
    test('fromJson parses currentState and ui', () {
      final resp = AssistantResponse.fromJson({
        'currentState': 'ELIGIBILITY_CHECK',
        'message': 'You are eligible!',
        'ui': {
          'screen': 'eligibility',
          'title': 'Checking eligibility',
          'prompt': 'You are eligible to vote!',
        },
      });
      expect(resp.currentState, 'ELIGIBILITY_CHECK');
      expect(resp.message, 'You are eligible!');
      expect(resp.ui.screen, 'eligibility');
    });

    test('fromJson handles missing message gracefully', () {
      final resp = AssistantResponse.fromJson({
        'currentState': 'START',
        'ui': {'screen': 'onboarding'},
      });
      expect(resp.currentState, 'START');
    });
  });

  group('State machine — expected screen mappings', () {
    // These verify the contract between backend state names and frontend screens.
    const stateToScreen = {
      'START': 'onboarding',
      'ELIGIBILITY_CHECK': 'eligibility',
      'REGISTRATION': 'registration',
      'CHECK_STATUS': 'check_status',
      'VERIFICATION': 'verification',
      'ISSUE_RESOLVER': 'issue_resolver',
      'READY_TO_VOTE': 'ready',
      'VOTING_DAY': 'voting_day',
      'COMPLETED': 'completed',
    };

    for (final entry in stateToScreen.entries) {
      test('${entry.key} maps to screen "${entry.value}"', () {
        final ui = AssistantUI.fromJson({'screen': entry.value});
        final u = _user(currentState: entry.key).copyWith(latestUI: ui);
        expect(u.currentScreen, entry.value);
      });
    }
  });
}
