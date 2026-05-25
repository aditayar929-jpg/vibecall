import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/firestore_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  final FirestoreService _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  int _currentPage = 0;
  String _selectedGender = '';
  int _selectedAge = 22;
  final Set<String> _selectedInterests = {};
  File? _profilePhoto;
  String? _avatarUrl;
  bool _isUploading = false;

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
    {'name': 'Beach', 'icon': Icons.beach_access_rounded, 'color': Colors.cyan},
    {'name': 'Foodie', 'icon': Icons.fastfood_rounded, 'color': Colors.redAccent},
    {'name': 'Parties', 'icon': Icons.celebration_rounded, 'color': Colors.amber},
  ];

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _saveProfile();
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _profilePhoto = File(picked.path);
        _isUploading = true;
      });

      try {
        final url = await _firestoreService.uploadProfilePhoto(_profilePhoto!);
        setState(() {
          _avatarUrl = url;
          _isUploading = false;
        });
      } catch (e) {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.errorRed),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    HapticFeedback.mediumImpact();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name'), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    await _firestoreService.updateProfile(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      gender: _selectedGender,
      age: _selectedAge,
      interests: _selectedInterests.toList(),
    );

    if (_avatarUrl != null) {
      await _firestoreService.updateAvatar(_avatarUrl!);
    }

    // Update Firebase Auth display name
    await user.updateDisplayName(_nameController.text.trim());
    if (_avatarUrl != null) {
      await user.updatePhotoURL(_avatarUrl!);
    }

    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user?.isAnonymous ?? false;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF12122A), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                child: Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? AppColors.primaryPurple
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildPhotoPage(isGuest),
                    _buildNameBioPage(),
                    _buildGenderAgePage(),
                    _buildInterestsPage(),
                  ],
                ),
              ),

              // Bottom buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Back', style: TextStyle(color: Colors.white54)),
                      ),
                    const Spacer(),
                    if (isGuest && _currentPage == 0)
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: Text('Skip for now', style: TextStyle(color: Colors.white.withOpacity(0.4))),
                      ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 140,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.primaryGradient),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              _currentPage == 3 ? 'Finish' : 'Next',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      ),
    );
  }

  Widget _buildPhotoPage(bool isGuest) {
    final user = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Text(
            'Add Your Photo',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            isGuest
                ? 'Add a photo so people can recognize you'
                : 'Let people see who you are',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: _profilePhoto == null
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryPurple.withOpacity(0.2),
                          AppColors.neonPink.withOpacity(0.1),
                        ],
                      )
                    : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryPurple.withOpacity(0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(color: AppColors.primaryPurple)
                  : _profilePhoto != null
                      ? ClipOval(
                          child: Image.file(
                            _profilePhoto!,
                            width: 180,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        )
                      : user?.photoURL != null
                          ? ClipOval(
                              child: Image.network(
                                user!.photoURL!,
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.add_a_photo_rounded,
                                  size: 50,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_rounded,
                                  size: 50,
                                  color: AppColors.primaryPurple.withOpacity(0.7),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Photo',
                                  style: TextStyle(
                                    color: AppColors.primaryPurple.withOpacity(0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          if (_avatarUrl != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 18),
                  SizedBox(width: 6),
                  Text('Photo uploaded!', style: TextStyle(color: AppColors.successGreen, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNameBioPage() {
    final user = FirebaseAuth.instance.currentUser;
    if (_nameController.text.isEmpty && user?.displayName != null) {
      _nameController.text = user!.displayName!;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          const Text(
            'About You',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            'Tell people a bit about yourself',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 40),
          const Text('Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Your name',
              prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primaryPurple),
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),
          const Text('Bio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            controller: _bioController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Write something about yourself...',
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildGenderAgePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          const Text(
            'Your Details',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            'Help us find better matches for you',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 40),
          const Text('Gender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildGenderOption('Male', Icons.male_rounded, AppColors.primaryPurple),
              const SizedBox(width: 12),
              _buildGenderOption('Female', Icons.female_rounded, AppColors.neonPink),
              const SizedBox(width: 12),
              _buildGenderOption('Other', Icons.transgender_rounded, AppColors.diamondBlue),
            ],
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 36),
          const Text('Age', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    if (_selectedAge > 18) setState(() => _selectedAge--);
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.remove_rounded, color: AppColors.primaryPurple),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$_selectedAge',
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'years old',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    if (_selectedAge < 65) setState(() => _selectedAge++);
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded, color: AppColors.primaryPurple),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95), delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildInterestsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Interests',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ).animate().fadeIn(),
              const SizedBox(height: 8),
              Text(
                'Choose at least 3 interests to find like-minded people',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
              ).animate().fadeIn(delay: 100.ms),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                ).animate().fadeIn(delay: Duration(milliseconds: 200 + index * 40));
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: Text(
            '${_selectedInterests.length} selected',
            style: TextStyle(
              color: _selectedInterests.length >= 3 ? AppColors.successGreen : Colors.white38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String label, IconData icon, Color color) {
    final isSelected = _selectedGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedGender = label);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.08),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.white54, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.white54,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
