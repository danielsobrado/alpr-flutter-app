import 'package:flutter/material.dart';
import '../services/fastalpr_service.dart';
import '../services/model_manager.dart';
import 'model_management_screen.dart';

class FastALPRSettingsScreen extends StatefulWidget {
  final FastALPRService fastAlprService;

  const FastALPRSettingsScreen({
    super.key,
    required this.fastAlprService,
  });

  @override
  State<FastALPRSettingsScreen> createState() => _FastALPRSettingsScreenState();
}

class _FastALPRSettingsScreenState extends State<FastALPRSettingsScreen> {
  String? _selectedDetectorModelId;
  String? _selectedOcrModelId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSelection();
  }

  void _loadCurrentSelection() {
    _selectedDetectorModelId = widget.fastAlprService.currentDetectorModelId;
    _selectedOcrModelId = widget.fastAlprService.currentOcrModelId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FastALPR Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _openModelManager,
            icon: const Icon(Icons.download),
            tooltip: 'Manage Models',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'FastALPR Configuration',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'FastALPR uses separate models for detection and OCR. You need to download models before they can be used.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Detection model selection
            Text(
              'Detection Model',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'YOLO model for finding license plates in images',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            _buildDetectorModelDropdown(),

            const SizedBox(height: 24),

            // OCR model selection
            Text(
              'OCR Model',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Model for reading text from detected license plates',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            _buildOcrModelDropdown(),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _openModelManager,
                  icon: const Icon(Icons.download),
                  label: const Text('Download Models'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _canApplySettings() && !_isLoading ? _applySettings : null,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isLoading ? 'Applying...' : 'Apply Settings'),
                ),
              ],
            ),

            const Spacer(),

            // Current status
            _buildCurrentStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectorModelDropdown() {
    return FutureBuilder<List<ONNXModel>>(
      future: widget.fastAlprService.modelManager.getDownloadedModels(ModelType.detector),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final models = snapshot.data ?? [];

        if (models.isEmpty) {
          return Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Detection Models Downloaded',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Download models to enable FastALPR functionality',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _openModelManager,
                    child: const Text('Download'),
                  ),
                ],
              ),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          value: _selectedDetectorModelId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          hint: const Text('Select detection model'),
          items: models.map((model) {
            return DropdownMenuItem<String>(
              value: model.id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    model.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    model.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDetectorModelId = value;
            });
          },
        );
      },
    );
  }

  Widget _buildOcrModelDropdown() {
    return FutureBuilder<List<ONNXModel>>(
      future: widget.fastAlprService.modelManager.getDownloadedModels(ModelType.ocr),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final models = snapshot.data ?? [];

        if (models.isEmpty) {
          return Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No OCR Models Downloaded',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Download models to enable text recognition',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _openModelManager,
                    child: const Text('Download'),
                  ),
                ],
              ),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          value: _selectedOcrModelId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          hint: const Text('Select OCR model'),
          items: models.map((model) {
            return DropdownMenuItem<String>(
              value: model.id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    model.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    model.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedOcrModelId = value;
            });
          },
        );
      },
    );
  }

  Widget _buildCurrentStatus() {
    final config = widget.fastAlprService.getConfiguration();
    final hasModelsLoaded = config['has_models_loaded'] as bool? ?? false;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'Detection Model',
              config['detector_model']?.toString() ?? 'None',
              hasModelsLoaded,
            ),
            _buildStatusRow(
              'OCR Model',
              config['ocr_model']?.toString() ?? 'None',
              hasModelsLoaded,
            ),
            _buildStatusRow(
              'Available Detector Models',
              config['available_detector_models']?.toString() ?? '0',
              (config['available_detector_models'] as int? ?? 0) > 0,
            ),
            _buildStatusRow(
              'Available OCR Models',
              config['available_ocr_models']?.toString() ?? '0',
              (config['available_ocr_models'] as int? ?? 0) > 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.warning,
            size: 16,
            color: isGood ? Colors.green[600] : Colors.orange[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool _canApplySettings() {
    return _selectedDetectorModelId != null && _selectedOcrModelId != null;
  }

  void _openModelManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ModelManagementScreen(),
      ),
    ).then((_) {
      // Refresh the current selection when returning from model manager
      setState(() {
        _loadCurrentSelection();
      });
    });
  }

  Future<void> _applySettings() async {
    if (!_canApplySettings()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.fastAlprService.setModels(
        detectorModelId: _selectedDetectorModelId!,
        ocrModelId: _selectedOcrModelId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FastALPR models updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating models: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}