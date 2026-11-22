import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/features/home/presentation/widgets/community_stories_section.dart';
import 'package:android/features/writer/models/writer_publication.dart';

WriterPublication publication(String id, String title, String author) =>
    WriterPublication(
      id: id,
      title: title,
      synopsis: 'Sinopsis real de $title',
      genre: 'Novela',
      coverPath: null,
      authorName: author,
      authorUsername: author,
      chapterCount: 1,
    );

void main() {
  testWidgets('Home muestra publicaciones reales y permite abrir autor y lector',
      (tester) async {
    final publications = [
      publication('obra-1', 'Primera obra', 'autora1'),
      publication('obra-2', 'Segunda obra', 'autora2'),
      publication('obra-3', 'Tercera obra', 'autora3'),
    ];
    String? openedAuthor;
    String? openedStory;
    var openedCommunity = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CommunityStoriesSection(
            stories: publications,
            loading: false,
            error: null,
            onRetry: () {},
            onCommunity: () => openedCommunity = true,
            onAuthorTap: (story) => openedAuthor = story.authorUsername,
            onStoryTap: (story) => openedStory = story.id,
          ),
        ),
      ),
    ));

    expect(find.text('Primera obra'), findsOneWidget);
    expect(find.text('Segunda obra'), findsOneWidget);
    expect(find.text('Tercera obra'), findsOneWidget);
    expect(find.text('El Jardín de los Recuerdos'), findsNothing);

    await tester.tap(find.text('@autora1'));
    expect(openedAuthor, 'autora1');

    await tester.tap(find.text('✦ Comunidad'));
    expect(openedCommunity, isTrue);

    await tester.ensureVisible(find.text('Primera obra'));
    await tester.tap(find.text('Leer historia completa').first);
    expect(openedStory, 'obra-1');
  });
}
