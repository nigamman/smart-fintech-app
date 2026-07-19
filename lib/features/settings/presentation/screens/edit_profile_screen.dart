import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../commons/widgets/loading_indicator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _incomeController;
  late final TextEditingController _savingsGoalController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _incomeController = TextEditingController();
    _savingsGoalController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _incomeController.dispose();
    _savingsGoalController.dispose();
    super.dispose();
  }

  void _initializeValues(dynamic user) {
    if (_initialized) return;
    _nameController.text = user.name;
    _incomeController.text = user.monthlyIncome.toStringAsFixed(0);
    _savingsGoalController.text = user.monthlySavingsGoal.toStringAsFixed(0);
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const LoadingIndicator(),
          error: (err, stack) => Center(
            child: Text('Error loading profile: $err', style: AppTextStyles.body),
          ),
          data: (user) {
            if (user == null) {
              return const Center(child: Text('User profile not found.', style: TextStyle(color: Colors.white)));
            }

            _initializeValues(user);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Profile',
                          style: GoogleFonts.fraunces(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border, width: 1.0),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Inputs list
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                        filled: true,
                        fillColor: AppColors.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.expense, width: 0.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.expense, width: 1.0),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Name is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _incomeController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        labelText: 'Monthly Income',
                        labelStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                        prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppColors.primary, size: 20),
                        filled: true,
                        fillColor: AppColors.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.expense, width: 0.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.expense, width: 1.0),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Income is required';
                        final numVal = double.tryParse(val);
                        if (numVal == null || numVal < 0) return 'Please enter a valid positive amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _savingsGoalController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        labelText: 'Monthly Savings Target',
                        labelStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                        prefixIcon: const Icon(Icons.savings_outlined, color: AppColors.primary, size: 20),
                        filled: true,
                        fillColor: AppColors.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.expense, width: 0.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.expense, width: 1.0),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Savings target is required';
                        final numVal = double.tryParse(val);
                        if (numVal == null || numVal < 0) return 'Please enter a valid positive amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          if (!_formKey.currentState!.validate()) return;
                          final incomeVal = double.parse(_incomeController.text);
                          final savingsVal = double.parse(_savingsGoalController.text);
                          final messenger = ScaffoldMessenger.of(context);
                          
                          try {
                            await ref.read(profileControllerProvider.notifier).updateProfile(
                                  user: user,
                                  name: _nameController.text.trim(),
                                  monthlyIncome: incomeVal,
                                  monthlySavingsGoal: savingsVal,
                                );
                            ref.invalidate(userProfileStreamProvider);
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Profile updated successfully!')),
                            );
                            context.pop();
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to update: $e')),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: AppColors.background,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
