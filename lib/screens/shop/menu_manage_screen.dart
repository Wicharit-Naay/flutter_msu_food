import 'package:flutter/material.dart';
import '../../models/menu_item.dart';
import '../../services/db.dart';

/// หน้าจอจัดการเมนูของร้าน — CRUD ครบทั้งสี่การกระทำำ
///
/// C : ปุ่ม + มุมล่างขวา
/// R : StreamBuilder ที่ฟัง watchMenu()
/// U : แตะที่รายการเพื่อแก้ไข และสวิตช์เปิดปิดการขาย
/// D : ปุ่มถังขยะพร้อมกล่องยืนยัน
class MenuManageScreen extends StatelessWidget {
  final String shopId;
  const MenuManageScreen({super.key, required this.shopId});

  /// กล่องโต้ตอบเดียว ใช้ได้ทั้งเพิ่มใหม่และแก้ไขของเดิม
  /// ถ้า item เป็น null คือโหมดเพิ่ม ถ้าไม่ null คือโหมดแก้ไข
  Future<void> _openForm(BuildContext context, Db db, MenuItem? item) async {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final priceCtrl = TextEditingController(
      text: item == null ? '' : '${item.price}',
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'เพิ่มเมนูใหม่' : 'แก้ไขเมนู'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'ชื่อเมนู',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ราคา (บาท)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = num.tryParse(priceCtrl.text.trim());
              if (name.isEmpty || price == null) return;
              if (item == null) {
                await db.addMenuItem(shopId, name, price); // CREATE
              } else {
                await db.updateMenuItem(item.id, name, price); // UPDATE
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Db db,
    MenuItem item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบเมนู "${item.name}" หรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok == true) await db.deleteMenuItem(item.id); // DELETE
  }

  @override
  Widget build(BuildContext context) {
    final db = Db();
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการเมนู')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, db, null),
        child: const Icon(Icons.add),
      ),
      // READ แบบเรียลไทม์
      body: StreamBuilder<List<MenuItem>>(
        stream: db.watchMenu(shopId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('ผิดพลาด: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีเมนู กดปุ่ม + เพื่อเพิ่ม'),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final m = items[i];
              return ListTile(
                title: Text(m.name),
                subtitle: Text('${m.price} บาท'),
                onTap: () => _openForm(context, db, m),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // สวิตช์นี้คือจุดสาธิตเรียลไทม์
                    // กดแล้วหน้าจอลูกค้าจะเปลี่ยนทันที
                    Switch(
                      value: m.available,
                      onChanged: (v) => db.setAvailable(m.id, v),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, db, m),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
