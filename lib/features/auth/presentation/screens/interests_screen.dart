import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final Set<String> _selectedInterests = {};

  final List<Map<String, dynamic>> _interests = [
    {'name': 'Music', 'icon': Icons.music_note_rounded, 'color': Colors.purple},
    {'name': 'Travel', 'icon': Icons.flight_rounded, 'color': Colors.blue},
    {'name': 'Photography', 'icon': Icons.camera_alt_rounded, 'color': Colors.orange},
    {'name': 'Gaming', 'icon': Icons.sports_esports_rounded, 'color': Colors.green},
    {'name': 'Fitness', 'icon': Icons.fitness_center_rounded, 'color': Colors.red},
    {'name': 'Cooking', 'icon': Icons.restaurant_rounded, 'color': Colors.amber},
    {'name': 'Reading', 'icon': Icons.menu_book_rounded, 'color': Colors.teal},
    {'name': 'Art', 'icon': Icons.palette_rounded, 'color': Colors.pink},
    {'name': 'Dance', 'icon': Icons.nightlife_rounded, 'color': Colors.deepPurple},
    {'name': 'Movies', 'icon': Icons.movie_rounded, 'color': Colors.cyan},
    {'name': 'Pets', 'icon': Icons.pets_rounded, 'color': Colors.brown},
    {'name': 'Nature', 'icon': Icons.nature_rounded, 'color': Colors.lightGreen},
    {'name': 'Fashion', 'icon': Icons.checkroom_rounded, 'color': Colors.indigo},
    {'name': 'Tech', 'icon': Icons.computer_rounded, 'color': Colors.blueGrey},
    {'name': 'Yoga', 'icon': Icons.self_improvement_rounded, 'color': Colors.deepOrange},
    {'name': 'Coffee', 'icon': Icons.coffee_rounded, 'color': Colors.brown},
    {'name': 'Sports', 'icon': Icons.sports_basketball_rounded, 'color': Colors.orange},
    {'name': 'Music Festivals', 'icon': Icons.celebration_rounded, 'color': Colors.amber},
    {'name': 'Beach', 'icon': Icons.beach_access_rounded, 'color': Colors.cyan},
    {'name': 'Foodie', 'icon': Icons.fastfood_rounded, 'color': Colors.redAccent},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Select Interests'),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text('Skip', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.darkGradient,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              child: Text(
                'Choose at least 3 interests to match with similar people',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
              ).animate().fadeIn(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_interests.length, (index) {
                    final interest = _interests[index];
                    final isSelected = _selectedInterests.contains(interest['name']);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (isSelected) {
                            _selectedInterests.remove(interest['name']);
                          } else {
                            _selectedInterests.add(interest['name']);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (interest['color'] as Color).withOpacity(0.2)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected
                                ? interest['color'] as Color
                                : Colors.white.withOpacity(0.08),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              interest['icon'] as IconData,
                              size: 20,
                              color: isSelected ? interest['color'] as Color : Colors.white54,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              interest['name'] as String,
                              style: TextStyle(
                                color: isSelected ? interest['color'] as Color : Colors.white54,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 200 + index * 50))
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          delay: Duration(milliseconds: 200 + index * 50),
                          duration: 300.ms,
                        );
                  }),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  Text(
                    '${_selectedInterests.length} selected',
                    style: TextStyle(
                      color: _selectedInterests.length >= 3
                          ? AppColors.successGreen
                          : Colors.white38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _selectedInterests.length >= 3
                          ? () {
                              HapticFeedback.mediumImpact();
                              context.go('/home');
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _selectedInterests.length >= 3
                                ? AppColors.primaryGradient
                                : [Colors.grey.shade800, Colors.grey.shade700],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Continue',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
