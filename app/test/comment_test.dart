import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tavas/auth/auth_service.dart';
import 'package:tavas/chat/chat_repository.dart';
import 'package:tavas/comments/comment_repository.dart';
import 'package:tavas/data/content_mapper.dart';
import 'package:tavas/data/mock_data.dart';
import 'package:tavas/main.dart';
import 'package:tavas/notifications/notification_settings.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('yorum kuralları: boş, uzun ve uygunsuz yorum reddedilir', () {
    expect(validateComment('  '), isNotNull);
    expect(validateComment('a' * (maxCommentLength + 1)), isNotNull);
    expect(validateComment('siktir'), isNotNull);
    expect(validateComment('Çok teşekkürler, güzel haber'), isNull);
  });

  test(
    'belgede commentsOpen yoksa yorumlar açık sayılır; false ise kapalı',
    () {
      Map<String, dynamic> base() => {
        'kind': 'haber',
        'title': 'T',
        'status': 'published',
        'id': 'x1',
      };
      expect(ContentMapper.news(base()).commentsOpen, isTrue);
      expect(ContentMapper.news(base()).id, 'x1');
      expect(
        ContentMapper.news({...base(), 'commentsOpen': false}).commentsOpen,
        isFalse,
      );
    },
  );

  group('haber yorumları', () {
    late InMemoryAuthService auth;
    late InMemoryCommentRepository comments;
    late InMemoryChatRepository chat;
    late BlockList blocks;

    Future<void> openNews(WidgetTester tester, String title) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        TavasApp(
          repository: MockContentRepository(),
          notifications: InMemoryNoticeSettings(),
          auth: auth,
          comments: comments,
          chat: chat,
          blocks: blocks,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Haberler'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(title));
      await tester.pumpAndSettle();
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Yorumlar'));
      await tester.pumpAndSettle();
    }

    const open = "Tavas'ta sonbahar etkinlik takvimi açıklandı";

    setUp(() {
      auth = InMemoryAuthService();
      comments = InMemoryCommentRepository();
      chat = InMemoryChatRepository();
      blocks = BlockList.memory();
    });

    testWidgets('üye değilken yorumlar okunur ama yazmak için giriş istenir', (
      tester,
    ) async {
      comments.seed('n1', 'u9', 'Ayşe', 'Çok güzel olmuş');
      await openNews(tester, open);
      expect(find.text('Çok güzel olmuş'), findsOneWidget);
      expect(
        find.text('Yorum yazmak için giriş yapman gerekiyor.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('üye yorum yazar, yorum listede görünür', (tester) async {
      await auth.signUp(name: 'Mehmet', email: 'm@o.com', password: 'sifre123');
      await openNews(tester, open);
      expect(find.text('Henüz yorum yok. İlk yorumu sen yaz!'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Teşekkürler');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(find.text('Teşekkürler'), findsOneWidget);
      expect(find.text('Mehmet'), findsOneWidget);
    });

    testWidgets('uygunsuz yorum gönderilmez', (tester) async {
      await auth.signUp(name: 'Mehmet', email: 'm@o.com', password: 'sifre123');
      await openNews(tester, open);
      await tester.enterText(find.byType(TextField), 'siktir');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(find.textContaining('uygunsuz'), findsOneWidget);
      expect(find.text('Henüz yorum yok. İlk yorumu sen yaz!'), findsOneWidget);
    });

    testWidgets(
      'başkasının yorumu şikâyet edilir, kişi engellenir; kendi yorumu silinir',
      (tester) async {
        comments.seed('n1', 'u9', 'Ayşe', 'Katılmıyorum');
        await auth.signUp(
          name: 'Mehmet',
          email: 'm@o.com',
          password: 'sifre123',
        );
        await openNews(tester, open);

        await tester.tap(find.byTooltip('Yorum seçenekleri'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Şikâyet et'));
        await tester.pumpAndSettle();
        expect(comments.reports, hasLength(1));

        await tester.pumpAndSettle(const Duration(seconds: 5));
        await tester.tap(find.byTooltip('Yorum seçenekleri'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('adlı kişiyi engelle'));
        await tester.pumpAndSettle();
        expect(find.text('Katılmıyorum'), findsNothing);

        await tester.enterText(find.byType(TextField), 'Benim yorumum');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Yorum seçenekleri'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yorumu sil'));
        await tester.pumpAndSettle();
        expect(find.text('Benim yorumum'), findsNothing);
      },
    );

    testWidgets('susturulan üye yorum yazamaz', (tester) async {
      await auth.signUp(name: 'Mehmet', email: 'm@o.com', password: 'sifre123');
      chat.setMuted(auth.user!.uid, true);
      await openNews(tester, open);
      expect(find.textContaining('susturuldu'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets(
      'yorumları kapalı haberde kapalı mesajı çıkar, yorum alanı yoktur',
      (tester) async {
        await auth.signUp(
          name: 'Mehmet',
          email: 'm@o.com',
          password: 'sifre123',
        );
        await openNews(tester, 'Belediye hizmet saatlerinde yeni düzenleme');
        expect(find.text('Bu haber için yorumlar kapalı.'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
      },
    );
  });
}
