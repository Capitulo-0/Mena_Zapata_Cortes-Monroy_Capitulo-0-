import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android/features/writer/services/writer_local_service.dart';
import 'package:android/features/writer/models/writer_story.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('new account namespaces preserve legacy Writer data without sharing it', () async {
    SharedPreferences.setMockInitialValues({});
    final legacy = WriterLocalService();
    final first = WriterLocalService(scope: 'fixture-account-a');
    final second = WriterLocalService(scope: 'fixture-account-b');
    final story = WriterStory(
      id: 'fixture-story',
      title: 'Draft',
      synopsis: 'Synopsis',
      genre: 'Fiction',
      status: WriterStoryStatus.draft,
      chapters: [],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await legacy.createStory(story);
    expect(await first.getStories(), isEmpty);
    await first.createStory(story.copyWith(id: 'account-a-story'));
    expect(await second.getStories(), isEmpty);
    expect((await legacy.getStories()).single.id, 'fixture-story');
    expect((await first.getStories()).single.id, 'account-a-story');
    // No clear/delete during signout: same account can recover its local draft.
    expect(
      (await WriterLocalService(
        scope: 'fixture-account-a',
      ).getStories()).single.id,
      'account-a-story',
    );
  });
}
