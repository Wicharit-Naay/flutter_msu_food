import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/shop.dart';
import '../../services/auth_service.dart';
import '../../services/db.dart';
import 'menu_screen.dart';
import 'my_orders_screen.dart';

/// หน้าแรกของฝั่งลูกค้า แสดงรายชื่อร้านทั้งหมด
///
/// ป้ายเปิดหรือปิดของแต่ละร้านมาจากฟิลด์ isOpen
/// เมื่อร้านสลับสวิตช์บนอีกเครื่อง ป้ายนี้จะเปลี่ยนเองทันที
class ShopListScreen extends StatelessWidget {
  final User user;
  const ShopListScreen({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    final db = Db();
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกร้านอาหาร'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'ออร์เดอร์ของฉัน',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyOrdersScreen(user: user)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Shop>>(
        stream: db.watchShops(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('ผิดพลาด: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final shops = snap.data!;
          if (shops.isEmpty) {
            return const Center(child: Text('ยังไม่มีร้านค้าในระบบ'));
          }
          return ListView.separated(
            itemCount: shops.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = shops[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: s.isOpen
                      ? Colors.green.shade100
                      : Colors.grey.shade300,
                  child: Icon(
                    Icons.storefront,
                    color: s.isOpen ? Colors.green : Colors.grey,
                  ),
                ),
                title: Text(s.name),
                subtitle: Text(s.isOpen ? 'เปิดอยู่' : 'ปิดอยู่'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuScreen(shop: s, user: user),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
