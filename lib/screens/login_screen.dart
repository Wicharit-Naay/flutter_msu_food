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

  // ==========================================================================
  // Google Sign In
  // ==========================================================================

  Future<void> _signIn() async {
    setState(() => _busy = true);

    // ใช้ Auth Logic เดิม
    final error = await _auth.signInWithGoogle();

    // ป้องกัน setState หลังจากหน้าจอถูกปิด
    if (!mounted) return;

    setState(() => _busy = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),

      body: SafeArea(
        child: Stack(
          children: [
            // =================================================================
            // Background Decoration
            // =================================================================

            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF6B35).withOpacity(0.08),
                ),
              ),
            ),

            Positioned(
              top: 130,
              left: -90,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFA27E).withOpacity(0.07),
                ),
              ),
            ),

            // =================================================================
            // Main Content
            // =================================================================

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 440,
                  ),
                  child: Column(
                    children: [
                      // =======================================================
                      // Hero Image
                      // =======================================================

                      Container(
                        width: double.infinity,
                        height: 260,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/food_delivery.jpg',
                                fit: BoxFit.cover,
                              ),

                              // Gradient เพื่อให้ภาพดูนุ่มขึ้น
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.12),
                                    ],
                                  ),
                                ),
                              ),

                              // Badge
                              Positioned(
                                top: 18,
                                left: 18,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.92),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.restaurant_rounded,
                                        size: 15,
                                        color: Color(0xFFFF6B35),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'MSU Food',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1D1D1F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 34),

                      // =======================================================
                      // Logo Icon
                      // =======================================================

                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF6B35),
                              Color(0xFFFF8A5B),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35)
                                  .withOpacity(0.22),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fastfood_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // =======================================================
                      // App Name
                      // =======================================================

                      const Text(
                        'MSU Food',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'สั่งอาหารง่าย ๆ ภายในมหาวิทยาลัย',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6E6E73),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'เลือกร้าน เลือกเมนู และติดตามออร์เดอร์ได้ในแอปเดียว',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA0A0A5),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 34),

                      // =======================================================
                      // Login Card
                      // =======================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFEAEAEC),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.025),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'เข้าสู่ระบบ',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1D1D1F),
                              ),
                            ),

                            const SizedBox(height: 5),

                            const Text(
                              'ใช้บัญชี Google เพื่อเข้าใช้งาน MSU Food',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8E8E93),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // =================================================
                            // Google Sign-In Button
                            // =================================================

                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: _busy
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF2EB),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 21,
                                            height: 21,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Color(0xFFFF6B35),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'กำลังเข้าสู่ระบบ...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFFF6B35),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : FilledButton(
                                      onPressed: _signIn,
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFF6B35),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _GoogleIcon(),
                                          SizedBox(width: 12),
                                          Text(
                                            'เข้าสู่ระบบด้วย Google',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),

                            const SizedBox(height: 16),

                            const Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFEEEEF0),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    'ปลอดภัยด้วย Google',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFA0A0A5),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFEEEEF0),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 15,
                                  color: Color(0xFF9A9A9F),
                                ),
                                SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    'ระบบจะใช้บัญชี Google สำหรับยืนยันตัวตนในการเข้าใช้งาน',
                                    style: TextStyle(
                                      fontSize: 10,
                                      height: 1.5,
                                      color: Color(0xFF9A9A9F),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // =======================================================
                      // Footer
                      // =======================================================

                      const Text(
                        'MSU Food • University Food Ordering',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFB0B0B5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Google Icon
// ============================================================================

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}