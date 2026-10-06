import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavas/auth/auth_service.dart';
import 'package:tavas/members/member_registry.dart';

void main() {
  testWidgets('giriş yapan üye kayda geçer; çıkış ve tekrar giriş çoğaltmaz', (
    tester,
  ) async {
    final auth = InMemoryAuthService();
    final reg = InMemoryMemberRegistry();
    await tester.pumpWidget(
      MemberSync(registry: reg, auth: auth, child: const SizedBox()),
    );
    expect(reg.members, isEmpty);
    await auth.signUp(name: 'Mehmet', email: 'm@o.com', password: 'sifre123');
    await tester.pump();
    expect(reg.members.values.single.name, 'Mehmet');
    expect(reg.members.values.single.email, 'm@o.com');
    await auth.signOut();
    await auth.signIn(email: 'm@o.com', password: 'sifre123');
    await tester.pump();
    expect(reg.members, hasLength(1));
  });
}
