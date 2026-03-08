import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/farm_diary.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/farm_diary_provider.dart';
import 'farm_diary_form_screen.dart';

class FarmDiaryDetailScreen extends StatefulWidget {
  final String entryId;

  const FarmDiaryDetailScreen({super.key, required this.entryId});

  @override
  State<FarmDiaryDetailScreen> createState() => _FarmDiaryDetailScreenState();
}

class _FarmDiaryDetailScreenState extends State<FarmDiaryDetailScreen> {
  late FarmDiaryProvider _provider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _provider = AppProviders.farmDiary;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEntry());
  }

  void _loadEntry() {
    _provider.loadDiaryEntry(widget.entryId).then((_) {
      setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary Entry'),
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () {
                  final entry = Provider.of<FarmDiaryProvider>(context, listen: false).selectedEntry;
                  if (entry != null) {
                    context.navigateToFarmDiaryForm(entry: entry);
                  }
                },
                child: const Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () => _showDeleteDialog(),
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<FarmDiaryProvider>(
        builder: (context, provider, child) {
          if (_isLoading || provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.selectedEntry == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Entry not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            child: _buildDetailContent(provider.selectedEntry!),
          );
        },
      ),
    );
  }

  Widget _buildDetailContent(FarmDiary entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          color: Colors.greenAccent[100],
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          entry.activityType.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • HH:mm').format(entry.diaryDate),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              if (entry.syncStatus != 'synced')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Chip(
                    label: Text(entry.syncStatus),
                    backgroundColor: entry.syncStatus == 'pending'
                        ? Colors.orange[100]
                        : Colors.red[100],
                  ),
                ),
            ],
          ),
        ),
        // Description
        if (entry.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(entry.description),
              ],
            ),
          ),
        // Images
        if (entry.images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Images',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: entry.images
                        .map(
                          (image) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                image.url,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        // Weather Information
        if (entry.weather.temperature != null ||
            entry.weather.humidity != null ||
            entry.weather.rainfall != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weather',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.weather.temperature != null)
                        Text(
                          'Temperature: ${entry.weather.temperature}°C',
                          style: const TextStyle(fontSize: 14),
                        ),
                      if (entry.weather.humidity != null)
                        Text(
                          'Humidity: ${entry.weather.humidity}%',
                          style: const TextStyle(fontSize: 14),
                        ),
                      if (entry.weather.rainfall != null)
                        Text(
                          'Rainfall: ${entry.weather.rainfall} mm',
                          style: const TextStyle(fontSize: 14),
                        ),
                      if (entry.weather.condition != 'unknown')
                        Text(
                          'Condition: ${entry.weather.condition}',
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Observations
        if (entry.observations.plantHealth != 'good' ||
            entry.observations.diseaseSymptoms != null ||
            entry.observations.pestPresence != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Observations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plant Health: ${entry.observations.plantHealth}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (entry.observations.diseaseSymptoms != null)
                        Text(
                          'Disease Symptoms: ${entry.observations.diseaseSymptoms}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      if (entry.observations.pestPresence != null)
                        Text(
                          'Pest Presence: ${entry.observations.pestPresence}',
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Inputs
        if (entry.inputs.fertilizer != null ||
            entry.inputs.waterQuantity != null ||
            entry.inputs.pesticide != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inputs Used',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.inputs.fertilizer != null)
                        Text(
                          'Fertilizer: ${entry.inputs.fertilizer}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      if (entry.inputs.waterQuantity != null)
                        Text(
                          'Water: ${entry.inputs.waterQuantity} L',
                          style: const TextStyle(fontSize: 14),
                        ),
                      if (entry.inputs.pesticide != null)
                        Text(
                          'Pesticide: ${entry.inputs.pesticide}',
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Notes
        if (entry.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(entry.notes),
                ),
              ],
            ),
          ),
        // Meta Information
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Meta Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.createdAt != null)
                      Text(
                        'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(entry.createdAt!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    if (entry.updatedAt != null)
                      Text(
                        'Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(entry.updatedAt!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text(
          'Are you sure you want to delete this diary entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _provider.deleteDiaryEntry(widget.entryId).then((success) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Entry deleted')),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete entry')),
                  );
                }
              });
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
