import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  CustomBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  final List<Map<String, dynamic>> _items = [
    {'icon': Icons.home, 'label': 'home'},
    {'icon': Icons.restaurant, 'label': 'meals'},
    {'icon': Icons.fitness_center, 'label': 'exercise'},
    {'icon': Icons.person, 'label': 'profile'},
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_items.length, (index) {
          final isSelected = index == currentIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              splashColor: Color(0xFF8B4513).withOpacity(0.2),
              highlightColor: Color(0xFF8B4513).withOpacity(0.1),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isSelected ? Color(0xFF8B4513) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _items[index]['icon'],
                      color: isSelected ? Color(0xFF8B4513) : Colors.grey[600],
                      size: 22,
                    ),
                    SizedBox(height: 2),
                    Text(
                      loc.translate(_items[index]['label']),
                      style: TextStyle(
                        color: isSelected ? Color(0xFF8B4513) : Colors.grey[600],
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
} 