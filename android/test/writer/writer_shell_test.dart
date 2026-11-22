import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/core/session/local_account_scope.dart';
import 'package:android/features/home/presentation/screens/main_shell_screen.dart';
import 'package:android/features/profile/presentation/screens/profile_screen.dart';
import 'package:android/features/writer/services/writer_local_service.dart';
import 'package:android/features/writer/presentation/screens/writer_legacy_screen.dart';

import '../library_regression_test.dart' show installLocalTestAssets;
import 'writer_flow_test.dart' show TestWriterRepository;
import 'writer_closure_test.dart' show fixture;

class _NoNativeMap extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) => const SizedBox.expand();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleMapsFlutterPlatform.instance = _NoNativeMap();
  });
  testWidgets(
    'profile loads remote publications without claiming or deleting legacy stories',
    (t) async {
      final remote = fixture(published: true);
      final legacy = remote.copyWith(
        id: 'legacy-only',
        title: 'Local anterior',
      );
      final local = WriterLocalService(scope: 'a');
      await local.createStory(legacy);
      final repo = TestWriterRepository({remote.id: remote.toJson()});
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: LocalAccountScope(
            uid: 'a',
            child: MainShellScreen(
              writerRepository: repo,
              isGuest: false,
              onLogout: () {},
              onGuestLoginRequested: () {},
              onGuestRegisterRequested: () {},
              isDarkMode: false,
              onDarkModeChanged: (_) {},
            ),
          ),
        ),
      );
      // MainShell incorpora Maps, que puede programar frames continuamente.
      // La comprobación consulta el perfil montado, no requiere animaciones en reposo.
      await t.pump();
      await t.pump(const Duration(milliseconds: 450));
      final profile = t.widget<ProfileScreen>(
        find.byType(ProfileScreen, skipOffstage: false),
      );
      expect(profile.publishedStories.map((s) => s.id), ['original']);
      expect(repo.loads, 1);
      expect((await local.getStories()).single.id, 'legacy-only');
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('legacy screen is read only and account scoped', (t) async {
    final story = fixture();
    final a = WriterLocalService(scope: 'a'),
        b = WriterLocalService(scope: 'b'),
        unowned = WriterLocalService();
    await a.createStory(story.copyWith(title: 'Anterior de A'));
    await b.createStory(story.copyWith(title: 'Anterior de B'));
    await unowned.createStory(story.copyWith(title: 'Sin dueño verificado'));
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const WriterLegacyScreen(ownerUid: 'a'),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Anterior de A'), findsOneWidget);
    expect(find.text('Anterior de B'), findsNothing);
    expect(find.text('Sin dueño verificado'), findsNothing);
    expect(await a.getStories(), hasLength(1));
    expect(await b.getStories(), hasLength(1));
    expect(await unowned.getStories(), hasLength(1));
    expect(t.takeException(), isNull);
  });
}
