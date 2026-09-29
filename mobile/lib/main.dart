import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/user/user_main_screen.dart';
import 'screens/vet/vet_main_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('tr', null);
  runApp(const VetApp());
}

class VetApp extends StatelessWidget {
  const VetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VetDoğum',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.user(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return _RoleRouter(uid: snapshot.data!.uid);
          }

          return const AuthScreen();
        },
      ),
    );
  }
}

// Kullanıcı rolüne göre
class _RoleRouter extends StatelessWidget {
  final String uid;
  const _RoleRouter({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirestoreService().getUser(uid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) return const AuthScreen();
        return user.isVet
            ? VetMainScreen(user: user)
            : UserMainScreen(user: user);
      },
    );
  }
}
