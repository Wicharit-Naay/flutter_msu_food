import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  // เรียกครั้งเดียวตอนเปิดแอป ก่อนเรียก authenticate() เสมอ
  // serverClientId คือ Web client ID ที่คัดลอกมาในข้อ 3.6
  static Future<void> init(String serverClientId) async {
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
  }

  // กระแสข้อมูลสถานะผู้ใช้ ใช้กับ AuthGate
  Stream<User?> get userChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  // คืน null เมื่อสำำเร็จ คืนข้อความเมื่อเกิดข้อผิดพลาด
  Future<String?> signInWithGoogle() async {
    try {
      // ขั้นที่ 1 เปิดหน้าต่างให้ผู้ใช้เลือกบัญชี Google
      final googleUser = await GoogleSignIn.instance.authenticate();
      // ขั้นที่ 2 ดึง idToken ที่ Google ออกให้
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        return 'ไม่ได้รับ idToken ตรวจสอบค่า serverClientId';
      }
      // ขั้นที่ 3 ห่อ idToken เป็น credential ของ Firebase
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      // ขั้นที่ 4 เข้าสู่ระบบ ถ้ายังไม่มีบัญชีจะสร้างให้อัตโนมัติ
      await _auth.signInWithCredential(credential);
      return null;
    } on GoogleSignInException catch (e) {
      // ผู้ใช้กดยกเลิกเอง ไม่ถือเป็นข้อผิดพลาด
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      return 'เข้าสู่ระบบด้วย Google ไม่สำเร็จ (${e.code.name})';
    } on FirebaseAuthException catch (e) {
      return 'Firebase ปฏิเสธการเข้าสู่ระบบ (${e.code})';
    }
  }

  // ต้องออกจากระบบทั้งสองฝั่ง
  // ถ้าออกเฉพาะ Firebase ครั้งต่อไปจะเข้าบัญชีเดิมทันทีโดยไม่ถาม
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
