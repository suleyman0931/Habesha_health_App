import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/activity_model.dart';
import '../utils/storage.dart';
import '../localization/app_localizations.dart';
import '../widgets/custom_bottom_navigation_bar.dart';

class MealScreen extends StatefulWidget {
  @override
  _MealScreenState createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<Activity> _todayMeals = [];
  List<Map<String, dynamic>> _predefinedMeals = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _selectedMealCategory = 'Breakfast';

  final List<String> _mealCategories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
  ];

  @override
  void initState() {
    super.initState();
    _loadMeals();
    _loadPredefinedMeals();
  }

  Future<void> _loadPredefinedMeals() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/meals.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        _predefinedMeals = List<Map<String, dynamic>>.from(jsonData['meals']);
      });
    } catch (e) {
      print('Error loading predefined meals: $e');
    }
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    try {
      final meals = await Storage.getTodayMeals();
      setState(() {
        _todayMeals = meals;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading meals: $e')));
      setState(() => _isLoading = false);
    }
  }

  void _showAddMealDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(loc.translate('add_new_meal')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: loc.translate('meal_name'),
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
                  controller: _caloriesController,
                  decoration: InputDecoration(
                    labelText: loc.translate('calories'),
                    border: OutlineInputBorder(),
                    suffixText: 'calories',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedMealCategory,
                  decoration: InputDecoration(
                    labelText: loc.translate('category'),
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _mealCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedMealCategory = newValue);
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
                _caloriesController.clear();
                _descriptionController.clear();
                Navigator.pop(context);
              },
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isEmpty ||
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
                  final newMeal = {
                    'name': _nameController.text,
                    'description': _descriptionController.text,
                    'calories': int.parse(_caloriesController.text),
                    'category': _selectedMealCategory,
                    'image': 'assets/images/placeholder.jpg',
                  };

                  setState(() {
                    _predefinedMeals.add(newMeal);
                  });

                  _nameController.clear();
                  _caloriesController.clear();
                  _descriptionController.clear();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.translate('meal_added_successfully')),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving meal: $e')),
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

  void _showPlanMealDialog(Map<String, dynamic> meal) {
    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(loc.translate('plan_meal')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(loc.translate('select_time')),
                  subtitle: Text(_selectedTime.format(context)),
                  trailing: Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) {
                      setState(() => _selectedTime = time);
                    }
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedMealCategory,
                  decoration: InputDecoration(
                    labelText: loc.translate('category'),
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _mealCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedMealCategory = newValue);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
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

                  final mealToAdd = Activity(
                    title: 'Meal - ${meal['name']}',
                    time: time,
                    description: meal['description'] ?? '',
                    duration: '',
                    calories: meal['calories']?.toString() ?? '0',
                    bpm: '',
                    date: now,
                  );

                  // Save the meal
                  await Storage.saveMeal(mealToAdd);

                  // Update today's progress
                  final todayProgress =
                      await Storage.getTodayProgress() ??
                      {
                        'steps': 0,
                        'waterIntake': 0.0,
                        'caloriesBurned': 0,
                        'caloriesGained': 0,
                      };

                  final caloriesToAdd =
                      int.tryParse(meal['calories']?.toString() ?? '0') ?? 0;
                  final currentCaloriesGained =
                      todayProgress['caloriesGained'] ?? 0;

                  await Storage.saveTodayProgress(
                    todayProgress['steps'] ?? 0,
                    todayProgress['waterIntake'] ?? 0.0,
                    todayProgress['caloriesBurned'] ?? 0,
                    currentCaloriesGained + caloriesToAdd,
                  );

                  // Reload meals and activities
                  await _loadMeals();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.translate('meal_planned_successfully')),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error planning meal: $e')),
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

  List<Map<String, dynamic>> get _filteredPredefinedMeals {
    if (_selectedCategory == 'All') {
      return _predefinedMeals;
    }
    return _predefinedMeals
        .where((meal) => meal['category'] == _selectedCategory)
        .toList();
  }

  List<String> get _mealTypeCategories {
    final categories =
        _predefinedMeals.map((e) => e['category'] as String).toSet().toList();
    return ['All', ...categories];
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
          loc.translate('meal'),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF8B4513),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadMeals,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showAddMealDialog,
                          icon: Icon(Icons.add),
                          label: Text(
                            loc.translate('add_new_meal'),
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
                          loc.translate('predefined_meals'),
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
                                _mealTypeCategories.map((category) {
                                  return Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(category),
                                      selected: _selectedCategory == category,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(
                                            () => _selectedCategory = category,
                                          );
                                        }
                                      },
                                      backgroundColor: Colors.grey[200],
                                      selectedColor: Color(0xFF8B4513),
                                      labelStyle: TextStyle(
                                        color:
                                            _selectedCategory == category
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        SizedBox(height: 16),
                        ..._filteredPredefinedMeals
                            .map((meal) => _buildPredefinedMealItem(meal))
                            .toList(),
                        SizedBox(height: 24),
                        Text(
                          loc.translate('todays_meals'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        if (_todayMeals.isEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                loc.translate('no_meals_today'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._todayMeals
                              .map((meal) => _buildMealItem(meal))
                              .toList(),
                      ],
                    ),
                  ),
                ),
              ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, '/dashboard');
          if (index == 2) Navigator.pushNamed(context, '/exercise');
          if (index == 3) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }

  Widget _buildPredefinedMealItem(Map<String, dynamic> meal) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(
                meal['image'] ?? 'assets/images/placeholder.jpg',
              ),
              radius: 24,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['name'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    meal['description'],
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(meal['category']),
                        SizedBox(width: 16),
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text('${meal['calories']} calories'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 8, top: 8),
              child: TextButton(
                onPressed: () => _showPlanMealDialog(meal),
                child: Text(
                  'Add to Plan',
                  style: TextStyle(color: Color(0xFF8B4513)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem(Activity meal) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.title.replaceFirst('Meal - ', ''),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${meal.calories} calories',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        meal.time,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                try {
                  await Storage.removeMeal(meal);
                  await _loadMeals();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Meal removed successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error removing meal: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
