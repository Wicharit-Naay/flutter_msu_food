import 'package:cloud_firestore/cloud_firestore.dart';

// ---------- ตรรกะของวงจรสถานะ ----------
class OrderStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const cooking = 'cooking';
  static const ready = 'ready';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
  // ลำำดับสถานะปกติ ใช้หาสถานะถัดไป
  static const flow = [pending, accepted, cooking, ready, completed];
  static const labels = {
    pending: 'รอร้านรับออร์เดอร์',
    accepted: 'ร้านรับออร์เดอร์แล้ว',
    cooking: 'กำำลังปรุงอาหาร',
    ready: 'พร้อมรับที่ร้าน',
    completed: 'รับอาหารเรียบร้อย',
    cancelled: 'ยกเลิกแล้ว',
  };
  // สถานะที่ถือว่ายังทำำงานอยู่ ใช้กรองบนจอของร้าน
  static const active = [pending, accepted, cooking, ready];
  // คืนสถานะถัดไป ถ้าไม่มีแล้วจะคืน null
  static String? next(String current) {
    final i = flow.indexOf(current);
    if (i < 0 || i >= flow.length - 1) return null;
    return flow[i + 1];
  }

  // ข้อความบนปุ่มของฝั่งร้าน
  static String? actionLabel(String current) {
    switch (current) {
      case pending:
        return 'รับออร์เดอร์';
      case accepted:
        return 'เริ่มปรุงอาหาร';
      case cooking:
        return 'ปรุงเสร็จแล้ว';
      default:
        return null; // ready ให้ลูกค้าเป็นผู้กดยืนยัน
    }
  }
}

// ---------- รายการอาหารหนึ่งบรรทัดในออร์เดอร์ ----------
class OrderItem {
  final String name;
  final num price;
  final int qty;
  OrderItem({required this.name, required this.price, required this.qty});
  num get subtotal => price * qty;
  Map<String, dynamic> toMap() => {'name': name, 'price': price, 'qty': qty};
  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    name: m['name'] as String? ?? '',
    price: m['price'] as num? ?? 0,
    qty: (m['qty'] as num?)?.toInt() ?? 1,
  );
}

// ---------- ออร์เดอร์ ----------
class FoodOrder {
  final String id;
  final String shopId;
  final String shopName;
  final String customerId;
  final String customerName;
  final List<OrderItem> items;
  final num total;
  final String status;
  final String note;
  final DateTime? createdAt;
  FoodOrder({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.total,
    required this.status,
    this.note = '',
    this.createdAt,
  });
  factory FoodOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    // items เก็บเป็นอาร์เรย์ของ Map ต้องแปลงทีละตัว
    final raw = m['items'] as List<dynamic>? ?? [];
    return FoodOrder(
      id: d.id,
      shopId: m['shopId'] as String? ?? '',
      shopName: m['shopName'] as String? ?? '',
      customerId: m['customerId'] as String? ?? '',
      customerName: m['customerName'] as String? ?? '',
      items: raw
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      total: m['total'] as num? ?? 0,
      status: m['status'] as String? ?? OrderStatus.pending,
      note: m['note'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
