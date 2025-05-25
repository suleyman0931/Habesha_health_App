import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../utils/storage.dart';
import '../localization/app_localizations.dart';
import '../utils/notification_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String? _selectedFitnessLevel;
  String? _selectedGender;
  bool _isLoading = false;
  File? _profileImage;

  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Athlete'];
  final List<String> _genders = ['Male', 'Female'];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkUserRegistration();
  }

  Future<void> _checkUserRegistration() async {
    final user = await Storage.getUser();
    if (user != null && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = User(
        name: _nameController.text.trim(),
        birthdate: DateFormat('MM/dd/yyyy').parse(_birthdateController.text),
        weight: double.parse(_weightController.text.trim()),
        height: double.parse(_heightController.text.trim()),
        fitnessLabel: _selectedFitnessLevel!,
        gender: _selectedGender!,
        profilePicturePath: _profileImage?.path,
      );
      user.calculateGoals();

      await Storage.saveUser(user);

      await NotificationService.scheduleWaterReminder();
      await NotificationService.scheduleExerciseReminder(
        DateTime(2025, 5, 21, 18, 0),
      );
      await NotificationService.scheduleMotivation();

      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.translate('create_profile'),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF8B4513),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image Picker
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                        backgroundColor: Colors.grey[300],
                        child:
                            _profileImage == null
                                ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey[600],
                                )
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Color(0xFF8B4513),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _pickImage,
                    child: Text(
                      loc.translate('choose_photo'),
                      style: TextStyle(color: Color(0xFF8B4513), fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Form Fields
                _buildTextField(
                  controller: _nameController,
                  label: loc.translate('full_name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.translate('please_enter_name');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                _buildTextField(
                  controller: _birthdateController,
                  label: loc.translate('birthdate'),
                  readOnly: true,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today, color: Color(0xFF8B4513)),
                    onPressed: () => _selectDate(context),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc.translate('please_select_birthdate');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Gender Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: loc.translate('gender'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                SizedBox(height: 16),

                _buildTextField(
                  controller: _weightController,
                  label: loc.translate('weight'),
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
                SizedBox(height: 16),

                _buildTextField(
                  controller: _heightController,
                  label: loc.translate('height'),
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
                SizedBox(height: 16),

                // Fitness Level Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedFitnessLevel,
                  decoration: InputDecoration(
                    labelText: loc.translate('fitness_label'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                SizedBox(height: 32),

                // Register Button
                Center(
                  child:
                      _isLoading
                          ? CircularProgressIndicator(color: Color(0xFF8B4513))
                          : ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF8B4513),
                              padding: EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              loc.translate('register'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
    );
  }
}
