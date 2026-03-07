import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/farm_diary.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/farm_diary_provider.dart';
import 'farm_diary_detail_screen.dart';
import 'farm_diary_form_screen.dart';

class FarmDiaryListScreen extends StatefulWidget {
  final String? farmPlotId;

  const FarmDiaryListScreen({super.key, this.farmPlotId});

  @override
  State<FarmDiaryListScreen> createState() => _FarmDiaryListScreenState();
}

class _FarmDiaryListScreenState extends State<FarmDiaryListScreen> {
  late FarmDiaryProvider _provider;
  String _selectedActivityFilter = 'all';
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> activityTypes = [
    'all',
    'watering',
    'fertilizing',
    'pest_control',
    'harvesting',
    'pruning',
    'weeding',
    'inspection',
    'disease_treatment',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _provider = AppProviders.farmDiary;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEntries());
  }

  void _loadEntries() {
    _provider.loadDiaryEntries(
      farmPlotId: widget.farmPlotId,
      startDate: _startDate,
      endDate: _endDate,
      activityType: _selectedActivityFilter == 'all'
          ? null
          : _selectedActivityFilter,
    );
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Diary Entries',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Activity Type:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: activityTypes.map((activity) {
                    final isSelected = _selectedActivityFilter == activity;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(activity.replaceAll('_', ' ')),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedActivityFilter = activity;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Date Range:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                      child: Text(
                        _startDate != null
                            ? DateFormat('MMM dd, yyyy').format(_startDate!)
                            : 'Start Date',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                      child: Text(
                        _endDate != null
                            ? DateFormat('MMM dd, yyyy').format(_endDate!)
                            : 'End Date',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedActivityFilter = 'all';
                          _startDate = null;
                          _endDate = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _loadEntries();
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Diary'),
        elevation: 0,
        actions: [
          Consumer<FarmDiaryProvider>(
            builder: (context, provider, child) {
              if (provider.hasPendingEntries) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Tooltip(
                      message: '${provider.pendingEntriesCount} pending changes',
                      child: IconButton(
                        icon: Badge(
                          label: Text(provider.pendingEntriesCount.toString()),
                          child: const Icon(Icons.cloud_off),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Syncing offline entries...'),
                            ),
                          );
                          provider.syncOfflineEntries();
                        },
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (query) {
                      setState(() => _searchQuery = query);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search diary entries...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _openFilterBottomSheet,
                  icon: const Icon(Icons.tune),
                  label: const Text('Filter'),
                ),
              ],
            ),
          ),
          // Diary Entries List
          Expanded(
            child: Consumer<FarmDiaryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: ${provider.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadEntries,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (provider.diaryEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text('No diary entries yet'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.navigateToFarmDiaryForm(
                            farmPlotId: widget.farmPlotId,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Entry'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: provider.diaryEntries.length,
                  itemBuilder: (context, index) {
                    final entry = provider.diaryEntries[index];
                    return _buildDiaryCard(entry);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'farm_diary_fab',
        onPressed: () => context.navigateToFarmDiaryForm(
          farmPlotId: widget.farmPlotId,
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }

  Widget _buildDiaryCard(FarmDiary entry) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getActivityColor(entry.activityType),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getActivityIcon(entry.activityType),
            color: Colors.white,
          ),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy • HH:mm').format(entry.diaryDate),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            if (entry.syncStatus != 'synced')
              Chip(
                label: Text(entry.syncStatus),
                backgroundColor: entry.syncStatus == 'pending'
                    ? Colors.orange[100]
                    : Colors.red[100],
                labelStyle: TextStyle(
                  fontSize: 10,
                  color: entry.syncStatus == 'pending'
                      ? Colors.orange[900]
                      : Colors.red[900],
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => context.navigateToFarmDiaryDetail(entryId: entry.id),
      ),
    );
  }

  Color _getActivityColor(String activityType) {
    switch (activityType) {
      case 'watering':
        return Colors.blue;
      case 'fertilizing':
        return Colors.brown;
      case 'pest_control':
        return Colors.red;
      case 'harvesting':
        return Colors.green;
      case 'pruning':
        return Colors.purple;
      case 'weeding':
        return Colors.orange;
      case 'inspection':
        return Colors.teal;
      case 'disease_treatment':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'watering':
        return Icons.water_drop;
      case 'fertilizing':
        return Icons.healing;
      case 'pest_control':
        return Icons.bug_report;
      case 'harvesting':
        return Icons.agriculture;
      case 'pruning':
        return Icons.cut;
      case 'weeding':
        return Icons.remove;
      case 'inspection':
        return Icons.checklist;
      case 'disease_treatment':
        return Icons.medical_services;
      default:
        return Icons.note;
    }
  }
}
