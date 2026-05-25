import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), 
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder()),
                  obscureText: true,
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: auth.isLoading ? null : () async {
                    final success = await auth.login(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim()
                    );
                    if (success && context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    }
                  },
                  child: auth.isLoading ? const CircularProgressIndicator() : const Text('Đăng nhập'),
                ),

                const SizedBox(height: 16),

                if (auth.errorMessage != null)
                  Text(
                    auth.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                
                const Spacer(),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Chưa có tài khoản? Đăng ký ngay'),
                )
              ],
            );
          }
        ),
      )
    );
  }
}
