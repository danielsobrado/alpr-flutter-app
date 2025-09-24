import 'package:flutter/material.dart';
import '../core/alpr_config.dart';
import '../services/alpr_service_factory.dart';
import 'home_screen.dart';

class InitialProviderSelectionScreen extends StatefulWidget {
  const InitialProviderSelectionScreen({super.key});

  @override
  State<InitialProviderSelectionScreen> createState() => _InitialProviderSelectionScreenState();
}

class _InitialProviderSelectionScreenState extends State<InitialProviderSelectionScreen> {
  ALPRProvider? _selectedProvider;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Title
              Text(
                'ALPR Prototype',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Choose License Plate Recognition Engine',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 40),

              // Provider Cards
              Expanded(
                child: ListView(
                  children: ALPRProvider.values.map((provider) => _buildProviderCard(provider)).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedProvider != null && !_isLoading ? _continueToApp : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Start Testing',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Note
              Text(
                'This is a prototype for testing different ALPR solutions. You can change providers later in settings.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(ALPRProvider provider) {
    final isSelected = _selectedProvider == provider;
    final capabilities = ALPRConfig.getProviderCapabilities(provider);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProvider = provider;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
              : Colors.white,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[400],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ALPRConfig.getProviderDisplayName(provider),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ALPRConfig.getProviderDescription(provider),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (provider == ALPRProvider.fastalpr)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'BETA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Capabilities
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _getDisplayCapabilities(capabilities)
                  .map((capability) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          capability,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[700],
                          ),
                        ),
                      ))
                  .toList(),
            ),

            if (provider == ALPRProvider.fastalpr) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Currently in mock mode - returns test data for development',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _getDisplayCapabilities(Map<String, bool> capabilities) {
    return capabilities.entries
        .where((entry) => entry.value)
        .map((entry) => _formatCapabilityName(entry.key))
        .toList();
  }

  String _formatCapabilityName(String capability) {
    final formatted = capability
        .split('_')
        .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
        .join(' ');

    // Shorter names for better display
    return formatted
        .replaceAll('Local Processing', 'Local')
        .replaceAll('Real Time', 'Real-time')
        .replaceAll('Region Specific', 'Regions')
        .replaceAll('Yolo Detection', 'YOLO')
        .replaceAll('Advanced Ocr', 'Advanced OCR')
        .replaceAll('Confidence Scores', 'Confidence')
        .replaceAll('Bounding Boxes', 'Bounding Box');
  }

  Future<void> _continueToApp() async {
    if (_selectedProvider == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize the selected provider
      await ALPRServiceFactory.switchProvider(_selectedProvider!);

      if (mounted) {
        // Navigate to main app
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing ${ALPRConfig.getProviderDisplayName(_selectedProvider!)}: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}