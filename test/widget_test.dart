import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahayak_ai/models/emergency_request.dart';
import 'package:sahayak_ai/widgets/request_card.dart';
import 'package:sahayak_ai/screens/login_screen.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Helper: build a fake EmergencyRequest for testing
  // ─────────────────────────────────────────────────────────────────────────
  EmergencyRequest fakeRequest({
    CriticalityLevel level = CriticalityLevel.high,
    int score = 75,
    String description = 'Person collapsed near the bus stop',
    RequestStatus status = RequestStatus.open,
  }) {
    return EmergencyRequest(
      id: 'test-id-001',
      userId: 'user-abc',
      userDisplayName: 'Roniit',
      description: description,
      latitude: 28.6139,
      longitude: 77.2090,
      criticalityLevel: level,
      criticalityScore: score,
      status: status,
      timestamp: DateTime(2025, 6, 15, 10, 30),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GROUP 1: RequestCard Widget Tests
  // (No Firebase needed — pure widget rendering)
  // ─────────────────────────────────────────────────────────────────────────
  group('RequestCard Widget', () {
    testWidgets('displays the user display name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestCard(request: fakeRequest()),
          ),
        ),
      );

      expect(find.text('Roniit'), findsOneWidget);
    });

    testWidgets('displays the emergency description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestCard(
              request: fakeRequest(
                description: 'Person collapsed near the bus stop',
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('Person collapsed near the bus stop'),
        findsOneWidget,
      );
    });

    testWidgets('displays the criticality score badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestCard(request: fakeRequest(score: 75)),
          ),
        ),
      );

      expect(find.text('75'), findsOneWidget);
    });

    testWidgets('shows Respond and View on Map buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestCard(request: fakeRequest()),
          ),
        ),
      );

      expect(find.text('Respond'), findsOneWidget);
      expect(find.text('View on Map'), findsOneWidget);
    });

    testWidgets('calls onResolve callback when Respond tapped', (tester) async {
      bool wasResolveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestCard(
              request: fakeRequest(),
              onResolve: () => wasResolveCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Respond'));
      await tester.pump();

      expect(wasResolveCalled, isTrue);
    });

    testWidgets('calls onMapTap callback when View on Map tapped',
        (tester) async {
      bool wasMapTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestCard(
              request: fakeRequest(),
              onMapTap: () => wasMapTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('View on Map'));
      await tester.pump();

      expect(wasMapTapped, isTrue);
    });

    testWidgets('CRITICAL level card renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestCard(
              request: fakeRequest(
                level: CriticalityLevel.critical,
                score: 95,
                description: 'Not breathing, need CPR immediately',
              ),
            ),
          ),
        ),
      );

      // No exception thrown = pass
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('95'), findsOneWidget);
    });

    testWidgets('LOW level card renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestCard(
              request: fakeRequest(
                level: CriticalityLevel.low,
                score: 10,
                description: 'My cat is stuck in a tree',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // GROUP 2: EmergencyRequest Model Tests
  // (Pure Dart — no Flutter or Firebase needed)
  // ─────────────────────────────────────────────────────────────────────────
  group('EmergencyRequest Model', () {
    test('toFirestore() includes all required fields', () {
      final request = fakeRequest();
      final map = request.toFirestore();

      expect(map.containsKey('userId'), isTrue);
      expect(map.containsKey('description'), isTrue);
      expect(map.containsKey('latitude'), isTrue);
      expect(map.containsKey('longitude'), isTrue);
      expect(map.containsKey('criticalityScore'), isTrue);
      expect(map.containsKey('criticalityLevel'), isTrue);
      expect(map.containsKey('status'), isTrue);
    });

    test('toFirestore() serializes status as string name', () {
      final request = fakeRequest(status: RequestStatus.open);
      final map = request.toFirestore();

      expect(map['status'], equals('open'));
    });

    test('toFirestore() serializes criticalityLevel as string name', () {
      final request = fakeRequest(level: CriticalityLevel.critical);
      final map = request.toFirestore();

      expect(map['criticalityLevel'], equals('critical'));
    });

    test('CriticalityLevel enum has all four levels', () {
      expect(CriticalityLevel.values.length, equals(4));
      expect(CriticalityLevel.values.map((e) => e.name),
          containsAll(['low', 'medium', 'high', 'critical']));
    });

    test('RequestStatus enum has all three statuses', () {
      expect(RequestStatus.values.length, equals(3));
      expect(RequestStatus.values.map((e) => e.name),
          containsAll(['open', 'acknowledged', 'resolved']));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // GROUP 3: LoginScreen Widget Tests
  // (No Firebase calls made — just renders the form)
  // ─────────────────────────────────────────────────────────────────────────
  group('LoginScreen Widget', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      expect(find.byType(TextFormField), findsNWidgets(2)); // email + password
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders Sign In button by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('toggling to Sign Up shows Name field and 3 inputs',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Tap the toggle button
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      // Now there should be 3 fields: name, email, password
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('shows validation error when Sign In tapped with empty fields',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Tap Sign In without filling in anything
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Form validators should fire
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Min 6 characters'), findsOneWidget);
    });

    testWidgets('toggling back to Sign In hides the Name field',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Go to sign up
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();
      expect(find.byType(TextFormField), findsNWidgets(3));

      // Go back to sign in
      await tester.tap(find.text('Already have an account? Sign In'));
      await tester.pump();
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
  });
}
