import 'dart:async';
import 'package:flutter/material.dart';

class ControlButton extends StatefulWidget {
  final Widget icon;
  final String? label;
  final VoidCallback onPressed;
  final bool enableRepeat;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  const ControlButton({
    super.key,
    required this.icon,
    this.label,
    required this.onPressed,
    this.enableRepeat = false,
    this.color,
    this.backgroundColor,
    this.size = 62.0,
  });

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  Timer? _initialDelayTimer;
  Timer? _repeatTimer;
  bool _isPressed = false;

  void _startPress() {
    setState(() => _isPressed = true);
    widget.onPressed();

    if (widget.enableRepeat) {
      _initialDelayTimer?.cancel();
      _repeatTimer?.cancel();
      _initialDelayTimer = Timer(const Duration(milliseconds: 170), () {
        _repeatTimer = Timer.periodic(const Duration(milliseconds: 55), (_) {
          widget.onPressed();
        });
      });
    }
  }

  void _endPress() {
    setState(() => _isPressed = false);
    _initialDelayTimer?.cancel();
    _repeatTimer?.cancel();
  }

  @override
  void dispose() {
    _initialDelayTimer?.cancel();
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? const Color(0xFF21262D);
    final fgColor = widget.color ?? Colors.white;

    return GestureDetector(
      onTapDown: (_) => _startPress(),
      onTapUp: (_) => _endPress(),
      onTapCancel: () => _endPress(),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 60),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _isPressed ? bgColor.withValues(alpha: 0.7) : bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: _isPressed ? fgColor : fgColor.withValues(alpha: 0.35),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed ? fgColor.withValues(alpha: 0.4) : Colors.black45,
                blurRadius: _isPressed ? 10 : 4,
                spreadRadius: _isPressed ? 1 : 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: fgColor,
                  size: widget.label == null ? 30 : 24,
                ),
                child: widget.icon,
              ),
              if (widget.label != null) ...[
                const SizedBox(height: 1),
                Text(
                  widget.label!,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
