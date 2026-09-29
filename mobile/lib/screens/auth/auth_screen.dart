import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../screens/user/user_main_screen.dart';
import '../../screens/vet/vet_main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVet = _tab.index == 1;
    final primary = isVet ? AppColors.vetPrimary : AppColors.userPrimary;

    return Theme(
      data: isVet ? AppTheme.vet() : AppTheme.user(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isVet
                        ? [AppColors.vetPrimary, AppColors.vetSecondary]
                        : [AppColors.userPrimary, AppColors.userSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        isVet ? Icons.medical_services : Icons.pets,
                        key: ValueKey(isVet),
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'VetDoğum',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isVet ? 'Veteriner Portalı' : 'Hayvan Sahibi Portalı',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tab,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: primary,
                        unselectedLabelColor: Colors.white,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(text: '👤  Hayvan Sahibi'),
                          Tab(text: '🩺  Veteriner'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form ────────────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _LoginForm(
                        role: UserRole.user,
                        primary: AppColors.userPrimary,
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _LoginForm(
                        role: UserRole.vet,
                        primary: AppColors.vetPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Giriş/Kayıt Formu ───────────────────────────────────────────────────────
class _LoginForm extends StatefulWidget {
  final UserRole role;
  final Color primary;
  const _LoginForm({required this.role, required this.primary});
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _clinicCtrl = TextEditingController();
  final _licCtrl = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _showPass = false;

  final _auth = FirebaseAuth.instance;
  final _db = FirestoreService();

  @override
  void dispose() {
    for (final c in [
      _emailCtrl,
      _passCtrl,
      _nameCtrl,
      _phoneCtrl,
      _clinicCtrl,
      _licCtrl,
    ])
      c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_isLogin) {
        final cred = await _auth.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        final user = await _db.getUser(cred.user!.uid);
        if (user == null) throw Exception('Kullanıcı bulunamadı');

        if (user.role != widget.role) {
          await _auth.signOut();
          _showErr(
            widget.role == UserRole.vet
                ? 'Bu hesap veteriner hesabı değil.'
                : 'Bu hesap hayvan sahibi hesabı değil.',
          );
          return;
        }
        _navigate(user);
      } else {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        final user = AppUser(
          id: cred.user!.uid,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: '',
          email: _emailCtrl.text.trim(),
          role: widget.role,
          clinicName: widget.role == UserRole.vet
              ? _clinicCtrl.text.trim()
              : null,
          licenseNo: widget.role == UserRole.vet ? _licCtrl.text.trim() : null,
        );
        await _db.saveUser(user);
        _navigate(user);
      }
    } on FirebaseAuthException catch (e) {
      _showErr(_authErr(e.code));
    } catch (e) {
      _showErr(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigate(AppUser user) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            user.isVet ? VetMainScreen(user: user) : UserMainScreen(user: user),
      ),
      (_) => false,
    );
  }

  void _showErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _authErr(String code) => switch (code) {
    'user-not-found' => 'Bu e-posta kayıtlı değil.',
    'wrong-password' => 'Hatalı şifre.',
    'email-already-in-use' => 'Bu e-posta zaten kullanımda.',
    'weak-password' => 'Şifre en az 6 karakter olmalı.',
    'invalid-email' => 'Geçersiz e-posta.',
    _ => 'Bir hata oluştu. Tekrar deneyin.',
  };

  @override
  Widget build(BuildContext context) {
    final isVet = widget.role == UserRole.vet;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLogin ? 'Giriş Yap' : 'Hesap Oluştur',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 20),

                if (!_isLogin) ...[
                  _field(
                    _nameCtrl,
                    'Ad Soyad',
                    Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _phoneCtrl,
                    'Telefon',
                    Icons.phone_outlined,
                    type: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                  ),
                  const SizedBox(height: 12),
                  if (isVet) ...[
                    _field(
                      _clinicCtrl,
                      'Klinik Adı',
                      Icons.local_hospital_outlined,
                    ),
                    const SizedBox(height: 12),
                    _field(_licCtrl, 'Lisans No', Icons.badge_outlined),
                    const SizedBox(height: 12),
                  ],
                ],

                _field(
                  _emailCtrl,
                  'E-posta',
                  Icons.email_outlined,
                  type: TextInputType.emailAddress,
                  validator: (v) {
                    if (v!.isEmpty) return 'Gerekli';
                    if (!v.contains('@')) return 'Geçerli e-posta girin';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: !_showPass,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPass ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return 'Gerekli';
                    if (!_isLogin && v.length < 6) return 'Min 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primary,
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
                ),
                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? 'Hesabın yok mu? Kayıt ol'
                          : 'Zaten hesabın var mı? Giriş yap',
                      style: TextStyle(color: widget.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? type,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: c,
    keyboardType: type,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    validator: validator,
  );
}
