import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/menu_item.dart';
import '../../services/db.dart';
import '../../services/image_service.dart';
import '../../widgets/menu_image.dart';

/// หน้าจอจัดการเมนูของร้าน
///
/// C : เพิ่มเมนูใหม่
/// R : อ่านรายการเมนูแบบ Real-time
/// U : แก้ไขเมนู / เปิด-ปิดการขาย
/// D : ลบเมนู
class MenuManageScreen extends StatelessWidget {
  final String shopId;

  const MenuManageScreen({
    super.key,
    required this.shopId,
  });

  // ==========================================================================
  // เพิ่ม / แก้ไขเมนู
  // ==========================================================================

  Future<void> _openForm(
    BuildContext context,
    Db db,
    MenuItem? item,
  ) async {
    final nameCtrl = TextEditingController(
      text: item?.name ?? '',
    );

    final priceCtrl = TextEditingController(
      text: item == null ? '' : '${item.price}',
    );

    final imageService = ImageService();

    // สถานะของรูปภายในฟอร์ม
    String? newImage; // Base64 ของรูปที่เพิ่งเลือก
    bool removeImage = false; // ผู้ใช้กดลบรูปเดิม
    bool saving = false; // กำลังบันทึก ใช้กันกดซ้ำ

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // ลำดับการเลือกรูปตัวอย่าง
          // รูปใหม่ > รูปเดิม > ไม่มีรูป
          final preview = newImage != null
              ? ImageService.decode(newImage)
              : (removeImage ? null : item?.imageBytes);

          // ==================================================================
          // เลือกรูปจากกล้อง / คลังภาพ
          // ==================================================================

          Future<void> pick(ImageSource source) async {
            try {
              final b64 = await imageService.pickAsBase64(source);

              if (b64 == null || !ctx.mounted) {
                return;
              }

              setDialogState(() {
                newImage = b64;
                removeImage = false;
              });
            } catch (e) {
              if (!ctx.mounted) return;

              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(
                    e.toString().replaceFirst(
                      'Exception: ',
                      '',
                    ),
                  ),
                ),
              );
            }
          }

          return AlertDialog(
            title: Text(
              item == null
                  ? 'เพิ่มเมนูใหม่'
                  : 'แก้ไขเมนู',
            ),

            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ==========================================================
                  // รูปเมนู
                  // ==========================================================

                  MenuImage(
                    bytes: preview,
                    size: 120,
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      // ถ่ายรูป
                      IconButton.filledTonal(
                        tooltip: 'ถ่ายรูป',
                        icon: const Icon(
                          Icons.photo_camera,
                        ),
                        onPressed: saving
                            ? null
                            : () => pick(
                                  ImageSource.camera,
                                ),
                      ),

                      // เลือกจากคลังภาพ
                      IconButton.filledTonal(
                        tooltip: 'เลือกจากคลังภาพ',
                        icon: const Icon(
                          Icons.photo_library,
                        ),
                        onPressed: saving
                            ? null
                            : () => pick(
                                  ImageSource.gallery,
                                ),
                      ),

                      // ลบรูป
                      if (preview != null)
                        IconButton(
                          tooltip: 'ลบรูป',
                          icon: const Icon(
                            Icons.delete_outline,
                          ),
                          onPressed: saving
                              ? null
                              : () {
                                  setDialogState(() {
                                    newImage = null;
                                    removeImage = true;
                                  });
                                },
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ==========================================================
                  // ชื่อเมนู
                  // ==========================================================

                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อเมนู',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==========================================================
                  // ราคา
                  // ==========================================================

                  TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'ราคา (บาท)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            actions: [
              // ==============================================================
              // ยกเลิก
              // ==============================================================

              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.pop(ctx),
                child: const Text('ยกเลิก'),
              ),

              // ==============================================================
              // บันทึก
              // ==============================================================

              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();

                        final price = num.tryParse(
                          priceCtrl.text.trim(),
                        );

                        if (name.isEmpty || price == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'กรุณากรอกชื่อเมนูและราคาให้ถูกต้อง',
                              ),
                            ),
                          );
                          return;
                        }

                        setDialogState(
                          () => saving = true,
                        );

                        try {
                          // CREATE
                          if (item == null) {
                            await db.addMenuItem(
                              shopId,
                              name,
                              price,
                              imageBase64: newImage,
                            );
                          }

                          // UPDATE
                          else {
                            await db.updateMenuItem(
                              item.id,
                              name,
                              price,
                              imageBase64: newImage,
                              removeImage: removeImage,
                            );
                          }

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                        } catch (e) {
                          if (!ctx.mounted) return;

                          setDialogState(
                            () => saving = false,
                          );

                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                'บันทึกไม่สำเร็จ: $e',
                              ),
                            ),
                          );
                        }
                      },

                // Loading ขณะบันทึก
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
    priceCtrl.dispose();
  }

  // ==========================================================================
  // ยืนยันการลบ
  // ==========================================================================

  Future<void> _confirmDelete(
    BuildContext context,
    Db db,
    MenuItem item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 30,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'ลบเมนูนี้?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'คุณต้องการลบ "${item.name}" ออกจากรายการเมนูหรือไม่',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF6E6E73),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx, false);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF636366),
                            side: const BorderSide(
                              color: Color(0xFFE0E0E2),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('ยกเลิก'),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx, true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'ลบเมนู',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (ok == true) {
      // DELETE — ใช้ Logic เดิม
      await db.deleteMenuItem(item.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ลบ "${item.name}" แล้ว',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ==========================================================================
  // Main UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final db = Db();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      // ======================================================================
      // AppBar
      // ======================================================================

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF1D1D1F),
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'จัดการเมนู',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'เพิ่ม แก้ไข และจัดการสถานะการขาย',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),

      // ======================================================================
      // Floating Add Button
      // ======================================================================

      floatingActionButton: FloatingActionButton.extended(
        elevation: 2,
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        onPressed: () {
          _openForm(
            context,
            db,
            null,
          );
        },
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'เพิ่มเมนู',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ======================================================================
      // Menu Stream
      // ======================================================================

      body: StreamBuilder<List<MenuItem>>(
        // READ — ใช้ฐานข้อมูลเดิม
        stream: db.watchMenu(shopId),
        builder: (context, snap) {
          if (snap.hasError) {
            return _ErrorState(
              message: '${snap.error}',
            );
          }

          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final items = snap.data!;

          if (items.isEmpty) {
            return _EmptyMenuState(
              onAddPressed: () {
                _openForm(
                  context,
                  db,
                  null,
                );
              },
            );
          }

          final availableCount = items
              .where(
                (item) => item.available,
              )
              .length;

          return Column(
            children: [
              // ===============================================================
              // Summary
              // ===============================================================

              _MenuSummary(
                total: items.length,
                available: availableCount,
              ),

              // ===============================================================
              // Menu List
              // ===============================================================

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    100,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final menu = items[index];

                    return _MenuCard(
                      menu: menu,

                      // UPDATE
                      onTap: () {
                        _openForm(
                          context,
                          db,
                          menu,
                        );
                      },

                      // UPDATE available
                      onAvailableChanged: (value) {
                        db.setAvailable(
                          menu.id,
                          value,
                        );
                      },

                      // DELETE
                      onDelete: () {
                        _confirmDelete(
                          context,
                          db,
                          menu,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// Summary
// ============================================================================

class _MenuSummary extends StatelessWidget {
  final int total;
  final int available;

  const _MenuSummary({
    required this.total,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    final unavailable = total - available;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        18,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              icon: Icons.restaurant_menu_rounded,
              title: '$total',
              subtitle: 'เมนูทั้งหมด',
              backgroundColor: const Color(0xFFFFF2EB),
              foregroundColor: const Color(0xFFFF6B35),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: _SummaryItem(
              icon: Icons.check_circle_outline_rounded,
              title: '$available',
              subtitle: 'กำลังขาย',
              backgroundColor: const Color(0xFFECFDF3),
              foregroundColor: const Color(0xFF16A34A),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: _SummaryItem(
              icon: Icons.pause_circle_outline_rounded,
              title: '$unavailable',
              subtitle: 'ปิดขาย',
              backgroundColor: const Color(0xFFF3F4F6),
              foregroundColor: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Summary Item
// ============================================================================

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color foregroundColor;

  const _SummaryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 21,
            color: foregroundColor,
          ),

          const SizedBox(height: 6),

          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w800,
              color: foregroundColor,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6E6E73),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Menu Card
// ============================================================================

class _MenuCard extends StatelessWidget {
  final MenuItem menu;
  final VoidCallback onTap;
  final ValueChanged<bool> onAvailableChanged;
  final VoidCallback onDelete;

  const _MenuCard({
    required this.menu,
    required this.onTap,
    required this.onAvailableChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = menu.available;

    return Container(
      margin: const EdgeInsets.only(
        top: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEAEAEC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ============================================================
                // รูปเมนู
                // ============================================================

                MenuImage(
                  bytes: menu.imageBytes,
                  size: 54,
                ),

                const SizedBox(width: 14),

                // ============================================================
                // Information
                // ============================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isAvailable
                              ? const Color(0xFF1D1D1F)
                              : const Color(0xFF8E8E93),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Text(
                            '${menu.price}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF6B35),
                            ),
                          ),

                          const SizedBox(width: 4),

                          const Text(
                            'บาท',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF9CA3AF),
                              shape: BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Text(
                            isAvailable
                                ? 'กำลังเปิดขาย'
                                : 'ปิดการขาย',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isAvailable
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // ============================================================
                // Actions
                // ============================================================

                Column(
                  children: [
                    Switch.adaptive(
                      value: isAvailable,
                      activeColor: const Color(0xFFFF6B35),

                      // ใช้ DB method เดิม
                      onChanged: onAvailableChanged,
                    ),

                    IconButton(
                      tooltip: 'ลบเมนู',
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 21,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Empty State
// ============================================================================

class _EmptyMenuState extends StatelessWidget {
  final VoidCallback onAddPressed;

  const _EmptyMenuState({
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF2EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: Color(0xFFFF6B35),
                size: 52,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'ยังไม่มีเมนู',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'เพิ่มรายการอาหารของร้าน\nเพื่อให้ลูกค้าเริ่มสั่งอาหารได้',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Color(0xFF8E8E93),
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'เพิ่มเมนูแรก',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Error State
// ============================================================================

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'ไม่สามารถโหลดเมนูได้',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}