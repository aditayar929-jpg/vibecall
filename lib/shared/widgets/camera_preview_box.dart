import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// Shows user's front camera in a small box during video call.
/// Like a real video call — you see yourself in the corner.
class CameraPreviewBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const CameraPreviewBox({
    super.key,
    this.width = 110,
    this.height = 150,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<CameraPreviewBox> createState() => _CameraPreviewBoxState();
}

class _CameraPreviewBoxState extends State<CameraPreviewBox> {
  CameraController? _controller;
  bool _initialized = false;
  bool _failed = false;
  bool _isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _failed = true);
        return;
      }

      // Find front camera
      CameraDescription camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _flipCamera() async {
    if (_controller == null) return;

    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) return;

      final newDirection = _isFrontCamera
          ? CameraLensDirection.back
          : CameraLensDirection.front;

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == newDirection,
        orElse: () => cameras.first,
      );

      await _controller!.dispose();
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();

      if (mounted) {
        setState(() => _isFrontCamera = !_isFrontCamera);
      }
    } catch (e) {
      // Ignore flip errors
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCamera,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
          ],
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_failed) {
      return Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(
          child: Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 28),
        ),
      );
    }

    if (!_initialized || _controller == null) {
      return Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        // Flip icon hint
        Positioned(
          top: 6, right: 6,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white70, size: 14),
          ),
        ),
      ],
    );
  }
}
