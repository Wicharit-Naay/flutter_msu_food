import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/food_order.dart';
import '../../models/menu_item.dart';
import '../../models/shop.dart';
import '../../services/db.dart';
import 'order_track_screen.dart';
import '../../widgets/menu_image.dart';

/// หน้าเมนูและตะกร้าของลูกค้า
///
/// ฟังสองกระแสข้อมูลพร้อมกัน
/// กระแสที่ 1 : เอกสารร้าน -> ดูว่ายังเปิดอยู่หรือไม่
/// กระแสที่ 2 : รายการเมนู -> ดูว่าเมนูใดของหมด
/// เมื่อร้านปิดสวิตช์หรือกดเมนูของหมดบนอีกเครื่อง
/// หน้าจอนี้จะเปลี่ยนทันทีทั้งที่ลูกค้าไม่ได้ทำำอะไรเลย
class MenuScreen extends StatefulWidget {
  final Shop shop;
  final User user;
  const MenuScreen({super.key, required this.shop, required this.user});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _db = Db();
  final _noteCtrl = TextEditingController();

  /// ตะกร้าเก็บไว้ในหน่วยความจำำของหน้าจอเท่านั้น
  /// ยังไม่บันทึกลงฐานข้อมูลจนกว่าจะกดยืนยันสั่งซื้อ
  /// key = รหัสเมนู, value = จำำนวน
  final Map<String, int> _cart = {};

  /// เก็บข้อมูลเมนูล่าสุดไว้ใช้ตอนสร้างออร์เดอร์
  List<MenuItem> _menu = [];
  bool _placing = false;
  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  num get _total {
    num sum = 0;
    for (final m in _menu) {
      final qty = _cart[m.id] ?? 0;
      sum += m.price * qty;
    }
    return sum;
  }

  Future<void> _placeOrder() async {
    // แปลงตะกร้าให้เป็นรายการอาหารของออร์เดอร์
    final items = <OrderItem>[];
    for (final m in _menu) {
      final qty = _cart[m.id] ?? 0;
      if (qty > 0) {
        items.add(OrderItem(name: m.name, price: m.price, qty: qty));
      }
    }
    if (items.isEmpty) return;
    setState(() => _placing = true);
    try {
      final orderId = await _db.placeOrder(
        shop: widget.shop,
        customerId: widget.user.uid,
        customerName: widget.user.displayName ?? 'ลูกค้า',
        items: items,
        note: _noteCtrl.text,
      );
      if (!mounted) return;
      // แทนที่หน้านี้ด้วยหน้าติดตามสถานะ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackScreen(orderId: orderId)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('สั่งซื้อไม่สำเร็จ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shop.name)),
      // กระแสที่ 1 เฝ้าฟังสถานะร้าน
      body: StreamBuilder<Shop>(
        stream: _db.watchShop(widget.shop.id),
        builder: (context, shopSnap) {
          final isOpen = shopSnap.data?.isOpen ?? false;
          return Column(
            children: [
              if (!isOpen)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    'ขณะนี้ร้านปิดอยู่ ยังสั่งอาหารไม่ได้',
                    textAlign: TextAlign.center,
                  ),
                ),
              // กระแสที่ 2 เฝ้าฟังรายการเมนู
              Expanded(
                child: StreamBuilder<List<MenuItem>>(
                  stream: _db.watchMenu(widget.shop.id),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text('ผิดพลาด: ${snap.error}'));
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    _menu = snap.data!;
                    if (_menu.isEmpty) {
                      return const Center(child: Text('ร้านนี้ยังไม่มีเมนู'));
                    }
                    return ListView.builder(
                      itemCount: _menu.length,
                      itemBuilder: (context, i) {
                        final m = _menu[i];
                        final qty = _cart[m.id] ?? 0;
                        // เมนูที่ของหมดหรือร้านปิดจะกดเพิ่มไม่ได้
                        final canOrder = isOpen && m.available;
                        return ListTile(
                          leading: MenuImage(
                            bytes: m.imageBytes,
                          ), // เพิ่มบรรทัดนี้
                          title: Text(m.name),
                          subtitle: Text(
                            m.available ? '${m.price} บาท' : 'ของหมดแล้ว',
                            style: TextStyle(
                              color: m.available ? null : Colors.red,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: qty == 0
                                    ? null
                                    : () => setState(() {
                                        if (qty - 1 == 0) {
                                          _cart.remove(m.id);
                                        } else {
                                          _cart[m.id] = qty - 1;
                                        }
                                      }),
                              ),
                              Text('$qty'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: !canOrder
                                    ? null
                                    : () =>
                                          setState(() => _cart[m.id] = qty + 1),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // ---------- แถบสรุปและปุ่มสั่งซื้อ ----------
              if (_cart.isNotEmpty)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          controller: _noteCtrl,
                          decoration: const InputDecoration(
                            labelText: 'หมายเหตุถึงร้าน (ไม่บังคับ)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: (!isOpen || _placing)
                                ? null
                                : _placeOrder,
                            child: _placing
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text('ยืนยันสั่งซื้อ รวม $_total บาท'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
