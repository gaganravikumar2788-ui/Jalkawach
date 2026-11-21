import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flood_guard/app.dart';
import 'package:flood_guard/core/constants/app_constants.dart';
import 'package:flood_guard/core/services/api_service.dart';
import 'package:flood_guard/core/services/storage_service.dart';

void main() {
  testWidgets('App splash screen and navigation smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();
    final apiService = ApiService(useMockData: true);

    await tester.pumpWidget(
      FloodGuardApp(
        storageService: storageService,
        apiService: apiService,
      ),
    );

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('FLOOD DISASTER PREPAREDNESS'), findsOneWidget);

    // Fast forward splash timer and transition into login screen
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    // Verify login screen elements
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    // Enter credentials
    await tester.enterText(find.byType(TextFormField).first, 'test@jalkawach.gov.in');
    await tester.enterText(find.byType(TextFormField).last, 'password123');

    // Scroll down inside SingleChildScrollView to ensure Login button is completely visible
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();

    // Tap Login button
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Verify main home dashboard top components are rendered
    expect(find.text('ESTIMATED FLOOD RISK'), findsOneWidget);
  });
}
