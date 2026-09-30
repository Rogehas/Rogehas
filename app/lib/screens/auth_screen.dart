import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sub_page.dart';

enum AuthMode { signIn, signUp, reset }

/// Giriş yap / üye ol / şifremi unuttum. Başarılı girişte kapanır (true döner).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.mode = AuthMode.signIn});
  final AuthMode mode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthMode _mode = widget.mode;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switch(AuthMode m) => setState(() {
    _mode = m;
    _error = null;
    _info = null;
  });

  Future<void> _submit() async {
    final auth = AuthScope.of(context);
    final nav = Navigator.of(context);
    final problem = switch (_mode) {
      AuthMode.signUp => validateSignUp(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      ),
      AuthMode.signIn => validateSignIn(
        email: _email.text,
        password: _password.text,
      ),
      AuthMode.reset => validateSignIn(email: _email.text, password: 'x'),
    };
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      switch (_mode) {
        case AuthMode.signIn:
          await auth.signIn(email: _email.text, password: _password.text);
          if (mounted) nav.pop(true);
        case AuthMode.signUp:
          await auth.signUp(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          );
          if (mounted) nav.pop(true);
        case AuthMode.reset:
          await auth.sendPasswordReset(_email.text);
          if (mounted) {
            setState(
              () => _info = 'Şifre yenileme bağlantısı e-postana gönderildi. Gelen kutunu (ve gereksiz klasörünü) kontrol et.',
            );
          }
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final title = switch (_mode) {
      AuthMode.signIn => 'Giriş yap',
      AuthMode.signUp => 'Üye ol',
      AuthMode.reset => 'Şifremi unuttum',
    };
    final action = switch (_mode) {
      AuthMode.signIn => 'Giriş yap',
      AuthMode.signUp => 'Üye ol',
      AuthMode.reset => 'Bağlantı gönder',
    };
    return SubPage(
      title: title,
      children: [
        if (!auth.available)
          const SoftNotice(
            Icons.cloud_off_outlined,
            'Üyelik şu an kullanılamıyor. Biraz sonra tekrar dene.',
          )
        else ...[
          Text(
            switch (_mode) {
              AuthMode.signIn => 'Sohbete katılmak için hesabınla giriş yap.',
              AuthMode.signUp => 'Sohbete katılmak için ücretsiz üye ol. Haber, vefat ilanı ve eczane için üyelik gerekmez.',
              AuthMode.reset => 'E-posta adresini yaz, şifreni yenilemen için bağlantı gönderelim.',
            },
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          if (_mode == AuthMode.signUp) ...[
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 30,
              decoration: _decoration(
                'Adın (sohbette görünür)',
                Icons.badge_outlined,
              ),
            ),
            const SizedBox(height: 4),
          ],
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: _mode == AuthMode.reset
                ? TextInputAction.done
                : TextInputAction.next,
            decoration: _decoration('E-posta', Icons.mail_outline),
          ),
          if (_mode != AuthMode.reset) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _busy ? null : _submit(),
              decoration: _decoration('Şifre', Icons.lock_outline),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.clay,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (_info != null) ...[
            const SizedBox(height: 12),
            Text(
              _info!,
              style: const TextStyle(
                color: AppColors.accentText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(action),
            ),
          ),
          const SizedBox(height: 8),
          if (_mode == AuthMode.signIn) ...[
            TextButton(
              onPressed: () => _switch(AuthMode.reset),
              child: const Text('Şifremi unuttum'),
            ),
            TextButton(
              onPressed: () => _switch(AuthMode.signUp),
              child: const Text('Hesabın yok mu? Üye ol'),
            ),
          ] else ...[
            TextButton(
              onPressed: () => _switch(AuthMode.signIn),
              child: const Text('Zaten üyeyim, giriş yap'),
            ),
          ],
        ],
      ],
    );
  }
}
