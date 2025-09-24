import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/add_note_dialog.dart';
import '../models/plate_result.dart';
import 'all_notes_screen.dart';
import 'alpr_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PlateResult> _detectedPlates = [];
  String? _errorMessage;
  bool _hasPermissions = false;

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

  void _showSettingsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ALPRSettingsScreen(),
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
            onPressed: _showInfoDialog,
            icon: const Icon(Icons.info_outline),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'notes') {
                _showNotesScreen();
              } else if (value == 'settings') {
                _showSettingsScreen();
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
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('ALPR Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _hasPermissions
          ? Column(
              children: [
                // Camera preview
                Expanded(
                  flex: 3,
                  child: CameraPreviewWidget(
                    onPlatesDetected: _onPlatesDetected,
                    onError: _onError,
                  ),
                ),
                
                // Results section
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: _buildResultsSection(),
                  ),
                ),
              ],
            )
          : _buildPermissionRequiredView(),
    );
  }

  Widget _buildResultsSection() {
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
              'Tap the camera button to take photos',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
        Text(
          'Detected Plates (${_detectedPlates.length})',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _detectedPlates.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final plate = _detectedPlates[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: plate.confidence > 80 
                        ? Colors.green 
                        : plate.confidence > 60 
                            ? Colors.orange 
                            : Colors.red,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    plate.plateNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  subtitle: Text(
                    'Confidence: ${plate.confidence.toStringAsFixed(1)}% • Region: ${plate.region}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => AddNoteDialog(
                              plateResult: plate,
                            ),
                          );
                        },
                        icon: const Icon(Icons.note_add),
                        tooltip: 'Add Note',
                      ),
                      Icon(
                        plate.confidence > 80
                            ? Icons.check_circle
                            : plate.confidence > 60
                                ? Icons.warning
                                : Icons.error,
                        color: plate.confidence > 80
                            ? Colors.green
                            : plate.confidence > 60
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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
              label: const Text('Grant Camera Access'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
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
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
