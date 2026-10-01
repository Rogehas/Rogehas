import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tavas/auth/auth_service.dart';
import 'package:tavas/complaints/complaint_repository.dart';
import 'package:tavas/data/mock_data.dart';
import 'package:tavas/main.dart';
import 'package:tavas/notifications/notification_settings.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('şikâyet kuralları', () {
    test('konu ve uzunluk denetlenir', () {
      expect(
        validateComplaint(category: '', text: 'Yeterince uzun bir mesaj'),
        isNotNull,
      );
      expect(validateComplaint(category: 'Öneri', text: 'kısa'), isNotNull);
      expect(
        validateComplaint(
          category: 'Öneri',
          text: 'a' * (maxComplaintLength + 1),
        ),
        isNotNull,
      );
      expect(
        validateComplaint(
          category: 'Öneri',
          text: 'Parka bank konulsun lütfen',
        ),
        isNull,
      );
    });

    test('durum adları bilinmeyen değerde "Alındı" olur', () {
      expect(ComplaintStatus.parse('resolved'), ComplaintStatus.resolved);
      expect(ComplaintStatus.parse(null), ComplaintStatus.newOne);
      expect(ComplaintStatus.parse('?'), ComplaintStatus.newOne);
    });
  });

  group('şikâyet ekranı', () {
    late InMemoryAuthService auth;
    late InMemoryComplaintRepository repo;

    Future<void> openScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        TavasApp(
          repository: MockContentRepository(),
          notifications: InMemoryNoticeSettings(),
          auth: auth,
          complaints: repo,
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Şikâyet\nÖneri'));
      await tester.tap(find.text('Şikâyet\nÖneri'));
      await tester.pumpAndSettle();
    }

    setUp(() {
      auth = InMemoryAuthService();
      repo = InMemoryComplaintRepository();
    });

    testWidgets('üye değilken giriş istenir, form görünmez', (tester) async {
      await openScreen(tester);
      expect(find.text('Önce üye ol'), findsOneWidget);
      expect(find.text('Gönder'), findsNothing);
    });

    testWidgets('üye gönderir, listede görür, yanıt ve durum güncellenir', (
      tester,
    ) async {
      await auth.signUp(name: 'Mehmet', email: 'm@o.com', password: 'sifre123');
      await openScreen(tester);
      expect(find.text('Henüz bir şey göndermedin.'), findsOneWidget);

      // Konu seçmeden gönderilemez.
      await tester.enterText(
        find.byType(TextField).at(1),
        'Sokak lambası yanmıyor, bakar mısınız',
      );
      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();
      expect(find.text('Bir konu seç.'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aydınlatma').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Merkez Mah.');
      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();

      expect(find.textContaining('mesajın alındı'), findsOneWidget);
      expect(find.text('Henüz bir şey göndermedin.'), findsNothing);
      expect(find.textContaining('Sokak lambası yanmıyor'), findsOneWidget);
      expect(find.text('Alındı'), findsOneWidget);

      repo.respond('c1', ComplaintStatus.resolved, 'Lamba değiştirildi.');
      await tester.pumpAndSettle();
      expect(find.text('Çözüldü'), findsOneWidget);
      expect(find.text('Lamba değiştirildi.'), findsOneWidget);
    });
  });
}
