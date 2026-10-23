import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late final AnimationController _ambientController;
  late final Animation<Offset> _orb1Offset;
  late final Animation<Offset> _orb2Offset;

  final List<_OnboardingStep> _steps = const [
    _OnboardingStep(
      icon: Icons.hub_rounded,
      iconGradient: AppColors.heroGlowGradient,
      title: 'Discover MANIT Teammates',
      description:
          'Connect with talented developers, UI/UX designers, and problem solvers across CSE, IT, ECE, Mech, Electrical, and all branches at Maulana Azad National Institute of Technology.',
    ),
    _OnboardingStep(
      icon: Icons.emoji_events_rounded,
      iconGradient: AppColors.coralSunsetGradient,
      title: 'Hackathons & Grand Challenges',
      description:
          'Assemble competitive squads for Smart India Hackathon (SIH), internal college hackathons, technical fests, robotics leagues, and startup ventures.',
    ),
    _OnboardingStep(
      icon: Icons.verified_user_rounded,
      iconGradient: AppColors.verifiedManitGradient,
      title: 'Verified Scholar Badges',
      description:
          'Authenticate seamlessly with your institutional @stu.manit.ac.in credentials. Ensure your team roster is genuine, verified, and ready to collaborate directly.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _orb1Offset = Tween<Offset>(
      begin: const Offset(-30, -20),
      end: const Offset(40, 30),
    ).animate(CurvedAnimation(
      parent: _ambientController,
      curve: Curves.easeInOutSine,
    ));

    _orb2Offset = Tween<Offset>(
      begin: const Offset(30, 20),
      end: const Offset(-30, -35),
    ).animate(CurvedAnimation(
      parent: _ambientController,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: Stack(
        children: [
          // Ambient drifting glow spheres
          AnimatedBuilder(
            animation: _ambientController,
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: -60 + _orb1Offset.value.dy,
                    left: -40 + _orb1Offset.value.dx,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0x337C3AED),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40 + _orb2Offset.value.dy,
                    right: -50 + _orb2Offset.value.dx,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0x2806B6D4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: widget.onFinish,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Skip'),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) => setState(() => _currentIndex = index),
                      itemCount: _steps.length,
                      itemBuilder: (context, index) {
                        final step = _steps[index];
                        return Center(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    gradient: step.iconGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x407C3AED),
                                        blurRadius: 28,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(step.icon, size: 48, color: AppColors.white),
                                ),
                                const SizedBox(height: 36),
                                Text(
                                  step.title,
                                  style: AppTypography.headlineLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  step.description,
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? AppColors.electricVioletLight
                              : AppColors.charcoalBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: _currentIndex == _steps.length - 1 ? 'Get Started' : 'Next',
                    onPressed: _nextPage,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  final IconData icon;
  final LinearGradient iconGradient;
  final String title;
  final String description;

  const _OnboardingStep({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.description,
  });
}
