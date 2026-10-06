import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tavas/auth/auth_service.dart';
import 'package:tavas/auth/firebase_auth_service.dart';
import 'package:tavas/chat/chat_logic.dart';
import 'package:tavas/chat/chat_repository.dart';
import 'package:tavas/data/mock_data.dart';
import 'package:tavas/main.dart';
import 'package:tavas/notifications/notification_settings.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('mesaj ve form kuralları', () {
    test('boş, çok uzun ve uygunsuz mesajlar reddedilir', () {
      expect(validateMessage('   '), isNotNull);
      expect(validateMessage('a' * (maxMessageLength + 1)), isNotNull);
      expect(validateMessage('a' * maxMessageLength), isNull);
      expect(validateMessage('Merhaba Tavas'), isNull);
      expect(validateMessage('siktir git'), isNotNull);
      expect(validateMessage('SİKTİR'), isNotNull);
      expect(validateMessage('amk'), isNotNull);
    });

    test('masum kelimeler yanlışlıkla engellenmez', () {
      for (final t in [
        'malzeme aldım',
        'kamyon',
        'Pişmaniye',
        'camii',
        'aqua',
      ]) {
        expect(containsBlockedWord(t), isFalse, reason: t);
      }
    });

    test('mesaj saati iki haneli gösterilir', () {
      expect(messageTime(DateTime(2026, 9, 30, 9, 5)), '09:05');
      expect(messageTime(null), '');
    });

    test('üyelik formu doğrulaması', () {
      expect(
        validateSignUp(name: 'A', email: 'a@b.co', password: '123456'),
        isNotNull,
      );
      expect(
        validateSignUp(name: 'Ali', email: 'yanlis', password: '123456'),
        isNotNull,
      );
      expect(
        validateSignUp(name: 'Ali', email: 'a@b.co', password: '123'),
        isNotNull,
      );
      expect(
        validateSignUp(name: 'Ali', email: 'a@b.co', password: '123456'),
        isNull,
      );
      expect(validateSignIn(email: 'a@b.co', password: ''), isNotNull);
    });

    test('Firebase hata kodları Türkçe açıklanır', () {
      expect(turkishAuthError('wrong-password'), contains('yanlış'));
      expect(turkishAuthError('email-already-in-use'), contains('zaten'));
      expect(turkishAuthError('bilinmeyen'), isNotEmpty);
    });

    test('engel listesi telefonda saklanır', () async {
      SharedPreferences.setMockInitialValues({});
      final a = await BlockList.load();
      await a.block('u9', 'Ayşe');
      final b = await BlockList.load();
      expect(b.isBlocked('u9'), isTrue);
      expect(b.all['u9'], 'Ayşe');
      await b.unblock('u9');
      expect((await BlockList.load()).isBlocked('u9'), isFalse);
    });
  });

  group('sohbet ekranı', () {
    late InMemoryAuthService auth;
    late InMemoryChatRepository chat;
    late BlockList blocks;

    Future<void> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        TavasApp(
          repository: MockContentRepository(),
          notifications: InMemoryNoticeSettings(),
          auth: auth,
          chat: chat,
          blocks: blocks,
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openTab(WidgetTester tester, String label) async {
      await tester.tap(find.bySemanticsLabel(label));
      await tester.pumpAndSettle();
    }

    Future<void> signUp(WidgetTester tester) async {
      await openTab(tester, 'Sohbet');
      await tester.tap(find.text('Üye ol'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Mehmet');
      await tester.enterText(find.byType(TextField).at(1), 'mehmet@ornek.com');
      await tester.enterText(find.byType(TextField).at(2), 'sifre123');
      await tester.tap(find.widgetWithText(FilledButton, 'Üye ol'));
      await tester.pumpAndSettle();
    }

    Future<List<ChatMessage>> stored() => chat.watchMessages().first;

    Future<void> send(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
    }

    setUp(() {
      auth = InMemoryAuthService();
      chat = InMemoryChatRepository();
      blocks = BlockList.memory();
    });

    testWidgets('üye değilken giriş/üyelik istenir, mesaj alanı yoktur', (
      tester,
    ) async {
      await pumpApp(tester);
      await openTab(tester, 'Sohbet');
      expect(find.text('Tavaslılarla sohbet et'), findsOneWidget);
      expect(find.text('Üye ol'), findsOneWidget);
      expect(find.text('Giriş yap'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('Firebase yoksa üyelik kullanılamıyor mesajı çıkar', (
      tester,
    ) async {
      auth = InMemoryAuthService(available: false);
      await pumpApp(tester);
      await openTab(tester, 'Sohbet');
      expect(find.textContaining('şu an kullanılamıyor'), findsOneWidget);
      expect(find.text('Üye ol'), findsNothing);
    });

    testWidgets('üye ol: hatalı form uyarır, doğru form sohbete sokar', (
      tester,
    ) async {
      await pumpApp(tester);
      await openTab(tester, 'Sohbet');
      await tester.tap(find.text('Üye ol'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Üye ol'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Adını yaz'), findsOneWidget);
      expect(auth.user, isNull);

      await tester.enterText(find.byType(TextField).at(0), 'Mehmet');
      await tester.enterText(find.byType(TextField).at(1), 'mehmet@ornek.com');
      await tester.enterText(find.byType(TextField).at(2), 'sifre123');
      await tester.tap(find.widgetWithText(FilledButton, 'Üye ol'));
      await tester.pumpAndSettle();
      expect(auth.user?.name, 'Mehmet');
      expect(find.text('Mehmet'), findsOneWidget); // başlıkta görünür
      expect(find.text('Mesajını yaz…'), findsOneWidget);
    });

    testWidgets(
      'mesaj gönderilir, alan temizlenir; hızlı ikinci mesaj beklenir',
      (tester) async {
        await pumpApp(tester);
        await signUp(tester);
        await send(tester, 'Herkese merhaba');
        expect(find.text('Herkese merhaba'), findsOneWidget);
        expect(find.text('Sen'), findsOneWidget);

        await send(tester, 'ikinci');
        expect(find.textContaining('Çok hızlı'), findsOneWidget);
        expect(await stored(), hasLength(1));
      },
    );

    testWidgets('uygunsuz mesaj gönderilmez', (tester) async {
      await pumpApp(tester);
      await signUp(tester);
      await send(tester, 'siktir');
      expect(find.textContaining('uygunsuz'), findsWidgets);
      expect(await stored(), isEmpty);
    });

    testWidgets('başkasının mesajı şikâyet edilir; ikinci kez uyarır', (
      tester,
    ) async {
      chat.seed('u99', 'Ayşe', 'Günaydın Tavas');
      await pumpApp(tester);
      await signUp(tester);
      expect(find.text('Günaydın Tavas'), findsOneWidget);

      await tester.tap(find.byTooltip('Mesaj seçenekleri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Şikâyet et'));
      await tester.pumpAndSettle();
      expect(chat.reports, hasLength(1));
      expect(find.textContaining('yöneticilere bildirildi'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.byTooltip('Mesaj seçenekleri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Şikâyet et'));
      await tester.pumpAndSettle();
      expect(chat.reports, hasLength(1));
      expect(find.textContaining('zaten bildirdin'), findsOneWidget);
    });

    testWidgets('engellenen kişinin mesajı gizlenir; Profil\'den kaldırılır', (
      tester,
    ) async {
      chat.seed('u99', 'Ayşe', 'Günaydın Tavas');
      await pumpApp(tester);
      await signUp(tester);

      await tester.tap(find.byTooltip('Mesaj seçenekleri'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('adlı kişiyi engelle'));
      await tester.pumpAndSettle();
      expect(find.text('Günaydın Tavas'), findsNothing);
      expect(blocks.isBlocked('u99'), isTrue);

      await openTab(tester, 'Profil');
      expect(find.text('Engellenenler'), findsOneWidget);
      await tester.tap(find.text('Engeli kaldır'));
      await tester.pumpAndSettle();
      expect(find.text('Engellenenler'), findsNothing);

      await openTab(tester, 'Sohbet');
      expect(find.text('Günaydın Tavas'), findsOneWidget);
    });

    testWidgets('kendi mesajını silebilir', (tester) async {
      await pumpApp(tester);
      await signUp(tester);
      await send(tester, 'silinecek mesaj');
      expect(find.text('silinecek mesaj'), findsOneWidget);
      await tester.tap(find.byTooltip('Mesaj seçenekleri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mesajı sil'));
      await tester.pumpAndSettle();
      expect(find.text('silinecek mesaj'), findsNothing);
    });

    testWidgets(
      'susturulan üye yazdığını görür, uyarı çıkmaz; başkası görmez',
      (tester) async {
        await pumpApp(tester);
        await signUp(tester);
        chat.setMuted(auth.user!.uid, true);
        await send(tester, 'gölge mesaj');
        expect(find.textContaining('susturuldu'), findsNothing);
        expect(find.text('gölge mesaj'), findsOneWidget);
        // Başka bir üyenin gözünden mesaj listede yok.
        final all = await chat.watchMessages().first;
        expect(all.single.shadow, isTrue);
        expect(
          visibleTo('baska', shadow: all.single.shadow, uid: all.single.uid),
          isFalse,
        );
      },
    );

    testWidgets(
      'çıkış yapınca sohbet kapanır; yanlış şifre uyarır, doğrusu girer',
      (tester) async {
        await pumpApp(tester);
        await signUp(tester);
        await openTab(tester, 'Profil');
        expect(find.text('Mehmet'), findsOneWidget);
        expect(find.text('mehmet@ornek.com'), findsOneWidget);
        await tester.tap(find.text('Çıkış yap'));
        await tester.pumpAndSettle();
        expect(auth.user, isNull);
        expect(find.text('Misafir'), findsOneWidget);

        await tester.tap(find.text('Giriş yap / Üye ol'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).at(0),
          'mehmet@ornek.com',
        );
        await tester.enterText(find.byType(TextField).at(1), 'yanlis');
        await tester.tap(find.widgetWithText(FilledButton, 'Giriş yap'));
        await tester.pumpAndSettle();
        expect(find.textContaining('yanlış'), findsOneWidget);
        expect(auth.user, isNull);

        await tester.enterText(find.byType(TextField).at(1), 'sifre123');
        await tester.tap(find.widgetWithText(FilledButton, 'Giriş yap'));
        await tester.pumpAndSettle();
        expect(auth.user?.name, 'Mehmet');
      },
    );

    testWidgets('şifremi unuttum e-posta gönderir', (tester) async {
      await pumpApp(tester);
      await openTab(tester, 'Sohbet');
      await tester.tap(find.text('Giriş yap'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Şifremi unuttum'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'mehmet@ornek.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Bağlantı gönder'));
      await tester.pumpAndSettle();
      expect(auth.lastResetEmail, 'mehmet@ornek.com');
      expect(find.textContaining('e-postana gönderildi'), findsOneWidget);
    });

    testWidgets('hesap silme: şifre sorulur, mesajlar da silinir', (
      tester,
    ) async {
      await pumpApp(tester);
      await signUp(tester);
      await send(tester, 'benim mesajım');
      await openTab(tester, 'Profil');

      await tester.ensureVisible(find.text('Hesabımı sil'));
      await tester.tap(find.text('Hesabımı sil'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'yanlis');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Hesabımı sil'),
        ),
      );
      await tester.pumpAndSettle();
      expect(auth.user, isNotNull);
      expect(find.textContaining('Şifre yanlış'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('Hesabımı sil'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'sifre123');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Hesabımı sil'),
        ),
      );
      await tester.pumpAndSettle();
      expect(auth.user, isNull);
      expect(auth.deleted, hasLength(1));
      await chat.watchMessages().first.then((m) => expect(m, isEmpty));
    });
  });
}
