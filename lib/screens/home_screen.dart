import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/add_note_dialog.dart';
import '../models/plate_result.dart';
import 'all_notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PlateResult> _detectedPlates = [];
  String? _errorMessage;
  String? _statusMessage;
  bool _hasPermissions = false;
  String? _capturedImagePath;
  bool _isAnalysisMode = false;
  int? _selectedPlateIndex;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> permissions = await [
      Permission.camera,
    ].request();
    
    if (permissions[Permission.camera]?.isDenied == true) {
      _showPermissionDialog(
        'Camera Permission Required',
        'This app needs camera access to capture images for license plate recognition.',
        Permission.camera,
      );
      return;
    }
    
    // Storage permission is not required for internal app storage
    
    setState(() {
      _hasPermissions = true;
    });
  }

  void _showPermissionDialog(String title, String message, Permission permission) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermissions();
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  void _onPlatesDetected(List<PlateResult> plates) {
    setState(() {
      _detectedPlates = plates;
      _errorMessage = null;
      _statusMessage = null;
      _isAnalysisMode = true; // Switch to analysis mode when plates are detected
      _selectedPlateIndex = null; // Reset selection
    });
  }

  void _onImageCaptured(String imagePath) {
    setState(() {
      _capturedImagePath = imagePath;
    });
  }

  void _selectPlate(int index) {
    setState(() {
      _selectedPlateIndex = index;
    });
  }

  void _returnToCamera() {
    setState(() {
      _isAnalysisMode = false;
      _capturedImagePath = null;
      _detectedPlates = [];
      _selectedPlateIndex = null;
      _errorMessage = null;
      _statusMessage = null;
    });
  }

  void _onStatusUpdate(String status) {
    setState(() {
      _statusMessage = status;
      _errorMessage = null;
    });
  }

  void _onError(String error) {
    setState(() {
      _errorMessage = error;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _clearDetectedPlates() {
    setState(() {
      _detectedPlates.clear();
      _errorMessage = null;
    });
  }

  void _showNotesScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AllNotesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera App'),
        actions: [
          if (_detectedPlates.isNotEmpty)
            IconButton(
              onPressed: _clearDetectedPlates,
              icon: const Icon(Icons.clear),
              tooltip: 'Clear Results',
            ),
          IconButton(
            onPressed: _showAboutDialog,
            icon: const Icon(Icons.info_outline),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'notes') {
                _showNotesScreen();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'notes',
                child: Row(
                  children: [
                    Icon(Icons.note, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('My Notes'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _hasPermissions
          ? Stack(
              children: [
                // Camera preview (full screen)
                _isAnalysisMode && _capturedImagePath != null
                    ? _buildAnalysisView()
                    : CameraPreviewWidget(
                        onPlatesDetected: _onPlatesDetected,
                        onError: _onError,
                        onStatusUpdate: _onStatusUpdate,
                        onImageCaptured: _onImageCaptured,
                      ),
                
                // Draggable bottom sheet
                DraggableScrollableSheet(
                  initialChildSize: 0.25, // Start at 25% of screen height
                  minChildSize: 0.1, // Minimum 10% of screen height
                  maxChildSize: 0.7, // Maximum 70% of screen height
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Drag handle
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Results content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildResultsSection(scrollController),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            )
          : _buildPermissionRequiredView(),
    );
  }

  Widget _buildResultsSection(ScrollController? scrollController) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error occurred',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_detectedPlates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage ?? 'Tap the camera button to scan license plates',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: _statusMessage != null 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Detected Plates (${_detectedPlates.length})',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (_isAnalysisMode)
              TextButton.icon(
                onPressed: _returnToCamera,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('New Photo'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            itemCount: _detectedPlates.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final plate = _detectedPlates[index];
              final isSelected = _selectedPlateIndex == index;
              return Card(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: InkWell(
                  onTap: () => _selectPlate(index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              plate.plateNumber,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.onPrimaryContainer
                                    : null,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: plate.confidence > 80 
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${plate.confidence.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: plate.confidence > 80 ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Region: ${plate.region.toUpperCase()}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Highlighted on image',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisView() {
    return Stack(
      children: [
        // Static captured image
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: FileImage(File(_capturedImagePath!)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Plate overlays - only show selected plate or all if none selected
        ..._buildAnalysisOverlays(),
        
        // Return to camera button
        Positioned(
          top: 20,
          right: 20,
          child: FloatingActionButton(
            mini: true,
            onPressed: _returnToCamera,
            backgroundColor: Colors.black54,
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAnalysisOverlays() {
    return _detectedPlates.asMap().entries.map((entry) {
      final index = entry.key;
      final plate = entry.value;
      
      // Show all plates if none selected, or only the selected one
      if (_selectedPlateIndex != null && _selectedPlateIndex != index) {
        return const SizedBox.shrink();
      }
      
      return Positioned.fill(
        child: CustomPaint(
          painter: AnalysisPlatePainter(
            plate: plate,
            isSelected: _selectedPlateIndex == index,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPermissionRequiredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 32),
            Text(
              'Camera Access Required',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This app needs access to your camera to scan license plates. Please grant camera permission to continue.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestPermissions,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Grant Camera Permission'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Camera App'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A simple camera app for taking photos.'),
            SizedBox(height: 16),
            Text('Features:'),
            SizedBox(height: 8),
            Text('• Real-time camera preview'),
            Text('• Photo capture'),
            Text('• Camera controls'),
            SizedBox(height: 16),
            Text('Tap the camera button to take a photo.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class AnalysisPlatePainter extends CustomPainter {
  final PlateResult plate;
  final bool isSelected;

  AnalysisPlatePainter({
    required this.plate,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (plate.coordinates.length < 4) return;

    final paint = Paint()
      ..color = isSelected 
          ? Colors.red.withValues(alpha: 0.8)
          : (plate.confidence > 80 ? Colors.green : Colors.orange)
      ..strokeWidth = isSelected ? 4.0 : 3.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = isSelected 
          ? Colors.red.withValues(alpha: 0.2)
          : (plate.confidence > 80 ? Colors.green : Colors.orange).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final textPaint = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Extract rectangle coordinates
    final coordinates = plate.coordinates;
    final topLeft = coordinates[0];
    final bottomRight = coordinates[2];
    
    // Get the actual image dimensions for proper scaling
    // The coordinates from ALPR are in the original processed image coordinate system
    // We need to scale them to match the display container
    
    // For now, let's use a more dynamic approach based on common camera resolutions
    // Most phone cameras capture at various resolutions, but our processing resizes to max 1280 width
    final imageWidth = 1280.0; // From our Python processing
    final imageHeight = 960.0; // Typical 4:3 aspect ratio
    
    // Scale coordinates to display size
    final left = (topLeft.x / imageWidth) * size.width;
    final top = (topLeft.y / imageHeight) * size.height;
    final right = (bottomRight.x / imageWidth) * size.width;
    final bottom = (bottomRight.y / imageHeight) * size.height;
    
    // Draw rectangle with fill if selected
    final rect = Rect.fromLTRB(left, top, right, bottom);
    if (isSelected) {
      canvas.drawRect(rect, fillPaint);
    }
    canvas.drawRect(rect, paint);

    // Draw plate text
    textPaint.text = TextSpan(
      text: '${plate.plateNumber} (${plate.confidence.toStringAsFixed(1)}%)',
      style: TextStyle(
        color: isSelected ? Colors.red : (plate.confidence > 80 ? Colors.green : Colors.orange),
        fontSize: isSelected ? 16 : 14,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 2,
            color: Colors.black87,
          ),
        ],
      ),
    );

    textPaint.layout();
    
    // Position text above the rectangle
    final centerX = (left + right) / 2;
    final textX = centerX - textPaint.width / 2;
    final textY = top - 30;
    
    // Ensure text stays within bounds
    final adjustedX = textX.clamp(0.0, size.width - textPaint.width);
    final adjustedY = textY.clamp(0.0, size.height - textPaint.height);
    
    // Draw text background if selected
    if (isSelected) {
      final textBg = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(adjustedX - 4, adjustedY - 2, textPaint.width + 8, textPaint.height + 4),
          const Radius.circular(4),
        ),
        textBg,
      );
    }
    
    textPaint.paint(canvas, Offset(adjustedX, adjustedY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension _HomeScreenStateExtension on _HomeScreenState {
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About ALPR Scanner'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Advanced license plate recognition app with Chaquopy ALPR.'),
            SizedBox(height: 16),
            Text('Features:'),
            SizedBox(height: 8),
            Text('• Real-time camera preview'),
            Text('• Static image analysis mode'),
            Text('• Click plates to highlight'),
            Text('• High-accuracy detection'),
            SizedBox(height: 16),
            Text('Take a photo to analyze license plates, then click detected plates to highlight them.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
