import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/writer_story.dart';

class WriterLocalService {
  static const String _storiesKey = 'writer_stories';

  Future<List<WriterStory>> getStories() async {
    final preferences = await SharedPreferences.getInstance();
    final rawStories = preferences.getString(_storiesKey);

    if (rawStories == null || rawStories.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rawStories);

      if (decoded is! List) {
        return [];
      }

      final stories = decoded
          .whereType<Map>()
          .map(
            (story) => WriterStory.fromJson(Map<String, dynamic>.from(story)),
          )
          .toList();

      stories.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return stories;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveStories(List<WriterStory> stories) async {
    final preferences = await SharedPreferences.getInstance();

    final encoded = jsonEncode(stories.map((story) => story.toJson()).toList());

    await preferences.setString(_storiesKey, encoded);
  }

  Future<void> createStory(WriterStory story) async {
    final stories = await getStories();

    final exists = stories.any((existingStory) => existingStory.id == story.id);

    if (exists) {
      await updateStory(story);
      return;
    }

    stories.insert(0, story);

    await saveStories(stories);
  }

  Future<void> updateStory(WriterStory updatedStory) async {
    final stories = await getStories();

    final index = stories.indexWhere((story) => story.id == updatedStory.id);

    if (index == -1) {
      stories.insert(0, updatedStory);
    } else {
      stories[index] = updatedStory;
    }

    stories.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    await saveStories(stories);
  }

  Future<void> deleteStory(String storyId) async {
    final stories = await getStories();

    stories.removeWhere((story) => story.id == storyId);

    await saveStories(stories);
  }

  Future<WriterStory?> getStoryById(String storyId) async {
    final stories = await getStories();

    for (final story in stories) {
      if (story.id == storyId) {
        return story;
      }
    }

    return null;
  }

  Future<void> clearStories() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_storiesKey);
  }
}
