import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/farm_diary.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/farm_diary_provider.dart';
import '../../../services/farmer_service.dart';
import '../../../models/farm_plot.dart';

class FarmDiaryFormScreen extends StatefulWidget {
  final String? farmPlotId;
  final FarmDiary? entry;

  const FarmDiaryFormScreen({super.key, this.farmPlotId, this.entry});

  @override
  State<FarmDiaryFormScreen> createState() => _FarmDiaryFormScreenState();
}

class _FarmDiaryFormScreenState extends State<FarmDiaryFormScreen> {
  late FarmDiaryProvider _provider;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _fertiliserController;
  late TextEditingController _pesticideController;
  late TextEditingController _waterQuantityController;
  late TextEditingController _diseaseSymptomController;
  late TextEditingController _pestPresenceController;

  String _selectedActivityType = 'other';
  DateTime _selectedDate = DateTime.now();
  String _selectedWeatherCondition = 'unknown';
  double? _temperature;
  double? _humidity;
  double? _rainfall;
  String _plantHealth = 'good';
  List<String> _tags = [];
  bool _isLoading = false;

  // Plot selection
  final FarmerService _farmerService = FarmerService();
  List<FarmPlot> _availablePlots = [];
  String? _selectedFarmPlotId;
  bool _isLoadingPlots = false;

  final List<String> activityTypes = [
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

  final List<String> weatherConditions = [
    'sunny',
    'cloudy',
    'rainy',
    'windy',
    'stormy',
    'unknown',
  ];

  final List<String> plantHealthOptions = ['excellent', 'good', 'fair', 'poor'];

  @override
  void initState() {
    super.initState();
    _provider = AppProviders.farmDiary;

    if (widget.entry != null) {
      _titleController = TextEditingController(text: widget.entry!.title);
      _descriptionController = TextEditingController(
        text: widget.entry!.description,
      );
      _notesController = TextEditingController(text: widget.entry!.notes);
      _fertiliserController = TextEditingController(
        text: widget.entry!.inputs.fertilizer ?? '',
      );
      _pesticideController = TextEditingController(
        text: widget.entry!.inputs.pesticide ?? '',
      );
      _waterQuantityController = TextEditingController(
        text: widget.entry!.inputs.waterQuantity?.toString() ?? '',
      );
      _diseaseSymptomController = TextEditingController(
        text: widget.entry!.observations.diseaseSymptoms ?? '',
      );
      _pestPresenceController = TextEditingController(
        text: widget.entry!.observations.pestPresence ?? '',
      );
      _selectedActivityType = widget.entry!.activityType;
      _selectedDate = widget.entry!.diaryDate;
      _selectedWeatherCondition = widget.entry!.weather.condition;
      _temperature = widget.entry!.weather.temperature;
      _humidity = widget.entry!.weather.humidity;
      _rainfall = widget.entry!.weather.rainfall;
      _plantHealth = widget.entry!.observations.plantHealth;
      _tags = List.from(widget.entry!.tags);
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _notesController = TextEditingController();
      _fertiliserController = TextEditingController();
      _pesticideController = TextEditingController();
      _waterQuantityController = TextEditingController();
      _diseaseSymptomController = TextEditingController();
      _pestPresenceController = TextEditingController();
    }

    _selectedFarmPlotId = widget.farmPlotId ?? widget.entry?.farmPlotId;
    if (_selectedFarmPlotId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAvailablePlots());
    }
  }

