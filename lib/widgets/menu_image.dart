import 'dart:typed_data';
import 'package:flutter/material.dart';

class MenuImage extends StatelessWidget {
  final Uint8List? bytes; // ไบต์ของรูป (null = ไม่มีรูป)
  final double size; // ความกว้างและความสูงของกรอบ
  const MenuImage({super.key, required this.bytes, this.size = 56});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8), // มุมโค้ง
      child: SizedBox(
        width: size,
        height: size,
        child: bytes == null
            ? Container(
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.restaurant,
                  color: Colors.grey.shade500,
                  size: size * 0.5,
                ),
              )
            : Image.memory(
                bytes!,
                fit: BoxFit.cover,
                // ไม่ให้รูปกะพริบเมื่อ StreamBuilder สร้างหน้าจอใหม่
                gaplessPlayback: true,
                // ถอดรหัสรูปตามขนาดที่แสดงจริง ประหยัดหน่วยความจำำ
                cacheWidth: (size * 3).round(),
              ),
      ),
    );
  }
}
