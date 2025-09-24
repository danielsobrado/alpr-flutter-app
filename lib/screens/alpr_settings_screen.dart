import 'package:flutter/material.dart';
import '../core/alpr_config.dart';
import '../services/alpr_service_factory.dart';
import '../services/fastalpr_service.dart';
import 'fastalpr_settings_screen.dart';

class ALPRSettingsScreen extends StatefulWidget {
  const ALPRSettingsScreen({super.key});

  @override
  State<ALPRSettingsScreen> createState() => _ALPRSettingsScreenState();
}

class _ALPRSettingsScreenState extends State<ALPRSettingsScreen> {
  ALPRProvider _selectedProvider = ALPRConfig.currentProvider;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ALPR Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'License Plate Recognition Provider',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the ALPR engine for license plate detection and recognition.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Provider selection
            ...ALPRProvider.values.map((provider) => _buildProviderTile(provider)),

            const Spacer(),

            // Action buttons
            Row(
              children: [
                if (_selectedProvider == ALPRProvider.fastalpr) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openFastALPRSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('Model Settings'),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _applySettings,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Apply Settings'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Provider comparison
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Provider Comparison',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildComparisonTable(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTile(ALPRProvider provider) {
    final isSelected = _selectedProvider == provider;
    final capabilities = ALPRConfig.getProviderCapabilities(provider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: RadioListTile<ALPRProvider>(
        value: provider,
        groupValue: _selectedProvider,
        onChanged: (ALPRProvider? value) {
          if (value != null) {
            setState(() {
              _selectedProvider = value;
            });
          }
        },
        title: Text(
          ALPRConfig.getProviderDisplayName(provider),
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(ALPRConfig.getProviderDescription(provider)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: capabilities.entries
                  .where((entry) => entry.value)
                  .map((entry) => Chip(
                        label: Text(
                          _formatCapabilityName(entry.key),
                          style: const TextStyle(fontSize: 10),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildComparisonTable() {
    final allCapabilities = ALPRConfig.getProviderCapabilities(ALPRProvider.fastalpr).keys.toList();

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Feature', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'OpenALPR',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'FastALPR',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),

        // Feature rows
        ...allCapabilities.map((capability) => TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_formatCapabilityName(capability)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                ALPRConfig.getProviderCapabilities(ALPRProvider.fastalpr)[capability] == true
                    ? Icons.check
                    : Icons.close,
                color: ALPRConfig.getProviderCapabilities(ALPRProvider.fastalpr)[capability] == true
                    ? Colors.green
                    : Colors.red,
                size: 16,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                ALPRConfig.getProviderCapabilities(ALPRProvider.fastalpr)[capability] == true
                    ? Icons.check
                    : Icons.close,
                color: ALPRConfig.getProviderCapabilities(ALPRProvider.fastalpr)[capability] == true
                    ? Colors.green
                    : Colors.red,
                size: 16,
              ),
            ),
          ],
        )),
      ],
    );
  }

  String _formatCapabilityName(String capability) {
    return capability
        .split('_')
        .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _applySettings() async {
    if (_selectedProvider == ALPRConfig.currentProvider) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Switch to new provider
      await ALPRServiceFactory.switchProvider(_selectedProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Switched to ${ALPRConfig.getProviderDisplayName(_selectedProvider)}',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error switching provider: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Reset to current provider
        setState(() {
          _selectedProvider = ALPRConfig.currentProvider;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openFastALPRSettings() {
    final currentService = ALPRServiceFactory.getCurrentService();
    if (currentService is FastALPRService) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FastALPRSettingsScreen(
            fastAlprService: currentService,
          ),
        ),
      );
    }
  }
}