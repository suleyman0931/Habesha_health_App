import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../utils/storage.dart';
import '../localization/app_localizations.dart';
import '../widgets/progress_ring.dart';
import '../widgets/custom_bottom_navigation_bar.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  User? _user;
  int _steps = 0;
  double _waterIntake = 0.0;
  int _caloriesBurned = 0;
  int _caloriesGained = 0;
  DateTime? _lastWaterUpdate;
  List<Activity> _todayActivities = [];
  Map<String, Map<String, dynamic>> _weeklyData = {};
  RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  String _status = 'Unknown';
  bool _isStepTrackingInitialized = false;
  bool _showAllActivities = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadActivities();
    _loadWeeklyData();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _initStepTracking();
    } else {
      // Show a dialog to explain why we need the permission
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Permission Required'),
                content: Text(
                  'Step tracking requires activity recognition permission. Please enable it in settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  void _initStepTracking() async {
    if (_isStepTrackingInitialized) return;

    try {
      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        (PedestrianStatus event) {
          if (mounted) {
            setState(() {
              _status = event.status;
            });
          }
        },
        onError: (error) {
          print('Pedestrian Status Error: $error');
        },
        cancelOnError: true,
      );

      _stepCountSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          if (mounted) {
            setState(() {
              _steps = event.steps;
              // Create a step activity and save progress
              final now = DateTime.now();
              final stepActivity = Activity(
                title: 'Steps',
                time: DateFormat('h:mm a').format(now),
                description: 'Daily steps',
                duration: '',
                calories: '$_steps calories',
                bpm: '',
                date: now,
                steps: _steps,
              );
              Storage.saveActivity(stepActivity);
              Storage.saveTodayProgress(
                _steps,
                _waterIntake,
                _caloriesBurned,
                _caloriesGained,
              );
              _loadWeeklyData(); // Refresh weekly data when steps update
            });
          }
        },
        onError: (error) {
          print('Step Count Error: $error');
        },
        cancelOnError: true,
      );

      _isStepTrackingInitialized = true;
    } catch (e) {
      print('Error initializing step tracking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to initialize step tracking. Please check permissions.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    _loadActivities();
  }

  Future<void> _loadUser() async {
    final user = await Storage.getUser();
    if (user != null) {
      setState(() {
        _user = user;
      });
    } else {
      Navigator.pushReplacementNamed(context, '/register');
    }
  }

  Future<void> _loadActivities() async {
    final progress = await Storage.getTodayProgress();
    final activities = await Storage.getTodayActivities();
    setState(() {
      _todayActivities = activities;
      _steps = progress?['steps'] ?? 0;
      _waterIntake = progress?['waterIntake'] ?? 0.0;
      _caloriesBurned = progress?['caloriesBurned'] ?? 0;
      _caloriesGained = 0; // Reset calories gained

      // Update steps from activities
      for (var activity in activities) {
        if (activity.title == 'Steps') {
          _steps =
              activity.steps ??
              int.tryParse(activity.calories.replaceAll(' calories', '')) ??
              _steps;
        } else if (activity.title == 'Water Intake') {
          final waterAmount =
              double.tryParse(
                activity.description
                    .replaceAll('Added ', '')
                    .replaceAll('ml of water', ''),
              ) ??
              0;
          _waterIntake += waterAmount / 1000;
          _lastWaterUpdate = activity.date;
        } else if (activity.title.startsWith('Meal - ') ||
            activity.title.contains('Planned Meal')) {
          // Track calories from meals (both regular and planned)
          final calories = int.tryParse(activity.calories) ?? 0;
          _caloriesGained += calories;
        } else if (activity.title.contains('Exercise -')) {
          if (activity.calories.isNotEmpty) {
            _caloriesBurned +=
                int.tryParse(activity.calories.replaceAll(' calories', '')) ??
                0;
          }
        }
      }

      if (_user != null) {
        _waterIntake = _waterIntake.clamp(0.0, _user!.waterGoal ?? 3.0);
      }

      // Save updated progress
      Storage.saveTodayProgress(
        _steps,
        _waterIntake,
        _caloriesBurned,
        _caloriesGained,
      );
    });
  }

  Future<void> _loadWeeklyData() async {
    final data = await Storage.getWeeklyActivities();
    setState(() {
      _weeklyData = data;
    });

    // Update calories gained for each day
    for (var entry in _weeklyData.entries) {
      final day = entry.key;
      final dayData = entry.value;

      // Initialize caloriesGained if not present
      if (dayData['caloriesGained'] == null) {
        dayData['caloriesGained'] = 0;
      }

      // Get activities for this day
      final activities = await Storage.getDayActivities(DateTime.parse(day));
      int totalCaloriesGained = 0;

      // Calculate total calories gained from meals
      for (var activity in activities) {
        if (activity.title.startsWith('Meal - ')) {
          final calories = int.tryParse(activity.calories) ?? 0;
          totalCaloriesGained += calories;
        }
      }

      // Update the weekly data with the calculated calories
      setState(() {
        dayData['caloriesGained'] = totalCaloriesGained;
      });
    }
  }

  void _addWater() {
    final now = DateTime.now();
    final time = DateFormat('h:mm a').format(now);
    final activity = Activity(
      title: 'Water Intake',
      time: time,
      description: 'Added 250ml of water',
      duration: '',
      calories: '',
      bpm: '',
      date: now,
    );
    Storage.saveActivity(activity);
    setState(() {
      _waterIntake += 0.25;
      if (_waterIntake > (_user?.waterGoal ?? 3.0))
        _waterIntake = _user?.waterGoal ?? 3.0;
      _todayActivities.add(activity);
      _lastWaterUpdate = now;
      Storage.saveTodayProgress(
        _steps,
        _waterIntake,
        _caloriesBurned,
        _caloriesGained,
      );
    });
  }

  String _getLastUpdateText() {
    if (_lastWaterUpdate == null)
      return AppLocalizations.of(context).translate('no_updates_yet');

    final now = DateTime.now();
    final difference = now.difference(_lastWaterUpdate!);

    if (difference.inMinutes < 1) {
      return AppLocalizations.of(context).translate('just_now');
    } else if (difference.inMinutes < 60) {
      return AppLocalizations.of(
        context,
      ).translate('minutes_ago').replaceFirst('%d', '${difference.inMinutes}');
    } else if (difference.inHours < 24) {
      return AppLocalizations.of(
        context,
      ).translate('hours_ago').replaceFirst('%d', '${difference.inHours}');
    } else {
      return DateFormat('MMM d, h:mm a').format(_lastWaterUpdate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final now = DateTime.now();
    final formattedDate = DateFormat('MMMM dd, yyyy').format(now);
    final dayOfWeek = DateFormat('EEEE').format(now);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset('assets/images/logo.png', height: 40),
          onPressed: () {},
        ),
        title: Text('Habesha Health', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF8B4513),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc
                        .translate('welcome_back')
                        .replaceFirst('%s', _user?.name ?? 'User'),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    loc
                        .translate('today')
                        .replaceFirst('%s', '$formattedDate | $dayOfWeek'),
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Card(
              margin: EdgeInsets.all(8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('todays_progress'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(width: 8),
                          ProgressRing(
                            value: _steps.toDouble(),
                            maxValue: 10000,
                            label: loc.translate('steps'),
                          ),
                          SizedBox(width: 16),
                          ProgressRing(
                            value: _waterIntake,
                            maxValue: _user?.waterGoal ?? 3.0,
                            label: loc.translate('water_intake'),
                            isWater: true,
                          ),
                          SizedBox(width: 16),
                          ProgressRing(
                            value: _caloriesBurned.toDouble(),
                            maxValue: _user?.calorieGoal ?? 2000.0,
                            label: loc.translate('calories_burned'),
                          ),
                          SizedBox(width: 16),
                          ProgressRing(
                            value: _caloriesGained.toDouble(),
                            maxValue: _user?.calorieGoal ?? 2000.0,
                            label: loc.translate('calories_gained'),
                            isCalories: true,
                          ),
                          SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.all(8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('water_intake'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        // Water cup visualization
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              width: 120,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            Container(
                              width: 120,
                              height:
                                  180 *
                                  (_waterIntake / (_user?.waterGoal ?? 3.0))
                                      .clamp(0.0, 1.0),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(20),
                                ),
                              ),
                            ),
                            Text(
                              '${_waterIntake.toStringAsFixed(1)}L\nof ${(_user?.waterGoal ?? 3.0).toStringAsFixed(1)}L',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        SizedBox(width: 16),
                        // Controls
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('0L'),
                                  Text(
                                    '${(_user?.waterGoal ?? 3.0).toStringAsFixed(1)}L',
                                  ),
                                ],
                              ),
                              Slider(
                                value: _waterIntake,
                                min: 0,
                                max: _user?.waterGoal ?? 3.0,
                                onChanged: (value) {
                                  setState(() {
                                    _waterIntake = value;
                                    Storage.saveTodayProgress(
                                      _steps,
                                      _waterIntake,
                                      _caloriesBurned,
                                      _caloriesGained,
                                    );
                                  });
                                },
                              ),
                              ElevatedButton(
                                onPressed: _addWater,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_drink,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      loc.translate('add_water'),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF8B4513),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Last update: ${_getLastUpdateText()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.all(8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('todays_activity'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    StatefulBuilder(
                      builder: (context, setState) {
                        final bool showAll = _showAllActivities;
                        // Filter out steps and sort activities by date
                        final filteredActivities =
                            _todayActivities
                                .where((activity) => activity.title != 'Steps')
                                .toList()
                              ..sort((a, b) => b.date.compareTo(a.date));
                        final displayedActivities =
                            showAll
                                ? filteredActivities
                                : filteredActivities.take(5).toList();

                        return Column(
                          children: [
                            ...displayedActivities
                                .map((activity) => _buildActivityItem(activity))
                                .toList(),
                            if (filteredActivities.length > 5)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showAllActivities = !_showAllActivities;
                                    });
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        showAll
                                            ? loc.translate('show_less')
                                            : loc.translate('view_more'),
                                        style: TextStyle(
                                          color: Color(0xFF8B4513),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Icon(
                                        showAll
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: Color(0xFF8B4513),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.all(8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('weekly_progress'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ..._weeklyData.entries.map((entry) {
                      final day = entry.key;
                      final data = entry.value;
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.directions_walk,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${data['steps']}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.water_drop,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${data['water'].toStringAsFixed(1)}L',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.local_fire_department,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${data['calories']}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.restaurant,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${data['caloriesGained']}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 8),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/meal');
          if (index == 2) Navigator.pushNamed(context, '/exercise');
          if (index == 3) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }

  Widget _buildActivityItem(Activity activity) {
    // Format the time consistently
    final time = DateFormat('h:mm a').format(activity.date);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                activity.title.startsWith('Meal - ')
                    ? Icons.restaurant
                    : activity.title == 'Water Intake'
                    ? Icons.water_drop
                    : activity.title.contains('Exercise')
                    ? Icons.fitness_center
                    : Icons.event_note,
                size: 20,
                color: Color(0xFF8B4513),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title.replaceFirst('Meal - ', ''),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      activity.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (activity.calories.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          '${activity.calories} calories',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                time,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          Divider(height: 16),
        ],
      ),
    );
  }
}
