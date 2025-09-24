import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/alpr_service_factory.dart';
import '../services/alpr_service_interface.dart';
import '../core/alpr_config.dart';
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
  ALPRServiceInterface? _alprService;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeALPR();
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

  Future<void> _initializeALPR() async {
    try {
      _alprService = ALPRServiceFactory.getCurrentService();

      if (!_alprService!.isInitialized) {
        await _alprService!.initialize();
      }

      final providerName = ALPRConfig.getProviderDisplayName(ALPRConfig.currentProvider);
      print('ALPR initialized successfully with $providerName');
      widget.onError('🚀 $providerName ready for license plate recognition!');
    } catch (e) {
      print('ALPR initialization failed: $e');
      widget.onError('Failed to initialize plate recognition: $e');
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

      if (_alprService != null && _alprService!.isInitialized) {
        try {
          final providerName = ALPRConfig.getProviderDisplayName(ALPRConfig.currentProvider);
          widget.onError('🔍 Processing with $providerName...');

          final plates = await _alprService!.recognizePlatesFromFile(
            imagePath: image.path,
            country: 'us',
          );

          if (mounted) {
            setState(() {
              _detectedPlates = plates;
            });
            widget.onPlatesDetected(plates);

            if (plates.isNotEmpty) {
              widget.onError('✅ $providerName detected ${plates.length} plate(s)!');
            } else {
              widget.onError('📸 Photo processed - no plates detected');
            }
          }
        } catch (e) {
          widget.onError('Error in ALPR processing: $e');
          if (mounted) {
            setState(() {
              _detectedPlates = [];
            });
            widget.onPlatesDetected([]);
          }
        }
      } else {
        // No ALPR available - camera only mode
        widget.onError('📸 Photo captured! ALPR service not available.');
        if (mounted) {
          setState(() {
            _detectedPlates = [];
          });
          widget.onPlatesDetected([]);
        }
      }
    } catch (e) {
      widget.onError('Error taking photo: $e');
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
    // Note: Don't dispose the ALPR service here as it's managed by the factory
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
