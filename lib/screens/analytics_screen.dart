import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/analytics_service.dart';
import '../models/plate_detection.dart';
import '../models/plate_note.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();
  late TabController _tabController;

  // Filters
  DateTime? _startDate;
  DateTime? _endDate;
  String _plateFilter = '';
  String _selectedSortBy = 'detections'; // detections, last_seen, first_seen

  // Data
  List<PlateAnalytics> _allAnalytics = [];
  List<PlateAnalytics> _filteredAnalytics = [];
  Map<String, dynamic> _totalStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _analyticsService.initialize();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _allAnalytics = _analyticsService.getAllPlateAnalytics();
      _totalStats = _analyticsService.getTotalStatistics();
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredAnalytics = _allAnalytics.where((analytics) {
      // Plate number filter
      if (_plateFilter.isNotEmpty &&
          !analytics.plateNumber.toUpperCase().contains(_plateFilter.toUpperCase())) {
        return false;
      }

      // Date range filter
      if (_startDate != null && analytics.lastSeen.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && analytics.firstSeen.isAfter(_endDate!.add(const Duration(days: 1)))) {
        return false;
      }

      return true;
    }).toList();

    // Apply sorting
    switch (_selectedSortBy) {
      case 'detections':
        _filteredAnalytics.sort((a, b) => b.totalDetections.compareTo(a.totalDetections));
        break;
      case 'last_seen':
        _filteredAnalytics.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
        break;
      case 'first_seen':
        _filteredAnalytics.sort((a, b) => a.firstSeen.compareTo(b.firstSeen));
        break;
      case 'confidence':
        _filteredAnalytics.sort((a, b) => b.averageConfidence.compareTo(a.averageConfidence));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plate Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Overview'),
            Tab(icon: Icon(Icons.list), text: 'Plates'),
            Tab(icon: Icon(Icons.filter_list), text: 'Filters'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showClearDataDialog(),
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All Data',
          ),
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPlatesTab(),
          _buildFiltersTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detection Statistics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildStatsCards(),
          const SizedBox(height: 24),
          Text(
            'Top Plates',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildTopPlatesList(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Detections',
          _totalStats['totalDetections']?.toString() ?? '0',
          Icons.camera_alt,
          Colors.blue,
        ),
        _buildStatCard(
          'Unique Plates',
          _totalStats['uniquePlates']?.toString() ?? '0',
          Icons.local_parking,
          Colors.green,
        ),
        _buildStatCard(
          'Today',
          _totalStats['todayDetections']?.toString() ?? '0',
          Icons.today,
          Colors.orange,
        ),
        _buildStatCard(
          'This Week',
          _totalStats['thisWeekDetections']?.toString() ?? '0',
          Icons.date_range,
          Colors.purple,
        ),
        _buildStatCard(
          'Total Notes',
          _totalStats['totalNotes']?.toString() ?? '0',
          Icons.note,
          Colors.red,
        ),
        _buildStatCard(
          'Avg/Day',
          (_totalStats['averageDetectionsPerDay'] as double? ?? 0.0).toStringAsFixed(1),
          Icons.trending_up,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPlatesList() {
    final topPlates = _filteredAnalytics.take(5).toList();
    
    if (topPlates.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No plate data available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Start taking photos to see analytics here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: topPlates.map((analytics) => _buildPlateAnalyticsCard(analytics)).toList(),
    );
  }

  Widget _buildPlatesTab() {
    return Column(
      children: [
        // Search and sort controls
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search plates...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _plateFilter = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedSortBy,
                onChanged: (value) {
                  setState(() {
                    _selectedSortBy = value!;
                    _applyFilters();
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'detections', child: Text('By Detections')),
                  DropdownMenuItem(value: 'last_seen', child: Text('By Last Seen')),
                  DropdownMenuItem(value: 'first_seen', child: Text('By First Seen')),
                  DropdownMenuItem(value: 'confidence', child: Text('By Confidence')),
                ],
              ),
            ],
          ),
        ),
        // Plates list
        Expanded(
          child: _filteredAnalytics.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No plates found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredAnalytics.length,
                  itemBuilder: (context, index) {
                    final analytics = _filteredAnalytics[index];
                    return _buildPlateAnalyticsCard(analytics);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFiltersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date Range Filter',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => _selectDate(context, isStartDate: true),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From Date',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _startDate != null
                                ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                : 'Select start date',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => _selectDate(context, isStartDate: false),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'To Date',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _endDate != null
                                ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                : 'Select end date',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () {
                  _applyFilters();
                  _tabController.animateTo(1); // Go to plates tab
                },
                icon: const Icon(Icons.check),
                label: const Text('Apply Filters'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Quick Filters',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              FilterChip(
                label: const Text('Today'),
                onSelected: (selected) => _setQuickFilter('today'),
              ),
              FilterChip(
                label: const Text('This Week'),
                onSelected: (selected) => _setQuickFilter('week'),
              ),
              FilterChip(
                label: const Text('This Month'),
                onSelected: (selected) => _setQuickFilter('month'),
              ),
              FilterChip(
                label: const Text('Last 7 Days'),
                onSelected: (selected) => _setQuickFilter('7days'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlateAnalyticsCard(PlateAnalytics analytics) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPlateDetails(analytics),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    analytics.plateNumber,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${analytics.totalDetections} detections',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last seen: ${DateFormat('MMM dd, HH:mm').format(analytics.lastSeen)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Avg confidence: ${analytics.averageConfidence.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  if (analytics.totalNotes > 0) ...[
                    Icon(
                      Icons.note,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${analytics.totalNotes} notes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _applyFilters();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _plateFilter = '';
      _applyFilters();
    });
  }

  void _setQuickFilter(String filter) {
    final now = DateTime.now();
    setState(() {
      switch (filter) {
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = now;
          break;
        case 'week':
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _endDate = now;
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case '7days':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
      }
      _applyFilters();
    });
  }

  void _showPlateDetails(PlateAnalytics analytics) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: _buildPlateDetailContent(analytics, scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlateDetailContent(PlateAnalytics analytics, ScrollController scrollController) {
    final notes = _analyticsService.getNotesForPlate(analytics.plateNumber);
    
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            analytics.plateNumber,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          
          // Statistics Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _buildDetailStatCard('Total Detections', analytics.totalDetections.toString(), Icons.camera_alt),
              _buildDetailStatCard('Avg Confidence', '${analytics.averageConfidence.toStringAsFixed(1)}%', Icons.trending_up),
              _buildDetailStatCard('Most Common Hour', analytics.mostCommonHour, Icons.access_time),
              _buildDetailStatCard('Most Common Day', analytics.mostCommonDay, Icons.calendar_today),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Timeline
          Text(
            'Timeline',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('First seen: ${DateFormat('MMM dd, yyyy HH:mm').format(analytics.firstSeen)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.stop, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Last seen: ${DateFormat('MMM dd, yyyy HH:mm').format(analytics.lastSeen)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule),
                      const SizedBox(width: 8),
                      Text('Duration: ${analytics.timeBetweenFirstAndLast.inDays} days'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Notes (${notes.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...notes.map((note) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.note,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(note.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Analytics Data'),
        content: const Text(
          'This will permanently delete all plate detection history and analytics data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await _analyticsService.clearAllData();
              Navigator.of(context).pop();
              _refreshData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Analytics data cleared')),
                );
              }
            },
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }
}