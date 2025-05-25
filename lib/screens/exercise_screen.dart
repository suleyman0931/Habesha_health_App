import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/activity_model.dart';
import '../utils/storage.dart';
import '../localization/app_localizations.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import 'dart:async';

class ExerciseScreen extends StatefulWidget {
  @override
  _ExerciseScreenState createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen>
    with WidgetsBindingObserver {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<Activity> _todayExercises = [];
  List<Map<String, dynamic>> _predefinedExercises = [];
  bool _isLoading = true;
  String _selectedType = 'All';
  String _selectedExerciseType = 'Cardio';
  Map<String, Timer> _timers = {}; // To manage timers for each activity
  Map<String, int> _elapsedTimes =
      {}; // To store elapsed time for each activity

  final List<String> _exerciseTypes = [
    'Cardio',
    'Strength',
    'Flexibility',
    'Balance',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadExercises();
    _loadPredefinedExercises();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAllTimers();
    _nameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Save state when app is paused or detached
      _saveExerciseStates();
      _stopAllTimers();
    } else if (state == AppLifecycleState.resumed) {
      _loadExercises(); // Reload exercises to update timers/status
    }
  }

  Future<void> _saveExerciseStates() async {
    // Iterate through today's exercises and save their current state
    for (var exercise in _todayExercises) {
      await Storage.saveActivity(exercise); // Use the updated saveActivity
    }
  }

