import 'package:flutter/material.dart';
import '../../models/shop.dart';
import '../../services/db.dart';

const _defaultMembers = [
  {'name': 'นางสาวเพ็ญนภา เรืองชม', 'studentId': '66010914080'},
  {'name': 'นางสาวปภัสสร อุณวงค์', 'studentId': '66010914097'},
  {'name': 'นางสาวกุลปริยา แก้วตา', 'studentId': '66010914101'},
  {'name': 'นางสาวธิดารัตน์ บุญสุภา', 'studentId': '66010914074'},
  {'name': 'นายวิชาฤทธิ์ ร้อยคำลือ', 'studentId': '66010914115'},
  {'name': 'นางสาวอนุสรา แสนขรยาง', 'studentId': '66010914119'},
  {'name': 'นางสาวอริศรา พวงมาลัย', 'studentId': '66010914120'},
];

class ShopProfileScreen extends StatefulWidget {
  final String shopId;
  const ShopProfileScreen({super.key, required this.shopId});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  late final Db _db = Db();
  bool _initializingMembers = true;

  @override
  void initState() {
    super.initState();
    _initializeMembers();
  }

  Future<void> _initializeMembers() async {
    try {
      await _db.ensureDefaultShopMembers(widget.shopId, _defaultMembers);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เตรียมรายชื่อสมาชิกไม่สำเร็จ: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _initializingMembers = false);
    }
  }

  Future<void> _addMember(BuildContext context, Db db) async {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final member = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('เพิ่มสมาชิก'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'กรอกชื่อสมาชิก'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: idController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'รหัสประจำตัว'),
                validator: (value) {
                  final studentId = value?.trim() ?? '';
                  if (studentId.isEmpty) return 'กรอกรหัสประจำตัว';
                  if (_defaultMembers.any(
                    (member) => member['studentId'] == studentId,
                  )) {
                    return 'รหัสนี้อยู่ในรายชื่อแล้ว';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, {
                'name': nameController.text.trim(),
                'studentId': idController.text.trim(),
              });
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
    nameController.dispose();
    idController.dispose();
    if (member == null) return;

    try {
      await db.addShopMember(
        widget.shopId,
        name: member['name']!,
        studentId: member['studentId']!,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  Future<void> _deleteMember(
    BuildContext context,
    Db db,
    Map<String, dynamic> member,
  ) async {
    final name = member['name'] as String? ?? 'สมาชิก';
    final studentId = member['studentId'] as String? ?? '';
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการลบสมาชิก'),
        content: Text('ต้องการลบ $name ($studentId) หรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ลบสมาชิก'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    try {
      await db.deleteShopMember(widget.shopId, studentId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ลบสมาชิกไม่สำเร็จ: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ร้าน')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMember(context, _db),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('เพิ่มสมาชิก'),
      ),
      body: StreamBuilder<Shop>(
        stream: _db.watchShop(widget.shopId),
        builder: (context, shopSnapshot) {
          if (shopSnapshot.hasError) {
            return Center(child: Text('ผิดพลาด: ${shopSnapshot.error}'));
          }
          if (!shopSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _db.watchShopMembers(widget.shopId),
            builder: (context, membersSnapshot) {
              if (membersSnapshot.hasError) {
                return Center(child: Text('ผิดพลาด: ${membersSnapshot.error}'));
              }
              if (!membersSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_initializingMembers) {
                return const Center(child: CircularProgressIndicator());
              }

              final members = [...membersSnapshot.data!]
                ..sort(
                  (a, b) => (a['name'] as String? ?? '').compareTo(
                    b['name'] as String? ?? '',
                  ),
                );

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  Text(
                    shopSnapshot.data!.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('รหัสร้าน: ${shopSnapshot.data!.id}'),
                  Text(
                    shopSnapshot.data!.isOpen
                        ? 'สถานะ: เปิดร้าน'
                        : 'สถานะ: ปิดร้าน',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'สมาชิก (${members.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  ...members.map((member) {
                    final name = member['name'] as String? ?? '';
                    final studentId = member['studentId'] as String? ?? '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(name.isEmpty ? 'ไม่ระบุชื่อ' : name),
                      subtitle: Text('รหัสประจำตัว: $studentId'),
                      trailing: IconButton(
                        tooltip: 'ลบสมาชิก',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteMember(context, _db, member),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
