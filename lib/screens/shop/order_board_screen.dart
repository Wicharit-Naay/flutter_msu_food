import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/shop.dart';
import '../../models/food_order.dart';
import '../../services/auth_service.dart';
import '../../services/db.dart';
import 'order_history_screen.dart';
import 'shop_profile_screen.dart';
import 'menu_manage_screen.dart';

class OrderBoardScreen extends StatelessWidget {
  final User user;
  final String shopId;
  const OrderBoardScreen({super.key, required this.user, required this.shopId});
  @override
  Widget build(BuildContext context) {
    final db = Db();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ออร์เดอร์เข้าใหม่'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'ประวัติออร์เดอร์',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderHistoryScreen(shopId: shopId),
              ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.person_outline),
            label: const Text('โปรไฟล์'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShopProfileScreen(shopId: shopId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'จัดการเมนู',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MenuManageScreen(shopId: shopId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ---------- สวิตช์เปิดปิดร้าน ----------
          // ฟังเอกสารร้านเดียว เพื่อให้สวิตช์ตรงกับค่าจริงเสมอ
          StreamBuilder<Shop>(
            stream: db.watchShop(shopId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const LinearProgressIndicator();
              }
              final shop = snap.data!;
              return SwitchListTile(
                title: Text(
                  shop.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  shop.isOpen
                      ? 'ร้านเปิดอยู่ ลูกค้าสั่งได้'
                      : 'ร้านปิดอยู่ ลูกค้าสั่งไม่ได้',
                ),
                value: shop.isOpen,
                onChanged: (v) => db.setShopOpen(shopId, v),
              );
            },
          ),
          const Divider(height: 1),
          // ---------- รายการออร์เดอร์ ----------
          Expanded(
            child: StreamBuilder<List<FoodOrder>>(
              stream: db.watchShopOrders(shopId),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('ผิดพลาด: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snap.data!;
                if (orders.isEmpty) {
                  return const Center(child: Text('ยังไม่มีออร์เดอร์เข้ามา'));
                }
                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, i) =>
                      _OrderCard(order: orders[i], db: db),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final FoodOrder order;
  final Db db;
  const _OrderCard({required this.order, required this.db});
  Future<void> _onAction(BuildContext context) async {
    // ถ้ายังเป็น pending ให้ใช้ธุรกรรมเพื่อกันการกดซ้ำ้ำ
    if (order.status == OrderStatus.pending) {
      final error = await db.acceptOrder(order.id);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    // สถานะอื่นเลื่อนไปข้างหน้าตามลำำดับได้เลย
    await db.advanceStatus(order.id, order.status);
  }

  @override
  Widget build(BuildContext context) {
    final action = OrderStatus.actionLabel(order.status);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  label: Text(OrderStatus.labels[order.status] ?? ''),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            // รายการอาหารในออร์เดอร์
            ...order.items.map(
              (e) => Text('${e.name} x${e.qty} ${e.subtotal} บาท'),
            ),
            if (order.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'หมายเหตุ: ${order.note}',
                style: const TextStyle(color: Colors.orange),
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รวม ${order.total} บาท',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (order.status == OrderStatus.pending)
                      TextButton(
                        onPressed: () => db.cancelOrder(order.id),
                        child: const Text('ปฏิเสธ'),
                      ),
                    if (action != null)
                      FilledButton(
                        onPressed: () => _onAction(context),
                        child: Text(action),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
