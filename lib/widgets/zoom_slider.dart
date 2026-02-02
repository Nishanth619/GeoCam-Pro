import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ZoomSlider extends StatefulWidget {
  final double value; // Initial value 0.0 to 1.0
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

  const ZoomSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
  });

  @override
  State<ZoomSlider> createState() => _ZoomSliderState();
}

class _ZoomSliderState extends State<ZoomSlider> {
  late double _currentValue;
  Timer? _throttleTimer;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(ZoomSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with external state if not currently dragging
    if (_throttleTimer == null) {
      _currentValue = widget.value;
    }
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }

  void _updateValue(double localY, double totalHeight) {
    // 20 is the vertical padding we added in the container
    final usableHeight = totalHeight - 40; 
    final adjustedY = localY - 20;
    final newValue = (1 - (adjustedY / usableHeight)).clamp(0.0, 1.0);
    
    if (newValue != _currentValue) {
      setState(() {
        _currentValue = newValue;
      });

      // Throttled update to the camera hardware (at most every 50ms)
      if (_throttleTimer == null) {
        widget.onChanged?.call(newValue);
        _throttleTimer = Timer(const Duration(milliseconds: 50), () {
          _throttleTimer = null;
          // Send final value if it changed during the throttle period
          if (_currentValue != newValue) {
              widget.onChanged?.call(_currentValue);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Zoom value bubble
          Positioned(
            left: -60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(
                '${(1.0 + _currentValue * 4.0).toStringAsFixed(1)}x',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          // Slider track container (Hit Area)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) {
              _updateValue(details.localPosition.dy, 320);
            },
            onTapDown: (details) {
              _updateValue(details.localPosition.dy, 320);
            },
            child: Container(
              width: 56, // Large hit area
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Icon(
                    Icons.add,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  // Visual Slider track
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final trackHeight = constraints.maxHeight;
                          final thumbPosition = trackHeight * (1 - _currentValue);
                          
                          return Stack(
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.none,
                            children: [
                              // Track background
                              Container(
                                width: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              // Active track
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  width: 6,
                                  height: trackHeight * _currentValue,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                              // Thumb
                              Positioned(
                                top: thumbPosition - 14,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Icon(
                    Icons.remove,
                    size: 20,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
