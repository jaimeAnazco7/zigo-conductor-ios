import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart' as lt;
import 'package:taxi_driver/utils/Images.dart';

/// Animación del pill "Estás en línea". Usa [AnimationController] para no
/// reiniciar la animación en cada setState del mapa (GPS).
class DriverOnlineTaxiAnim extends StatefulWidget {
  final bool isOnline;
  final double width;
  final double height;

  const DriverOnlineTaxiAnim({
    super.key,
    required this.isOnline,
    this.width = 50,
    this.height = 28,
  });

  @override
  State<DriverOnlineTaxiAnim> createState() => _DriverOnlineTaxiAnimState();
}

class _DriverOnlineTaxiAnimState extends State<DriverOnlineTaxiAnim>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _compositionReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  void _onCompositionLoaded(lt.LottieComposition composition) {
    if (!mounted) return;
    _compositionReady = true;
    _controller.duration = composition.duration;
    _syncPlayback();
  }

  void _syncPlayback() {
    if (!_compositionReady) return;
    if (widget.isOnline) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant DriverOnlineTaxiAnim oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline) {
      _syncPlayback();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOnline) {
      return Image.asset(ic_red_car, height: 22, fit: BoxFit.contain);
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: lt.Lottie.asset(
        taxiAnim,
        controller: _controller,
        fit: BoxFit.contain,
        frameRate: const lt.FrameRate(10),
        repeat: true,
        onLoaded: _onCompositionLoaded,
      ),
    );
  }
}
