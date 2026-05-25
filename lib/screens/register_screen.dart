import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
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

                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu', border: OutlineInputBorder()),
                  obscureText: true,
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: auth.isLoading ? null : () async {
                    if (passwordController.text != confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mật khẩu không khớp')),
                      );
                      return;
                    }
                    final success = await auth.register(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim()
                    );
                    if (success && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: auth.isLoading ? const CircularProgressIndicator() : const Text('Đăng ký'),
                ),

                const SizedBox(height: 16),

                if (auth.errorMessage != null)
                  Text(
                    auth.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            );
          }
        )
      )
    );
  }
}