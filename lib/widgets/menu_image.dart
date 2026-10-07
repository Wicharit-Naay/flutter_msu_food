import 'dart:typed_data';
import 'package:flutter/material.dart';

class MenuImage extends StatelessWidget {
  final Uint8List? bytes;
  final double size;

  const MenuImage({
    super.key,
    required this.bytes,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: bytes == null || bytes!.isEmpty
            ? _placeholder()
            : Image.memory(
                bytes!,
                width: size,
                height: size,
                fit: BoxFit.cover,

                // ลดการกระพริบตอน Stream rebuild
                gaplessPlayback: true,

                // ลดหน่วยความจำตอน decode
                cacheWidth: (size * 3).round(),

                // ถ้ารูปเสีย ให้แสดง placeholder แทน
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return _placeholder();
                },
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_rounded,
        color: Colors.grey.shade500,
        size: size * 0.5,
      ),
    );
  }
}