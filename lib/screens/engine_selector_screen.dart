import 'package:flutter/material.dart';
import '../services/multi_alpr_service.dart';
import '../models/plate_result.dart';
import 'package:path/path.dart' as path;

class EngineSelectorScreen extends StatefulWidget {
  const EngineSelectorScreen({super.key});

  @override
  State<EngineSelectorScreen> createState() => _EngineSelectorScreenState();
}

class _EngineSelectorScreenState extends State<EngineSelectorScreen> {
  final MultiALPRService _multiALPRService = MultiALPRService();
  bool _isInitializing = true;
  String _selectedEngine = '';
  Map<String, dynamic> _performanceInfo = {};
  Map<String, List<PlateResult>>? _comparisonResults;
  bool _isComparing = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _multiALPRService.initialize();
      _selectedEngine = _multiALPRService.selectedEngine;
      _performanceInfo = await _multiALPRService.getEnginePerformanceInfo();
    } catch (e) {
      print('Failed to initialize MultiALPR: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _selectEngine(String engineName) {
    setState(() {
      _selectedEngine = engineName;
      _multiALPRService.setEngine(engineName);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to: ${_multiALPRService.getEngineDescription(engineName)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _runComparison() async {
    // For demo, we'll use a sample image path
    // In real implementation, you'd let user select an image
    final sampleImagePath = '/path/to/sample/image.jpg';
    
    setState(() {
      _isComparing = true;
      _comparisonResults = null;
    });

    try {
      final results = await _multiALPRService.compareAllEngines(
        imagePath: sampleImagePath,
      );
      
      setState(() {
        _comparisonResults = results;
      });
    } catch (e) {
      print('Comparison failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comparison failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isComparing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ALPR Engine Selector'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEngineSelectionSection(),
                  const SizedBox(height: 24),
                  _buildPerformanceInfoSection(),
                  const SizedBox(height: 24),
                  _buildComparisonSection(),
                  if (_comparisonResults != null) ...[
                    const SizedBox(height: 24),
                    _buildComparisonResults(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEngineSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select ALPR Engine',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...(_multiALPRService.availableEngines.map((engine) {
              final isSelected = engine == _selectedEngine;
              final description = _multiALPRService.getEngineDescription(engine);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                ),
                child: ListTile(
                  title: Text(
                    _getEngineDisplayName(engine),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  subtitle: Text(description),
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
                  trailing: engine == 'fast_plate_ocr'
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'FREE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  onTap: () => _selectEngine(engine),
                ),
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance Comparison',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Engine', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Speed', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Accuracy', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ..._performanceInfo.entries.map((entry) {
                  final engineName = entry.key;
                  final info = entry.value as Map<String, dynamic>;
                  
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(_getEngineDisplayName(engineName)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(info['speed'] ?? 'Unknown'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(info['accuracy'] ?? 'Unknown'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(info['cost'] ?? 'Unknown'),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compare,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Engine Comparison',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Compare results from all available engines on the same image to see which performs best for your use case.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isComparing ? null : _runComparison,
                icon: _isComparing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isComparing ? 'Running Comparison...' : 'Run Comparison Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonResults() {
    if (_comparisonResults == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assessment,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comparison Results',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._comparisonResults!.entries.map((entry) {
              final engineName = entry.key;
              final results = entry.value;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getEngineDisplayName(engineName),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (results.isEmpty)
                      Text(
                        'No plates detected',
                        style: TextStyle(color: Colors.grey.shade600),
                      )
                    else
                      Column(
                        children: results.map((result) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    result.plateNumber,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${result.confidence.toStringAsFixed(1)}%'),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _getEngineDisplayName(String engineName) {
    switch (engineName) {
      case 'fast_plate_ocr':
        return 'Fast Plate OCR';
      case 'opencv_tesseract':
        return 'OpenCV + Tesseract';
      default:
        return engineName;
    }
  }
}