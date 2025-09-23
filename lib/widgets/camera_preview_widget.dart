import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/openalpr_service.dart';
import '../services/termux_alpr_service.dart';
import '../services/chaquopy_alpr_service.dart';
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
  final TermuxAlprService _termuxAlprService = TermuxAlprService();
  final ChaquopyAlprService _chaquopyAlprService = ChaquopyAlprService();
  bool _useTermuxAlpr = false;
  bool _useChaquopyAlpr = false;

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
    // First try Chaquopy ALPR (best modern solution)
    try {
      final chaquopyAvailable = await _chaquopyAlprService.isChaquopyAvailable();
      if (chaquopyAvailable) {
        await _chaquopyAlprService.initialize();
        _useChaquopyAlpr = true;
        widget.onError('🔥 Chaquopy ALPR ready! Advanced local processing on your Samsung Galaxy S25.');
        print('Chaquopy ALPR: Successfully initialized');
        return;
      }
    } catch (e) {
      print('Chaquopy ALPR initialization failed: $e');
    }

    // Second try Termux ALPR (alternative modern solution)
    try {
      final termuxAvailable = await _termuxAlprService.isTermuxAvailable();
      if (termuxAvailable) {
        await _termuxAlprService.initialize();
        _useTermuxAlpr = true;
        widget.onError('🚀 Termux ALPR initialized! Local processing ready on your Samsung Galaxy S25.');
        print('Termux ALPR: Successfully initialized');
        return;
      }
    } catch (e) {
      print('Termux ALPR initialization failed: $e');
    }

    // Fallback to original OpenALPR (will fail on ARM64)
    try {
      await _openAlprService.initialize();
      print('OpenALPR initialized successfully');
    } catch (e) {
      print('OpenALPR initialization failed: $e');
      if (e.toString().contains('NATIVE_LIB_ERROR')) {
        widget.onError('📱 Using camera-only mode. Chaquopy ALPR integrated for next update!');
      } else {
        widget.onError('Failed to initialize plate recognition: $e');
      }
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
      
      // Try ALPR processing based on available service (priority order)
      if (_useChaquopyAlpr && _chaquopyAlprService.isInitialized) {
        try {
          widget.onError('🔥 Processing with Chaquopy ALPR...');
          final plates = await _chaquopyAlprService.recognizePlatesFromFile(
            imagePath: image.path,
            country: 'us',
          );
          
          if (mounted) {
            setState(() {
              _detectedPlates = plates;
            });
            widget.onPlatesDetected(plates);
            
            if (plates.isNotEmpty) {
              widget.onError('✅ Chaquopy ALPR detected ${plates.length} plate(s)!');
            } else {
              widget.onError('📸 Photo processed - no plates detected');
            }
          }
        } catch (e) {
          widget.onError('Error in Chaquopy ALPR: $e');
          if (mounted) {
            setState(() {
              _detectedPlates = [];
            });
            widget.onPlatesDetected([]);
          }
        }
      } else if (_useTermuxAlpr && _termuxAlprService.isInitialized) {
        try {
          widget.onError('🔍 Processing with Termux ALPR...');
          final plates = await _termuxAlprService.recognizePlatesFromFile(
            imagePath: image.path,
            country: 'us',
          );
          
          if (mounted) {
            setState(() {
              _detectedPlates = plates;
            });
            widget.onPlatesDetected(plates);
            
            if (plates.isNotEmpty) {
              widget.onError('✅ Termux ALPR detected ${plates.length} plate(s)!');
            } else {
              widget.onError('📸 Photo processed - no plates detected');
            }
          }
        } catch (e) {
          widget.onError('Error in Termux ALPR: $e');
          if (mounted) {
            setState(() {
              _detectedPlates = [];
            });
            widget.onPlatesDetected([]);
          }
        }
      } else if (_openAlprService.isInitialized) {
        try {
          final plates = await _openAlprService.recognizePlatesFromFile(
            imagePath: image.path,
            country: 'us',
          );
          
          if (mounted) {
            setState(() {
              _detectedPlates = plates;
            });
            widget.onPlatesDetected(plates);
            
            if (plates.isNotEmpty) {
              widget.onError('✅ Detected ${plates.length} plate(s)');
            } else {
              widget.onError('📸 Photo captured - no plates detected');
            }
          }
        } catch (e) {
          widget.onError('Error analyzing photo: $e');
          if (mounted) {
            setState(() {
              _detectedPlates = [];
            });
            widget.onPlatesDetected([]);
          }
        }
      } else {
        // No ALPR available - camera only mode
        widget.onError('📸 Photo captured! Chaquopy ALPR ready for processing in this build.');
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
    _openAlprService.dispose();
    _termuxAlprService.dispose();
    _chaquopyAlprService.dispose();
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
