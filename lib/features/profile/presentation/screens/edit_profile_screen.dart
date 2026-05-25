import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: 'Alex Johnson');
  final _bioController = TextEditingController(text: 'Adventure seeker & coffee lover ☕');
  final _ageController = TextEditingController(text: '24');
  String _selectedGender = 'Male';
  final List<String> _selectedInterests = ['Travel', 'Music', 'Photography', 'Coffee'];
  final List<String> _photos = List.filled(6, '');

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            child: const Text('Save', style: TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.w600)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos Grid
              const Text('Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Add up to 6 photos', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  final hasPhoto = index < 2;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryPurple),
                                title: const Text('Take Photo'),
                                onTap: () => Navigator.pop(context),
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library_rounded, color: AppColors.neonPink),
                                title: const Text('Choose from Gallery'),
                                onTap: () => Navigator.pop(context),
                              ),
                              if (hasPhoto)
                                ListTile(
                                  leading: const Icon(Icons.delete_rounded, color: AppColors.errorRed),
                                  title: const Text('Remove Photo', style: TextStyle(color: AppColors.errorRed)),
                                  onTap: () => Navigator.pop(context),
                                ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: hasPhoto
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryPurple.withOpacity(0.3),
                                          AppColors.neonPink.withOpacity(0.2),
                                        ],
                                      ),
                                    ),
                                    child: Icon(Icons.person_rounded, size: 50, color: Colors.white.withOpacity(0.2)),
                                  ),
                                  if (index == 0)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: AppColors.primaryGradient),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('Main', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPurple.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_rounded, color: AppColors.primaryPurple, size: 28),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add',
                                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Name
              _buildLabel('Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_rounded, color: AppColors.primaryPurple),
                ),
              ),
              const SizedBox(height: 20),

              // Bio
              _buildLabel('Bio'),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.edit_note_rounded, color: AppColors.primaryPurple),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Gender
              _buildLabel('Gender'),
              const SizedBox(height: 8),
              Row(
                children: ['Male', 'Female', 'Other'].map((g) {
                  final isSelected = _selectedGender == g;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGender = g),
                      child: Container(
                        margin: EdgeInsets.only(right: g != 'Other' ? 10 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryPurple.withOpacity(0.15) : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryPurple : Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            g,
                            style: TextStyle(
                              color: isSelected ? AppColors.lightPurple : Colors.white54,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Age
              _buildLabel('Age'),
              const SizedBox(height: 8),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.cake_rounded, color: AppColors.primaryPurple),
                ),
              ),
              const SizedBox(height: 20),

              // Interests
              _buildLabel('Interests'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Travel', 'Music', 'Photography', 'Coffee', 'Yoga', 'Art', 'Gaming', 'Fitness', 'Cooking', 'Dance']
                    .map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        if (isSelected) {
                          _selectedInterests.remove(interest);
                        } else {
                          _selectedInterests.add(interest);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryPurple.withOpacity(0.2) : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryPurple : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Text(
                        interest,
                        style: TextStyle(
                          color: isSelected ? AppColors.lightPurple : Colors.white54,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Location
              _buildLabel('Location'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.neonPink),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('New York, USA', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            'Last updated 2 days ago',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Update', style: TextStyle(color: AppColors.neonPink)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.primaryGradient),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
  }
}
