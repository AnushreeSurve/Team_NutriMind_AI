/// PPG Heart Rate screen — camera preview UI and instruction overlay.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/gradient_button.dart';

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../repository/ppg_repository.dart';

class PpgScreen extends ConsumerStatefulWidget {
  const PpgScreen({super.key});

  @override
  ConsumerState<PpgScreen> createState() => _PpgScreenState();
}

class _PpgScreenState extends ConsumerState<PpgScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  late AnimationController _pulseController;
  
  CameraController? _cameraController;
  bool _cameraInitialized = false;
  
  final List<double> _rChannel = [];
  final List<double> _gChannel = [];
  final List<double> _timestamps = [];
  final int _scanDurationSeconds = 15;
  
  Timer? _timer;
  int _secondsRemaining = 15;
  int _startTime = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (await Permission.camera.request().isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first, // usually the rear camera
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420, // default android
        );
        await _cameraController!.initialize();
        // Try getting max zoom for better finger coverage
        try {
          final maxZoom = await _cameraController!.getMaxZoomLevel();
          await _cameraController!.setZoomLevel(maxZoom > 2.0 ? 2.0 : maxZoom);
        } catch (_) {}
        
        if (mounted) {
          setState(() => _cameraInitialized = true);
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.setFlashMode(FlashMode.off);
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startScan() async {
    if (!_cameraInitialized || _cameraController == null) return;
    
    setState(() {
      _isScanning = true;
      _secondsRemaining = _scanDurationSeconds;
      _rChannel.clear();
      _gChannel.clear();
      _timestamps.clear();
    });
    
    _pulseController.repeat(reverse: true);
    await _cameraController!.setFlashMode(FlashMode.torch);
    _startTime = DateTime.now().millisecondsSinceEpoch;
    
    _cameraController!.startImageStream((CameraImage image) {
      final int now = DateTime.now().millisecondsSinceEpoch;
      _timestamps.add((now - _startTime) / 1000.0);
      
      double r = 0, g = 0;
      if (image.format.group == ImageFormatGroup.yuv420 || image.format.group == ImageFormatGroup.nv21) {
         final yPlane = image.planes[0].bytes;
         int ySum = 0;
         for (int i=0; i < yPlane.length; i+=4) ySum += yPlane[i];
         r = ySum / (yPlane.length / 4);
         g = r; // Approximate G with Luma as well for demo purposes
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
         final bytes = image.planes[0].bytes;
         int rSum = 0, gSum = 0;
         for (int i=0; i < bytes.length; i+=4) {
           rSum += bytes[i+2]; // R
           gSum += bytes[i+1]; // G
         }
         r = rSum / (bytes.length / 4);
         g = gSum / (bytes.length / 4);
      }
      _rChannel.add(r);
      _gChannel.add(g);
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        _finishScan();
      }
    });
  }
  
  void _finishScan() async {
    _timer?.cancel();
    _pulseController.stop();
    await _cameraController?.stopImageStream();
    await _cameraController?.setFlashMode(FlashMode.off);
    
    setState(() => _isScanning = false);
    
    // Call backend
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      final repo = PpgRepository();
      final result = await repo.analyze(timestamps: _timestamps, rChannel: _rChannel, gChannel: _gChannel);
      if (mounted) {
        Navigator.pop(context); // close dialog
        context.push('/ppg-result', extra: result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            // ── Camera preview placeholder ─────────────────────
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.08);
                return Transform.scale(scale: _isScanning ? scale : 1.0, child: child);
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isScanning
                      ? AppTheme.errorRed.withValues(alpha: 0.15)
                      : AppTheme.primaryTeal.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _isScanning ? AppTheme.errorRed : AppTheme.primaryTeal,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _cameraInitialized && _isScanning
                      ? CameraPreview(_cameraController!)
                      : Center(
                          child: Icon(
                            _isScanning
                                ? Icons.favorite_rounded
                                : Icons.camera_alt_rounded,
                            size: 64,
                            color: _isScanning ? AppTheme.errorRed : AppTheme.primaryTeal,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Status text ────────────────────────────────────
            Text(
              _isScanning ? '$_secondsRemaining seconds remaining' : 'Ready to scan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _isScanning ? AppTheme.errorRed : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isScanning
                  ? 'Place your finger on the camera lens'
                  : 'Tap the button below to start',
              style: TextStyle(
                color: AppTheme.subtitleGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),

            // ── Instructions ───────────────────────────────────
            if (!_isScanning) ...[
              _InstructionRow(
                icon: Icons.fingerprint_rounded,
                text: 'Place your index finger on the camera lens',
              ),
              const SizedBox(height: 12),
              _InstructionRow(
                icon: Icons.flash_on_rounded,
                text: 'Keep the flashlight on during measurement',
              ),
              const SizedBox(height: 12),
              _InstructionRow(
                icon: Icons.timer_rounded,
                text: 'Hold still for about 15 seconds',
              ),
              const SizedBox(height: 12),
              _InstructionRow(
                icon: Icons.airline_seat_recline_normal_rounded,
                text: 'Sit comfortably and relax',
              ),
            ],

            const Spacer(),

            // ── Start button ───────────────────────────────────
            GradientButton(
              text: _isScanning ? 'Scanning...' : 'Start Scan',
              isLoading: _isScanning,
              icon: Icons.monitor_heart_rounded,
              onPressed: _isScanning ? () {} : _startScan,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryTeal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.subtitleGrey,
            ),
          ),
        ),
      ],
    );
  }
}