  Future<void> _loadAvailablePlots() async {
    setState(() => _isLoadingPlots = true);
    try {
      final plots = await _farmerService.fetchPlots();
      setState(() {
        _availablePlots = plots;
      });
    } catch (e) {
      print('Error loading plots: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlots = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _fertiliserController.dispose();
    _pesticideController.dispose();
    _waterQuantityController.dispose();
    _diseaseSymptomController.dispose();
    _pestPresenceController.dispose();
    super.dispose();
  }

  void _saveDiaryEntry() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    if (_selectedFarmPlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a farm plot')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final entry = FarmDiary(
      id: widget.entry?.id ?? '',
      title: _titleController.text,
      description: _descriptionController.text,
      activityType: _selectedActivityType,
      diaryDate: _selectedDate,
      farmPlotId: _selectedFarmPlotId!,
      weather: Weather(
        condition: _selectedWeatherCondition,
        temperature: _temperature,
        humidity: _humidity,
        rainfall: _rainfall,
      ),
      observations: Observations(
        plantHealth: _plantHealth,
        diseaseSymptoms: _diseaseSymptomController.text.isEmpty
            ? null
            : _diseaseSymptomController.text,
        pestPresence: _pestPresenceController.text.isEmpty
            ? null
            : _pestPresenceController.text,
      ),
      inputs: Inputs(
        fertilizer: _fertiliserController.text.isEmpty
            ? null
            : _fertiliserController.text,
        pesticide: _pesticideController.text.isEmpty
            ? null
            : _pesticideController.text,
        waterQuantity: _waterQuantityController.text.isEmpty
            ? null
            : double.tryParse(_waterQuantityController.text),
      ),
      notes: _notesController.text,
      tags: _tags,
    );

    try {
      FarmDiary? saved;
      if (widget.entry != null) {
        saved = await _provider.updateDiaryEntry(widget.entry!.id, entry);
      } else {
        saved = await _provider.createDiaryEntry(entry);
      }

      if (saved != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.entry != null ? 'Entry updated' : 'Entry created',
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_provider.error ?? 'Failed to save entry')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry != null ? 'Edit Entry' : 'New Diary Entry'),
        elevation: 0,
      ),
      body: _isLoadingPlots
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.farmPlotId == null && widget.entry == null) ...[
                    const Text(
                      'Select Farm Plot',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedFarmPlotId,
                      hint: const Text('Select a plot'),
                      items: _availablePlots
                          .map((plot) => DropdownMenuItem(
                                value: plot.id,
                                child: Text('${plot.name} (${plot.crop})'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedFarmPlotId = value);
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Title
                  _buildTextField(
                    'Title ',
                    _titleController,
                    hint: 'e.g., Watering Session',
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),
                  // Activity Type
                  _buildActivityTypeDropdown(),
                  const SizedBox(height: 16),
                  // Date and Time
                  _buildDateField(),
                  const SizedBox(height: 16),
                  // Description
                  _buildTextField(
                    'Description',
                    _descriptionController,
                    hint: 'Describe what you did...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  // Weather Section
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Weather Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildWeatherConditionDropdown(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Temperature (°C)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            _temperature = double.tryParse(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Humidity (%)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            _humidity = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Rainfall (mm)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      _rainfall = double.tryParse(value);
                    },
                  ),
                  const SizedBox(height: 24),
                  // Observations Section
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Observations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPlantHealthDropdown(),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Disease Symptoms',
                    _diseaseSymptomController,
                    hint: 'Describe any disease symptoms...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Pest Presence',
                    _pestPresenceController,
                    hint: 'Describe any pests found...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  // Inputs Section
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Inputs Used',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Fertilizer',
                    _fertiliserController,
                    hint: 'Type and amount of fertilizer used',
                    maxLines: 1,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Pesticide',
                    _pesticideController,
                    hint: 'Type and amount of pesticide used',
                    maxLines: 1,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Water Quantity (L)',
                    _waterQuantityController,
                    hint: 'Amount of water used in liters',
                    maxLines: 1,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  // Notes Section
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Additional Notes',
                    _notesController,
                    hint: 'Any other observations or notes...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveDiaryEntry,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        widget.entry != null ? 'Update Entry' : 'Save Entry',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String hint = '',
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity Type ',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _selectedActivityType,
          items: activityTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.replaceAll('_', ' ')),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedActivityType = value);
            }
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date & Time ',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedDate),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
                icon: const Icon(Icons.access_time),
                label: Text(DateFormat('HH:mm').format(_selectedDate)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherConditionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedWeatherCondition,
      items: weatherConditions
          .map(
            (condition) =>
                DropdownMenuItem(value: condition, child: Text(condition)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedWeatherCondition = value);
        }
      },
      decoration: InputDecoration(
        labelText: 'Weather Condition',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildPlantHealthDropdown() {
    return DropdownButtonFormField<String>(
      value: _plantHealth,
      items: plantHealthOptions
          .map((health) => DropdownMenuItem(value: health, child: Text(health)))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _plantHealth = value);
        }
      },
      decoration: InputDecoration(
        labelText: 'Plant Health Status',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
