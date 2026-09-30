import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/db.dart';
import 'customer/shop_list_screen.dart';
import 'shop/order_board_screen.dart';

class RoleGate extends StatelessWidget {
  final User user;
  const RoleGate({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    final db = Db();
    // ฟังเอกสารโปรไฟล์แบบเรียลไทม์
    // ถ้าเลือกบทบาทเสร็จ หน้าจอจะเปลี่ยนเองทันทีโดยไม่ต้องสั่ง
    return StreamBuilder<Map<String, dynamic>?>(
      stream: db.watchProfile(user.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = snap.data;
        // ยังไม่เคยเลือกบทบาท
        if (profile == null) {
          return _ChooseRole(user: user, db: db);
        }
        if (profile['role'] == 'shop') {
          return OrderBoardScreen(
            user: user,
            shopId: profile['shopId'] as String,
          );
        }
        return ShopListScreen(user: user);
      },
    );
  }
}

class _ChooseRole extends StatelessWidget {
  final User user;
  final Db db;
  const _ChooseRole({required this.user, required this.db});
  Future<void> _pickShop(BuildContext context) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ตั้งชื่อร้านของคุณ'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'เช่น ครัวคุณยาย',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('สร้างร้าน'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await db.becomeShop(user.uid, user.displayName ?? '', name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกบทบาทการใช้งาน')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'คุณต้องการใช้งานในบทบาทใด',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 28),
            _RoleCard(
              icon: Icons.person_outline,
              title: 'ลูกค้า',
              detail: 'เลือกร้าน สั่งอาหาร และติดตามสถานะ',
              onTap: () => db.becomeCustomer(user.uid, user.displayName ?? ''),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              icon: Icons.storefront_outlined,
              title: 'ร้านค้า',
              detail: 'จัดการเมนู รับออร์เดอร์ และเปลี่ยนสถานะ',
              onTap: () => _pickShop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 36),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(detail),
        onTap: onTap,
      ),
    );
  }
}
