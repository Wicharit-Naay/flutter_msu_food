import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  bool _busy = false;
  Future<void> _signIn() async {
    setState(() => _busy = true);
    final error = await _auth.signInWithGoogle();
    // mounted ตรวจว่าหน้าจอยังอยู่หรือไม่
    // ป้องกันการเรียก setState หลังจากหน้าจอถูกปิดไปแล้ว
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/food_delivery.jpg',
                width: 84,
                height: 84,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              const Text(
                'MSU Food',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'สั่งอาหารในมหาวิทยาลัย',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _busy
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton.icon(
                        onPressed: _signIn,
                        icon: const Icon(Icons.login),
                        label: const Text('เข้าสู่ระบบด้วยบัญชี Google'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
