import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/openalpr_service.dart';
import '../models/plate_result.dart';

class CameraPreviewWidget extends StatefulWidget {
  final Function(List<PlateResult>) onPlatesDetected;
  final Function(String) onError;

  const CameraPreviewWidget({
    super.key,
    required this.onPlatesDetected,
    required this.onError,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  List<PlateResult> _detectedPlates = [];
  final OpenALPRService _openAlprService = OpenALPRService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeOpenALPR();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        
        await _controller!.initialize();
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      widget.onError('Failed to initialize camera: $e');
    }
  }

  Future<void> _initializeOpenALPR() async {
    try {
      await _openAlprService.initialize();
    } catch (e) {
      widget.onError('Failed to initialize OpenALPR: $e');
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile image = await _controller!.takePicture();
      final List<PlateResult> results = await _openAlprService.recognizePlatesFromFile(
        imagePath: image.path,
        country: 'us',
        region: '',
        topN: 5,
      );

      if (mounted) {
        setState(() {
          _detectedPlates = results;
        });
        widget.onPlatesDetected(results);
      }
    } catch (e) {
      widget.onError('Error during plate recognition: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _openAlprService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        // Camera preview
        SizedBox.expand(
          child: CameraPreview(_controller!),
        ),
        
        // Plate detection overlays
        ..._buildPlateOverlays(),
        
        // Controls
        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton.large(
              onPressed: _isProcessing ? null : _captureAndAnalyze,
              backgroundColor: _isProcessing 
                  ? Colors.grey 
                  : Theme.of(context).colorScheme.primary,
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.camera_alt, size: 32),
            ),
          ),
        ),
        
        // Processing indicator
        if (_isProcessing)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Analyzing...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildPlateOverlays() {
    return _detectedPlates.map((plate) {
      return Positioned.fill(
        child: CustomPaint(
          painter: PlatePainter(
            plate: plate,
            cameraController: _controller!,
          ),
        ),
      );
    }).toList();
  }
}

class PlatePainter extends CustomPainter {
  final PlateResult plate;
  final CameraController cameraController;

  PlatePainter({
    required this.plate,
    required this.cameraController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (plate.coordinates.length < 4) return;

    final paint = Paint()
      ..color = plate.confidence > 80 ? Colors.green : Colors.orange
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final textPaint = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Create path from coordinates
    final path = Path();
    final coordinates = plate.coordinates;
    
    // Scale coordinates to match the widget size
    final scaleX = size.width / cameraController.value.previewSize!.height;
    final scaleY = size.height / cameraController.value.previewSize!.width;

    path.moveTo(coordinates[0].x * scaleX, coordinates[0].y * scaleY);
    for (int i = 1; i < coordinates.length; i++) {
      path.lineTo(coordinates[i].x * scaleX, coordinates[i].y * scaleY);
    }
    path.close();

    canvas.drawPath(path, paint);

    // Draw plate text
    textPaint.text = TextSpan(
      text: '${plate.plateNumber} (${plate.confidence.toStringAsFixed(1)}%)',
      style: TextStyle(
        color: plate.confidence > 80 ? Colors.green : Colors.orange,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 2,
            color: Colors.black54,
          ),
        ],
      ),
    );

    textPaint.layout();
    
    // Position text above the plate
    final centerX = coordinates.map((c) => c.x * scaleX).reduce((a, b) => a + b) / coordinates.length;
    final minY = coordinates.map((c) => c.y * scaleY).reduce((a, b) => a < b ? a : b);
    
    textPaint.paint(canvas, Offset(centerX - textPaint.width / 2, minY - 30));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}