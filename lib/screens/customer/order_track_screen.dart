import 'package:flutter/material.dart';
import '../../models/food_order.dart';
import '../../services/db.dart';

/// หน้าติดตามสถานะคำำสั่งซื้อ
///
/// ใช้การฟัง "เอกสารเดียว" ซึ่งประหยัดโควตาที่สุด
/// เพราะจะนับการอ่านเพิ่มก็ต่อเมื่อเอกสารใบนั้นเปลี่ยนแปลงจริง
///
/// เมื่อร้านกดเปลี่ยนสถานะบนอีกเครื่อง StreamBuilder จะได้รับค่าใหม่
/// แล้วเรียก builder ให้เองโดยอัตโนมัติ จึงไม่ต้องเรียก setState() เลย
class OrderTrackScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackScreen({super.key, required this.orderId});
  @override
  Widget build(BuildContext context) {
    final db = Db();
    return Scaffold(
      appBar: AppBar(title: const Text('ติดตามคำสั่งซื้อ')),
      body: StreamBuilder<FoodOrder>(
        stream: db.watchOrder(orderId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('ผิดพลาด: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = snap.data!;
          final steps = OrderStatus.flow;
          final currentIndex = steps.indexOf(order.status);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                order.shopName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // รายการอาหารที่สั่ง
              ...order.items.map(
                (e) => Text('${e.name} x${e.qty} ${e.subtotal} บาท'),
              ),
              const SizedBox(height: 6),
              Text(
                'ยอดรวม ${order.total} บาท',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (order.note.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'หมายเหตุ: ${order.note}',
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
              const Divider(height: 32),
              // แสดงความคืบหน้าเป็นลำำดับขั้น
              if (order.status == OrderStatus.cancelled)
                const ListTile(
                  leading: Icon(Icons.cancel, color: Colors.red),
                  title: Text('คำสั่งซื้อถูกยกเลิก'),
                )
              else
                ...List.generate(steps.length, (i) {
                  final passed = i <= currentIndex;
                  return ListTile(
                    leading: Icon(
                      passed
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: passed ? Colors.green : Colors.grey,
                    ),
                    title: Text(
                      OrderStatus.labels[steps[i]] ?? '',
                      style: TextStyle(
                        fontWeight: i == currentIndex
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
              // ลูกค้ายกเลิกได้เฉพาะตอนที่ร้านยังไม่รับ
              if (order.status == OrderStatus.pending)
                OutlinedButton(
                  onPressed: () => db.cancelOrder(order.id),
                  child: const Text('ยกเลิกคำสั่งซื้อ'),
                ),
              // เมื่ออาหารพร้อม ลูกค้ากดยืนยันว่ารับแล้ว
              if (order.status == OrderStatus.ready)
                FilledButton(
                  onPressed: () => db.advanceStatus(order.id, order.status),
                  child: const Text('ได้รับอาหารแล้ว'),
                ),
            ],
          );
        },
      ),
    );
  }
}
