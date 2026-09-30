import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/food_order.dart';
import '../../services/db.dart';
import 'order_track_screen.dart';

/// ประวัติออร์เดอร์ทั้งหมดของลูกค้าคนนี้
///
/// รายการทั้งหน้าอัปเดตเองเมื่อร้านเปลี่ยนสถานะออร์เดอร์ใดก็ตาม
class MyOrdersScreen extends StatelessWidget {
  final User user;
  const MyOrdersScreen({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    final db = Db();
    final fmt = DateFormat('d/M/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('ออร์เดอร์ของฉัน')),
      body: StreamBuilder<List<FoodOrder>>(
        stream: db.watchMyOrders(user.uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('ผิดพลาด: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snap.data!;
          if (orders.isEmpty) {
            return const Center(child: Text('ยังไม่มีประวัติการสั่งซื้อ'));
          }
          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final o = orders[i];
              // createdAt อาจเป็น null ชั่วครู่ตอนที่ยังออฟไลน์
              // เพราะ serverTimestamp() จะได้ค่าจริงเมื่อถึงเซิร์ฟเวอร์
              final when = o.createdAt == null
                  ? 'กำำลังส่งข้อมูล...'
                  : fmt.format(o.createdAt!);
              return ListTile(
                title: Text(o.shopName),
                subtitle: Text('$when · ${OrderStatus.labels[o.status] ?? ''}'),
                trailing: Text('${o.total} บาท'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderTrackScreen(orderId: o.id),
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
