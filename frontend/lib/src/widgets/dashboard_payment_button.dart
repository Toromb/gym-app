import 'package:flutter/material.dart';
import '../models/user_model.dart';

class DashboardPaymentButton extends StatefulWidget {
  final User user;
  final bool isExpired;
  final bool isNearExpiration;
  final VoidCallback onTap;

  const DashboardPaymentButton({
    super.key,
    required this.user,
    required this.isExpired,
    required this.isNearExpiration,
    required this.onTap,
  });

  @override
  State<DashboardPaymentButton> createState() => _DashboardPaymentButtonState();
}

class _DashboardPaymentButtonState extends State<DashboardPaymentButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = (widget.isExpired || widget.isNearExpiration) ? Colors.orange : Colors.green;
    final bgColor = (widget.isExpired || widget.isNearExpiration) ? Colors.orange[50] : Colors.green[50];
    final textColor = (widget.isExpired || widget.isNearExpiration) ? Colors.orange[800] : Colors.green[800];
    
    final text = widget.isExpired 
        ? 'VENCIDA' 
        : (widget.isNearExpiration ? 'CUOTA POR VENCER' : 'CUOTA PAGA');

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isPressed ? color : color.withOpacity(0.5) 
          ),
          boxShadow: _isPressed 
            ? [] 
            : [
                BoxShadow(
                  color: color.withOpacity(0.5), // Increased opacity from 0.2
                  blurRadius: 6, // Increased blur
                  offset: const Offset(0, 4), // Increased offset for more "height"
                )
              ],
        ),
        transform: _isPressed ? Matrix4.translationValues(0, 1, 0) : Matrix4.identity(), 
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(
               Icons.access_time_filled, 
               size: 14, 
               color: color
             ),
             const SizedBox(width: 6),
             Text(
               text,
               style: TextStyle(
                 fontSize: 10, 
                 fontWeight: FontWeight.bold,
                 color: textColor
               ),
             ),
             const SizedBox(width: 4),
             Icon(
               Icons.keyboard_arrow_down, 
               size: 16, 
               color: textColor
             ),
          ],
        ),
      ),
    );
  }
}
