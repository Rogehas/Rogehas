import 'dart:ui' show Offset, Size;

import 'package:flutter/material.dart' show Switch;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tavas/data/content_repository.dart';
import 'package:tavas/data/mock_data.dart';
import 'package:tavas/main.dart';
import 'package:tavas/notifications/notification_settings.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('misafir girişi ana sayfayı açar, sekmeler çalışır', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      TavasApp(
        repository: MockContentRepository(),
        notifications: InMemoryNoticeSettings(),
      ),
    );
    expect(find.text('Tavas cebinde.'), findsOneWidget);

    await tester.tap(find.text('Misafir olarak gez'));
    await tester.pumpAndSettle();
    expect(find.text("Tavas'ta bugün"), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Vefat'));
    await tester.pumpAndSettle();
    expect(find.text('Ayşe Örnek'), findsOneWidget);
    expect(find.text('Vefat bildirimleri açık'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Haberler'));
    await tester.pumpAndSettle();
    expect(find.text('Başvuru tarihleri uzatıldı'), findsOneWidget);
    await tester.drag(find.text('Tümü'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kesinti'));
    await tester.pumpAndSettle();
    expect(find.text('Başvuru tarihleri uzatıldı'), findsNothing);
    expect(find.text('KESİNTİ · SU'), findsOneWidget);
  });

  testWidgets('içerik yüklenemezse sahte veri değil hata mesajı gösterilir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      TavasApp(
        repository: UnavailableContentRepository(StateError('yok')),
        notifications: InMemoryNoticeSettings(),
      ),
    );
    await tester.tap(find.text('Misafir olarak gez'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Vefat'));
    await tester.pumpAndSettle();
    expect(find.textContaining('İçerik yüklenemedi'), findsOneWidget);
    expect(find.text('Ayşe Örnek'), findsNothing);
  });

  testWidgets('vefat bildirim anahtarı tercihi değiştirir; izin yoksa uyarır', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final denied = InMemoryNoticeSettings(grantPermission: false);
    await tester.pumpWidget(
      TavasApp(repository: MockContentRepository(), notifications: denied),
    );
    await tester.tap(find.text('Misafir olarak gez'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Vefat'));
    await tester.pumpAndSettle();
    expect(find.text('Vefat bildirimleri açık'), findsOneWidget);

    // Kapat -> tercih değişir.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(denied.isEnabled(NoticeTopics.vefat), isFalse);
    expect(find.text('Vefat bildirimleri kapalı'), findsOneWidget);

    // Tekrar aç -> izin reddedildiği için açılmaz ve uyarı çıkar.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(denied.isEnabled(NoticeTopics.vefat), isFalse);
    expect(find.textContaining('Bildirim izni kapalı'), findsOneWidget);
  });

  testWidgets('uygulama açıkken gelen vefat bildirimi ekranda görünür', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final settings = InMemoryNoticeSettings();
    await tester.pumpWidget(
      TavasApp(repository: MockContentRepository(), notifications: settings),
    );
    await tester.tap(find.text('Misafir olarak gez'));
    await tester.pumpAndSettle();

    settings.simulateForeground(
      const NoticeMessage(
        topic: 'vefat',
        title: 'Vefat · Deneme',
        body: 'Cenaze namazı bugün 13:30.',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Vefat · Deneme'), findsOneWidget);
    expect(find.text('Gör'), findsOneWidget);
  });
}
