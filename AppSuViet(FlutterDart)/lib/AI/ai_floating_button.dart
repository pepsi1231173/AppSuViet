import 'package:flutter/material.dart';

class AIFloatingButton extends StatefulWidget {
  final VoidCallback onOpen;

  const AIFloatingButton({super.key, required this.onOpen});

  @override
  State<AIFloatingButton> createState() => _AIFloatingButtonState();
}

class _AIFloatingButtonState extends State<AIFloatingButton> {
  double posX = 20;
  double posY = 300;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: posX,
      top: posY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            posX += details.delta.dx;
            posY += details.delta.dy;
          });
        },
        onTap: widget.onOpen,
        child: Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,

            // 🔥 Viền vàng đậm phong cách cổ trang
            border: Border.all(
              width: 4,
              color: const Color(0xFFFFD97D),
            ),

            // 🔥 Đổ bóng cổ trang
            boxShadow: [
              BoxShadow(
                color: Colors.amber.shade200.withOpacity(0.65),
                blurRadius: 20,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 12,
                offset: const Offset(3, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              "assets/images/dongson_pattern.jpg",
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
