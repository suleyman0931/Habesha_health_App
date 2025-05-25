import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../utils/storage.dart';
import '../localization/app_localizations.dart';
import '../widgets/custom_bottom_navigation_bar.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _imagePicker = ImagePicker();
  String? _selectedFitnessLevel;
  String? _selectedGender;
  bool _isEditing = false;
  User? _user;
  bool _isLoading = true;

  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Athlete'];
  final List<String> _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final user = await Storage.getUser();
      if (user != null) {
        user.calculateGoals(); // Recalculate goals with current data
        await Storage.saveUser(user); // Save the updated user data
        setState(() {
          _user = user;
          _nameController.text = user.name ?? '';
          _birthdateController.text =
              user.birthdate != null
                  ? DateFormat('MM/dd/yyyy').format(user.birthdate!)
                  : '';
          _weightController.text = user.weight?.toString() ?? '';
          _heightController.text = user.height?.toString() ?? '';
          _selectedFitnessLevel = user.fitnessLabel ?? _fitnessLevels[0];
          _selectedGender = user.gender ?? _genders[0];
          _isLoading = false;
        });
      } else {
        Navigator.pushReplacementNamed(context, '/register');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _user?.birthdate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF8B4513),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthdateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = User(
        name: _nameController.text.trim(),
        birthdate: DateFormat('MM/dd/yyyy').parse(_birthdateController.text),
        weight: double.parse(_weightController.text.trim()),
        height: double.parse(_heightController.text.trim()),
        fitnessLabel: _selectedFitnessLevel!,
        gender: _selectedGender!,
        profilePicturePath: _user?.profilePicturePath,
      );
      user.calculateGoals();
      await Storage.saveUser(user);
      setState(() {
        _user = user;
        _isEditing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (pickedFile != null) {
        final user = _user;
        if (user != null) {
          user.profilePicturePath = pickedFile.path;
          await Storage.saveUser(user);
          setState(() {
            _user = user;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_user?.profilePicturePath != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'Remove photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final user = _user;
                    if (user != null) {
                      user.profilePicturePath = null;
                      await Storage.saveUser(user);
                      setState(() {
                        _user = user;
                      });
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthdateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return Scaffold(body: Center(child: Text('No user data found')));
    }

    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.translate('profile'),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF8B4513),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              _user!.profilePicturePath != null
                                  ? FileImage(File(_user!.profilePicturePath!))
                                  : null,
                          backgroundColor: Colors.grey[300],
                          child:
                              _user!.profilePicturePath == null
                                  ? Icon(
                                    Icons.person,
                                    size: 48,
                                    color: Colors.grey[600],
                                  )
                                  : null,
                        ),
                        if (!_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Color(0xFF8B4513),
                              radius: 16,
                              child: IconButton(
                                icon: Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                onPressed: _showImagePickerOptions,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 16),
                    if (!_isEditing)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user!.name ?? 'N/A',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B4513),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${_user!.age ?? 0} years • ${_user!.gender ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'BMI: ${_user!.getBMI()?.toStringAsFixed(1) ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),

                if (!_isEditing) ...[
                  _buildInfoCard(
                    title: loc.translate('physical_info'),
                    children: [
                      _buildInfoRow(
                        loc.translate('weight'),
                        '${_user!.weight?.toString() ?? 'N/A'} kg',
                      ),
                      _buildInfoRow(
                        loc.translate('height'),
                        '${_user!.height?.toString() ?? 'N/A'} cm',
                      ),
                      _buildInfoRow(
                        loc.translate('fitness_level'),
                        _user!.fitnessLabel ?? 'N/A',
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildInfoCard(
                    title: loc.translate('goals'),
                    children: [
                      _buildInfoRow(
                        loc.translate('calorie_goal'),
                        '${_user!.calorieGoal?.toInt() ?? 0} calories/day',
                      ),
                      _buildInfoRow(
                        loc.translate('water_goal'),
                        '${_user!.waterGoal?.toStringAsFixed(1) ?? '0.0'} L/day',
                      ),
                      _buildInfoRow(
                        loc.translate('recommended_exercises'),
                        _user!.recommendedExercises?.isNotEmpty == true
                            ? _user!.recommendedExercises!.join(', ')
                            : 'None',
                      ),
                    ],
                  ),
                ] else ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: loc.translate('full_name'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return loc.translate('please_enter_name');
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),

                  TextFormField(
                    controller: _birthdateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: loc.translate('birthdate'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.calendar_today,
                          color: Color(0xFF8B4513),
                        ),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.translate('please_select_birthdate');
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: InputDecoration(
                      labelText: loc.translate('gender'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    items:
                        _genders.map((gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return loc.translate('please_select_gender');
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),

                  TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: loc.translate('weight'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixText: 'kg',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return loc.translate('please_enter_weight');
                      }
                      final weight = double.tryParse(value.trim());
                      if (weight == null || weight <= 0) {
                        return loc.translate('please_enter_valid_weight');
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),

                  TextFormField(
                    controller: _heightController,
                    decoration: InputDecoration(
                      labelText: loc.translate('height'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixText: 'cm',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return loc.translate('please_enter_height');
                      }
                      final height = double.tryParse(value.trim());
                      if (height == null || height <= 0) {
                        return loc.translate('please_enter_valid_height');
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _selectedFitnessLevel,
                    decoration: InputDecoration(
                      labelText: loc.translate('fitness_label'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    items:
                        _fitnessLevels.map((level) {
                          return DropdownMenuItem<String>(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFitnessLevel = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return loc.translate('please_select_fitness_level');
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _isEditing = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            loc.translate('cancel'),
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF8B4513),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            loc.translate('save_changes'),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, '/dashboard');
          if (index == 1) Navigator.pushNamed(context, '/meal');
          if (index == 2) Navigator.pushNamed(context, '/exercise');
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
