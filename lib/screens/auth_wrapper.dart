import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading while checking authentication
        if (authProvider.isLoading && authProvider.user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Show home screen if authenticated
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }
        
        // Show login screen if not authenticated
        return const LoginScreen();
      },
    );
  }
}