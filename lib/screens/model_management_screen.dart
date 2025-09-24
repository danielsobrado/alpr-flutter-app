import 'package:flutter/material.dart';
import '../services/model_manager.dart';

class ModelManagementScreen extends StatefulWidget {
  const ModelManagementScreen({super.key});

  @override
  State<ModelManagementScreen> createState() => _ModelManagementScreenState();
}

class _ModelManagementScreenState extends State<ModelManagementScreen>
    with SingleTickerProviderStateMixin {
  final ModelManager _modelManager = ModelManager();
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeModels();
    _modelManager.addListener(_onModelManagerUpdate);
  }

  @override
  void dispose() {
    _modelManager.removeListener(_onModelManagerUpdate);
    _tabController.dispose();
    super.dispose();
  }

  void _onModelManagerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeModels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _modelManager.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing models: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ONNX Models'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.visibility),
              text: 'Detection Models',
            ),
            Tab(
              icon: Icon(Icons.text_fields),
              text: 'OCR Models',
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    const Text('Clear All Models'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Refresh Status'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Storage info
                _buildStorageInfo(),

                // Model tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildModelList(ModelType.detector),
                      _buildModelList(ModelType.ocr),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStorageInfo() {
    return FutureBuilder<double>(
      future: _modelManager.getTotalStorageUsedMB(),
      builder: (context, snapshot) {
        final storageUsed = snapshot.data ?? 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(Icons.storage, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Storage Used: ${storageUsed.toStringAsFixed(1)} MB',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: storageUsed > 0 ? _showClearAllDialog : null,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelList(ModelType modelType) {
    final models = modelType == ModelType.detector
        ? _modelManager.detectorModels
        : _modelManager.ocrModels;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: models.length,
      itemBuilder: (context, index) => _buildModelCard(models[index]),
    );
  }

  Widget _buildModelCard(ONNXModel model) {
    final progress = _modelManager.downloadProgress[model.id];
    final isDownloaded = progress?.status == ModelDownloadStatus.downloaded;
    final isDownloading = progress?.status == ModelDownloadStatus.downloading;
    final hasError = progress?.status == ModelDownloadStatus.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusIcon(progress?.status ?? ModelDownloadStatus.notDownloaded),
              ],
            ),

            const SizedBox(height: 12),

            // Metadata chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _buildMetadataChips(model.metadata),
            ),

            const SizedBox(height: 12),

            // File info
            Row(
              children: [
                Icon(Icons.description, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  model.filename,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  '${model.fileSizeMB} MB',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Progress bar (if downloading)
            if (isDownloading && progress != null) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Downloading...',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${progress.progressPercent}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],

            // Error message
            if (hasError && progress?.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        progress!.error!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                if (isDownloaded) ...[
                  ElevatedButton.icon(
                    onPressed: () => _deleteModel(model),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      backgroundColor: Colors.red[50],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showModelInfo(model),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Info'),
                  ),
                ] else if (isDownloading) ...[
                  ElevatedButton.icon(
                    onPressed: null, // TODO: Implement cancel
                    icon: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    label: const Text('Downloading...'),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () => _downloadModel(model),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ModelDownloadStatus status) {
    switch (status) {
      case ModelDownloadStatus.downloaded:
        return Icon(Icons.check_circle, color: Colors.green[600]);
      case ModelDownloadStatus.downloading:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ModelDownloadStatus.error:
        return Icon(Icons.error, color: Colors.red[600]);
      case ModelDownloadStatus.notDownloaded:
        return Icon(Icons.download, color: Colors.grey[600]);
    }
  }

  List<Widget> _buildMetadataChips(Map<String, dynamic> metadata) {
    final chips = <Widget>[];

    metadata.forEach((key, value) {
      if (key == 'inputSize' && value is List) {
        chips.add(_buildChip('${value[0]}x${value[1]}', Icons.aspect_ratio));
      } else if (key == 'accuracy') {
        chips.add(_buildChip(value.toString(), Icons.star));
      } else if (key == 'speed') {
        chips.add(_buildChip(value.toString(), Icons.speed));
      } else if (key == 'architecture') {
        chips.add(_buildChip(value.toString(), Icons.architecture));
      } else if (key == 'regions' && value is List) {
        chips.add(_buildChip('${value.length} regions', Icons.public));
      }
    });

    return chips;
  }

  Widget _buildChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _downloadModel(ONNXModel model) async {
    try {
      await _modelManager.downloadModel(
        model.id,
        onProgress: (progress) {
          // Progress is automatically handled by ModelManager listener
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.name} downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading ${model.name}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteModel(ONNXModel model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text('Are you sure you want to delete ${model.name}?\n\nThis will free up ${model.fileSizeMB} MB of storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red[600])),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _modelManager.deleteModel(model.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${model.name} deleted successfully!'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting ${model.name}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showModelInfo(ONNXModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(model.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(model.description),
            const SizedBox(height: 16),
            Text('File: ${model.filename}', style: const TextStyle(fontFamily: 'monospace')),
            Text('Size: ${model.fileSizeMB} MB'),
            Text('Type: ${model.type.name.toUpperCase()}'),
            const SizedBox(height: 12),
            const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...model.metadata.entries.map((e) => Text('• ${e.key}: ${e.value}')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Models'),
        content: const Text('Are you sure you want to delete all downloaded models?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear All', style: TextStyle(color: Colors.red[600])),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _modelManager.clearAllModels();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All models cleared successfully!'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing models: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'refresh':
        _initializeModels();
        break;
    }
  }
}