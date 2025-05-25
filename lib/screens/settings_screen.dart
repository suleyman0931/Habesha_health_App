import 'package:flutter/material.dart';
import '../main.dart';
import '../localization/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = HabeshaHealthApp.of(context);
    
    // Check if appState is null to avoid runtime errors
    if (appState == null) {
      return Scaffold(
        body: Center(child: Text('Error: Unable to access app state')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('settings'))),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.translate('theme'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: Text(loc.translate('light'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              trailing: Radio<String>(
                value: 'light',
                groupValue: appState.themeMode, // Use getter
                onChanged: (value) => appState.setThemeMode(value!),
              ),
            ),
            ListTile(
              title: Text(loc.translate('dark'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              trailing: Radio<String>(
                value: 'dark',
                groupValue: appState.themeMode, // Use getter
                onChanged: (value) => appState.setThemeMode(value!),
              ),
            ),
            SizedBox(height: 20),
            Text(loc.translate('language'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: Text(loc.translate('english'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              trailing: Radio<Locale>(
                value: Locale('en', ''),
                groupValue: appState.locale, // Use getter
                onChanged: (value) => appState.setLocale(value!),
              ),
            ),
            ListTile(
              title: Text(loc.translate('amharic'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              trailing: Radio<Locale>(
                value: Locale('am', ''),
                groupValue: appState.locale, // Use getter
                onChanged: (value) => appState.setLocale(value!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}