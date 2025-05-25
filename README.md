# Habesha Health

A comprehensive health and fitness tracking application designed with Ethiopian context, helping users maintain a healthy lifestyle through activity tracking, meal planning, and exercise routines.

## Features

### 1. Dashboard
- Real-time step tracking
- Water intake monitoring
- Calorie tracking
- Daily activity summary
- Weekly progress overview
- Visual progress rings for goals

### 2. Profile Management
- Personal information storage
- BMI calculation
- Fitness level tracking
- Customizable goals
- Profile picture support
- Health metrics tracking

### 3. Activity Tracking
- Step counting with pedometer integration
- Water intake logging
- Exercise tracking
- Calorie monitoring
- Activity history
- Weekly progress reports

### 4. Meal Planning
- Ethiopian meal database
- Meal logging
- Calorie tracking
- Nutritional information
- Meal scheduling
- Dietary preferences

### 5. Exercise Tracking
- Exercise database
- Workout logging
- Calorie burn tracking
- Exercise history
- Custom workout creation
- Progress tracking

### 6. Localization
- Multi-language support
- Ethiopian context
- Cultural considerations
- Local measurements
- Regional food items

## Technical Features

### State Management
- Efficient data persistence
- Real-time updates
- Offline support
- Data synchronization

### UI/UX
- Material Design implementation
- Responsive layout
- Dark/Light theme support
- Custom widgets
- Progress visualizations

### Security
- Local data storage
- Privacy-focused
- Secure user data handling
- Permission management

## Setup and Installation

### Prerequisites
- Flutter SDK (version 3.7.0 or higher)
- Dart SDK
- Android Studio / Xcode
- Git

### Installation Steps
1. Clone the repository:
   ```bash
   git clone [repository-url]
   ```

2. Navigate to project directory:
   ```bash
   cd flutter_application_3
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

### Required Permissions
- Activity Recognition (for step counting)
- Camera (for profile pictures)
- Storage (for saving data)
- Location (for activity tracking)

## Project Structure

```
lib/
├── models/          # Data models
├── screens/         # UI screens
├── widgets/         # Reusable widgets
├── utils/           # Utility functions
├── localization/    # Language files
└── assets/          # Images and data files
```

## Dependencies

- `shared_preferences`: Local data storage
- `intl`: Internationalization
- `flutter_local_notifications`: Push notifications
- `pedometer`: Step counting
- `image_picker`: Profile picture management
- `permission_handler`: Permission management

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue in the GitHub repository or contact the development team.

## Acknowledgments

- Ethiopian Health Ministry
- Local fitness experts
- Community contributors
- Open-source community

## Version History

- 1.0.0
  - Initial release
  - Basic health tracking features
  - Localization support
  - Profile management
  - Activity tracking
  - Meal planning
  - Exercise tracking