  Future<void> _loadPredefinedExercises() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/exercises.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        _predefinedExercises = List<Map<String, dynamic>>.from(
          jsonData['exercises'],
        );
      });
    } catch (e) {
      print('Error loading predefined exercises: $e');
    } finally {
      // Ensure categories are loaded even if initial file load fails
      if (_predefinedExercises.isEmpty) {
        // Populate with default categories if no predefined exercises are loaded
        // This is a simplified approach, ideally handle initial data better
        setState(() {}); // Trigger a rebuild to show default categories
      }
    }
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    _stopAllTimers(); // Stop existing timers before loading
    try {
      final exercises = await Storage.getTodayActivities();
      setState(() {
        _todayExercises =
            exercises
                .where((activity) => activity.title.startsWith('Exercise -'))
                .toList();
        _isLoading = false;
        _initializeTimers(); // Initialize timers for loaded exercises
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading exercises: $e')));
      setState(() => _isLoading = false);
    }
  }

  void _initializeTimers() {
    for (var exercise in _todayExercises) {
      if (exercise.status == 'In Progress') {
        _startTimer(exercise);
      }
      // Initialize elapsed time from stored value
      _elapsedTimes[exercise.title + exercise.time] =
          exercise.elapsedMilliseconds;
    }
  }

  void _startTimer(Activity exercise) {
    // Ensure only one timer runs at a time
    Activity? activeExercise; // Use nullable Activity
    for (var e in _todayExercises) {
      if (e.status == 'In Progress') {
        activeExercise = e;
        break;
      }
    }

    if (activeExercise != null && activeExercise.title != exercise.title) {
      // Another exercise is already in progress, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).translate('another_workout_in_progress'),
          ),
        ), // Need translation key
      );
      return; // Don't start the new timer
    }

    // Ensure previous timer is stopped if exists for this specific exercise
    _stopTimer(exercise);

    final exerciseKey = exercise.title + exercise.time;
    _timers[exerciseKey] = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        _elapsedTimes[exerciseKey] = (_elapsedTimes[exerciseKey] ?? 0) + 100;
        // Update the status in the activity object if needed (e.g., to Completed)
        // This will be handled when saving or on completion
      });
    });
    // Update status immediately to In Progress and save
    _updateExerciseStatus(exercise, 'In Progress', save: true);
  }

  void _pauseTimer(Activity exercise) {
    _stopTimer(exercise);
    // Update status to Not Completed and save
    _updateExerciseStatus(exercise, 'Not Completed', save: true);
  }

  void _stopTimer(Activity exercise) {
    final exerciseKey = exercise.title + exercise.time;
    _timers[exerciseKey]?.cancel();
    _timers.remove(exerciseKey);
    // State is saved when status changes to Paused/Completed or when app is paused
  }

  void _stopAllTimers() {
    _timers.values.forEach((timer) => timer.cancel());
    _timers.clear();
  }

  void _updateExerciseStatus(
    Activity exercise,
    String status, {
    bool save = false,
  }) {
    final index = _todayExercises.indexWhere(
      (e) => e.title == exercise.title && e.time == exercise.time,
    );
    if (index != -1) {
      // Create a new Activity object with updated status
      final updatedExercise = Activity(
        title: exercise.title,
        time: exercise.time,
        description: exercise.description,
        duration: exercise.duration,
        calories: exercise.calories,
        bpm: exercise.bpm,
        startTime: exercise.startTime,
        status: status,
        elapsedMilliseconds:
            _elapsedTimes[exercise.title + exercise.time] ??
            exercise.elapsedMilliseconds,
        date: exercise.date,
      );
      setState(() {
        _todayExercises[index] = updatedExercise;
      });
      if (save) {
        Storage.saveActivity(updatedExercise);
      }
    }
  }

  void _completeWorkout(Activity exercise) {
    _stopTimer(exercise);
    _updateExerciseStatus(exercise, 'Completed', save: true);
    // Optionally show a completion message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).translate('workout_completed'),
        ),
      ), // Need translation key
    );
  }

  void _showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(loc.translate('add_new_exercise')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: loc.translate('exercise_name'),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: loc.translate('description'),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _durationController,
                  decoration: InputDecoration(
                    labelText: loc.translate('duration'),
                    border: OutlineInputBorder(),
                    suffixText: 'minutes',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _caloriesController,
                  decoration: InputDecoration(
                    labelText: loc.translate('calories_burned'),
                    border: OutlineInputBorder(),
                    suffixText: 'calories',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedExerciseType,
                  decoration: InputDecoration(
                    labelText: loc.translate('type'),
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _exerciseTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedExerciseType = newValue);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _nameController.clear();
                _durationController.clear();
                _caloriesController.clear();
                _descriptionController.clear();
                Navigator.pop(context);
              },
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isEmpty ||
                    _durationController.text.isEmpty ||
                    _caloriesController.text.isEmpty ||
                    _descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.translate('please_fill_all_fields')),
                    ),
                  );
                  return;
                }

                try {
                  final newExercise = {
                    'name': _nameController.text,
                    'duration': int.parse(_durationController.text),
                    'calories': int.parse(_caloriesController.text),
                    'type': _selectedExerciseType,
                    'description': _descriptionController.text,
                  };

                  setState(() {
                    _predefinedExercises.add(newExercise);
                  });

                  // Optionally save the updated predefined exercises to a file
                  // This requires additional logic to write to the JSON file

                  _nameController.clear();
                  _durationController.clear();
                  _caloriesController.clear();
                  _descriptionController.clear();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        loc.translate('exercise_added_successfully'),
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving exercise: $e')),
                  );
                }
              },
              child: Text(loc.translate('save')),
            ),
          ],
        );
      },
    );
  }

  void _startWorkout(Map<String, dynamic> exercise) async {
    try {
      final now = DateTime.now();
      final time = DateFormat('h:mm a').format(
        DateTime(
          now.year,
          now.month,
          now.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
      );

      final activity = Activity(
        title: 'Exercise - ${exercise['name']}',
        time: time,
        description: exercise['description'] ?? '',
        duration: '${exercise['duration']} min', // Store as string for now
        calories: '${exercise['calories']} calories', // Store as string for now
        bpm: '', // BPM is not available from predefined data
        date: DateTime.now(), // Add current date
      );

      await Storage.saveActivity(activity);
      await _loadExercises(); // Reload today's exercises to show the new one

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('workout_started'),
          ),
        ), // Need translation key
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting workout: $e')));
    }
  }

  List<Map<String, dynamic>> get _filteredPredefinedExercises {
    if (_selectedType == 'All') {
      return _predefinedExercises;
    }
    return _predefinedExercises
        .where((exercise) => exercise['type'] == _selectedType)
        .toList();
  }

  List<String> get _predefinedExerciseTypes {
    final types =
        _predefinedExercises.map((e) => e['type'] as String).toSet().toList();
    return ['All', ...types];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.translate('exercise'),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF8B4513), // Adjust color as needed
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadExercises,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showAddExerciseDialog,
                          icon: Icon(Icons.add),
                          label: Text(
                            loc.translate('add_new_exercise'),
                            style: TextStyle(color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          loc.translate('predefined_exercises'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                _predefinedExerciseTypes.map((type) {
                                  return Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(type),
                                      selected: _selectedType == type,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _selectedType = type);
                                        }
                                      },
                                      backgroundColor: Colors.grey[200],
                                      selectedColor: Color(
                                        0xFF8B4513,
                                      ), // Adjust color as needed
                                      labelStyle: TextStyle(
                                        color:
                                            _selectedType == type
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        SizedBox(height: 16),
                        ..._filteredPredefinedExercises
                            .map(
                              (exercise) =>
                                  _buildPredefinedExerciseItem(exercise),
                            )
                            .toList(),
                        SizedBox(height: 24),
                        Text(
                          loc.translate(
                            'todays_activity',
                          ), // Changed from todays_exercises
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        if (_todayExercises
                            .isEmpty) // Check against _todayExercises
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                loc.translate(
                                  'no_exercises_today',
                                ), // Need translation key
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._todayExercises
                              .map((exercise) => _buildExerciseItem(exercise))
                              .toList(), // Use _todayExercises
                      ],
                    ),
                  ),
                ),
              ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, '/dashboard');
          if (index == 1) Navigator.pushNamed(context, '/meal');
          if (index == 3) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }

  Widget _buildPredefinedExerciseItem(Map<String, dynamic> exercise) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expanded for the main content
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  exercise['name'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['description'] ?? '',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text('${exercise['duration']} min'),
                          SizedBox(width: 16),
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text('${exercise['calories']} calories'),
                          SizedBox(width: 16),
                          Icon(
                            Icons.category,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(exercise['type'] ?? ''),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Trailing button
            Container(
              margin: EdgeInsets.only(right: 8, top: 8),
              child: ElevatedButton(
                onPressed: () => _startWorkout(exercise),
                child: Text(
                  AppLocalizations.of(context).translate('start_workout'),
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B4513),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size(0, 36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem(Activity exercise) {
    final exerciseKey = exercise.title + exercise.time;
    final totalDurationMinutes =
        int.tryParse(exercise.duration.replaceAll(' min', '')) ?? 0;
    final totalDurationMilliseconds = totalDurationMinutes * 60 * 1000;
    final elapsedMilliseconds =
        _elapsedTimes[exerciseKey] ??
        exercise.elapsedMilliseconds; // Use state elapsed time

    // Calculate remaining time for display
    final remainingMilliseconds =
        totalDurationMilliseconds - elapsedMilliseconds;
    final remainingMinutes = (remainingMilliseconds / (1000 * 60)).floor();
    final remainingSeconds =
        ((remainingMilliseconds % (1000 * 60)) / 1000).floor();

    String statusText = exercise.status;
    IconData statusIcon = Icons.info_outline;
    Color statusColor = Colors.grey;
    Widget actionButton;

    if (exercise.status == 'In Progress') {
      statusText = 'In Progress';
      statusIcon = Icons.timer;
      statusColor = Colors.blueAccent;
      actionButton = IconButton(
        icon: Icon(Icons.pause, color: Colors.orangeAccent),
        onPressed: () => _pauseTimer(exercise),
      );
    } else if (exercise.status == 'Completed') {
      statusText = 'Completed';
      statusIcon = Icons.check_circle_outline;
      statusColor = Colors.green;
      actionButton = SizedBox.shrink(); // No action button when completed
    } else {
      // Not Started or Paused
      statusText = 'Not Started'; // Or Paused
      statusIcon = Icons.play_circle_outline;
      statusColor = Colors.orangeAccent;
      actionButton = IconButton(
        icon: Icon(Icons.play_circle_outline, color: Colors.green),
        onPressed:
            () => _startTimer(exercise), // Start from current elapsed time
      );
    }

    // Check if duration is completed based on elapsed time
    if (exercise.status == 'In Progress' &&
        elapsedMilliseconds >= totalDurationMilliseconds) {
      // Automatically mark as completed if duration is met and not already completed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _completeWorkout(
          exercise,
        ); // Use addPostFrameCallback to avoid state changes during build
      });
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exercise.title.replaceFirst('Exercise - ', ''),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(exercise.time, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            SizedBox(height: 8),
            Text(exercise.description, style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${exercise.calories} calories',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        SizedBox(width: 4),
                        Text(
                          '$statusText ('
                          '${remainingMinutes.toString().padLeft(2, '0')}:'
                          '${remainingSeconds.toString().padLeft(2, '0')})',
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  // Wrap action button and delete button in a Row
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    actionButton, // Play/Pause button
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ), // Delete button
                      onPressed: () async {
                        try {
                          _stopTimer(exercise); // Stop timer before deleting
                          await Storage.removeActivity(exercise);
                          await _loadExercises(); // Reload list after deletion
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('exercise_removed_successfully'),
                              ),
                            ), // Need translation key
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error removing exercise: $e'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
