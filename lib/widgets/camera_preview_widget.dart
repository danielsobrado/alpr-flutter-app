import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/alpr_service_factory.dart';
import '../services/alpr_service_interface.dart';
import '../core/alpr_config.dart';
import '../models/plate_result.dart';

class CameraPreviewWidget extends StatefulWidget {
  final Function(List<PlateResult>) onPlatesDetected;
  final Function(String) onError;
  final Function(String)? onStatusUpdate;
  final Function(String)? onImageCaptured;

  const CameraPreviewWidget({
    super.key,
    required this.onPlatesDetected,
    required this.onError,
    this.onStatusUpdate,
    this.onImageCaptured,
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
      if (widget.onStatusUpdate != null) {
        widget.onStatusUpdate!('🚀 $providerName ready for license plate recognition!');
      }
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
      
      // Notify that image was captured
      widget.onImageCaptured?.call(image.path);

      if (_alprService != null && _alprService!.isInitialized) {
        try {
          final providerName = ALPRConfig.getProviderDisplayName(ALPRConfig.currentProvider);
          if (widget.onStatusUpdate != null) {
            widget.onStatusUpdate!('🔍 Processing with $providerName...');
          }

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
              if (widget.onStatusUpdate != null) {
                widget.onStatusUpdate!('✅ $providerName detected ${plates.length} plate(s)!');
              }
            } else {
              if (widget.onStatusUpdate != null) {
                widget.onStatusUpdate!('📸 Photo processed - no plates detected');
              }
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
        if (widget.onStatusUpdate != null) {
          widget.onStatusUpdate!('📸 Photo captured! ALPR service not available.');
        }
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

    // Extract rectangle coordinates (first coordinate is top-left)
    final coordinates = plate.coordinates;
    final topLeft = coordinates[0];
    final bottomRight = coordinates[2];
    
    // Scale coordinates to match the camera preview size
    // The coordinates come from our processed image (max 1280 width)
    // but we need to scale them to the camera preview display size
    final previewSize = cameraController.value.previewSize!;
    final scaleX = size.width / 1280.0; // Match our Python processing width
    final scaleY = size.height / 960.0; // Match our Python processing height

    // Calculate scaled rectangle
    final left = topLeft.x * scaleX;
    final top = topLeft.y * scaleY;
    final right = bottomRight.x * scaleX;
    final bottom = bottomRight.y * scaleY;
    
    // Draw rectangle
    final rect = Rect.fromLTRB(left, top, right, bottom);
    canvas.drawRect(rect, paint);

    // Draw plate text
    textPaint.text = TextSpan(
      text: '${plate.plateNumber} (${plate.confidence.toStringAsFixed(1)}%)',
      style: TextStyle(
        color: plate.confidence > 80 ? Colors.green : Colors.orange,
        fontSize: 14,
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
    
    // Position text above the rectangle
    final centerX = (left + right) / 2;
    final textX = centerX - textPaint.width / 2;
    final textY = top - 25; // Position above the rectangle
    
    // Ensure text stays within bounds
    final adjustedX = textX.clamp(0.0, size.width - textPaint.width);
    final adjustedY = textY.clamp(0.0, size.height - textPaint.height);
    
    textPaint.paint(canvas, Offset(adjustedX, adjustedY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
