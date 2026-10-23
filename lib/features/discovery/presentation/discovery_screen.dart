import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/gradient_card.dart';
import '../../../core/widgets/manit_badge.dart';
import '../../../core/widgets/state_views.dart';
import '../../profiles/domain/user_profile.dart';
import '../../profiles/presentation/student_detail_screen.dart';
import '../../teams/domain/team.dart';
import '../../teams/presentation/create_team_screen.dart';
import '../../teams/presentation/team_detail_screen.dart';
import '../domain/discovery_filter.dart';
import '../services/student_discovery_repository.dart';
import '../../joining_requests/services/join_request_repository.dart';

enum DiscoveryMode {
  teams('Broadcasts'),
  scholars('Scholars');

  final String label;
  const DiscoveryMode(this.label);
}

class DiscoveryScreen extends StatefulWidget {
  final VoidCallback? onOpenCreateTeam;

  const DiscoveryScreen({super.key, this.onOpenCreateTeam});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  DiscoveryMode _mode = DiscoveryMode.teams;
  DiscoveryFilter _filter = const DiscoveryFilter();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scholarScrollController = ScrollController();
  Timer? _debounceTimer;

  static const int _pageSize = 12;
  int _scholarOffset = 0;
  bool _hasMoreScholars = false;
  bool _isLoadingMoreScholars = false;

  List<Team> _teams = [];
  List<UserProfile> _scholars = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scholarScrollController.addListener(_onScholarScroll);
    _fetchData();
  }

  void _onScholarScroll() {
    if (_scholarScrollController.position.pixels >=
        _scholarScrollController.position.maxScrollExtent - 200) {
      if (_hasMoreScholars && !_isLoadingMoreScholars && !_isLoading) {
        _loadMoreScholars();
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scholarScrollController.removeListener(_onScholarScroll);
    _scholarScrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _filter = _filter.copyWith(query: query.trim());
      });
      if (_mode == DiscoveryMode.scholars) {
        _fetchScholars(reset: true);
      }
    });
  }

  Future<void> _fetchData() async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized) {
      setState(() {
        _teams = [];
        _scholars = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch Teams
      final teamsRes = await supabase.client!
          .from('teams')
          .select()
          .order('created_at', ascending: false);

      final List<Team> loadedTeams = (teamsRes as List<dynamic>)
          .map((item) => Team.fromJson(item as Map<String, dynamic>))
          .toList();

      // 2. Fetch Scholars using StudentDiscoveryRepository
      final scholarResult = await StudentDiscoveryRepository.instance.fetchStudents(
        filter: _filter,
        offset: 0,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          _teams = loadedTeams;
          _scholars = scholarResult.students;
          _scholarOffset = scholarResult.offset;
          _hasMoreScholars = scholarResult.hasMore;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchScholars({bool reset = false}) async {
    final offset = reset ? 0 : _scholarOffset;
    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final result = await StudentDiscoveryRepository.instance.fetchStudents(
      filter: _filter,
      offset: offset,
      limit: _pageSize,
    );

    if (!mounted) return;

    if (result.errorMessage != null) {
      setState(() {
        _errorMessage = result.errorMessage;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      if (reset) {
        _scholars = result.students;
      } else {
        _scholars.addAll(result.students);
      }
      _scholarOffset = result.offset;
      _hasMoreScholars = result.hasMore;
      _isLoading = false;
    });
  }

  Future<void> _loadMoreScholars() async {
    if (_isLoadingMoreScholars || !_hasMoreScholars) return;

    setState(() {
      _isLoadingMoreScholars = true;
    });

    final result = await StudentDiscoveryRepository.instance.fetchStudents(
      filter: _filter,
      offset: _scholarOffset,
      limit: _pageSize,
    );

    if (!mounted) return;

    setState(() {
      _scholars.addAll(result.students);
      _scholarOffset = result.offset;
      _hasMoreScholars = result.hasMore;
      _isLoadingMoreScholars = false;
    });
  }

  List<Team> get _filteredTeams {
    return _teams.where((team) {
      if (_filter.onlyRecruiting && !team.isRecruiting) return false;
      if (_filter.category != null && team.projectCategory != _filter.category) {
        return false;
      }
      if (_filter.onlyVerifiedManit && !team.ownerIsManitVerified) {
        return false;
      }
      if (_filter.skill != null && _filter.skill!.isNotEmpty) {
        final target = _filter.skill!.toLowerCase();
        final match = team.requiredSkills.any((s) => s.toLowerCase().contains(target));
        if (!match) return false;
      }
      if (_filter.eventName != null && _filter.eventName!.isNotEmpty) {
        final target = _filter.eventName!.toLowerCase();
        if (!team.eventName.toLowerCase().contains(target)) {
          return false;
        }
      }
      if (_filter.query.isNotEmpty) {
        final q = _filter.query.toLowerCase();
        final matchTitle = team.title.toLowerCase().contains(q);
        final matchEvent = team.eventName.toLowerCase().contains(q);
        final matchDesc = team.description.toLowerCase().contains(q);
        final matchSkills = team.requiredSkills.any((s) => s.toLowerCase().contains(q));
        if (!matchTitle && !matchEvent && !matchDesc && !matchSkills) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.charcoalSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Discovery Filters', style: AppTypography.titleLarge),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filter = const DiscoveryFilter();
                              _searchController.clear();
                            });
                            Navigator.of(ctx).pop();
                            _fetchScholars(reset: true);
                          },
                          child: const Text('Reset All', style: TextStyle(color: AppColors.coralLight)),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.charcoalBorder),
                    const SizedBox(height: 12),

                    // Sort By Criteria
                    Text('Sort By', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ScholarSortBy.values.map((sortOption) {
                        final isSelected = _filter.sortBy == sortOption;
                        return ChoiceChip(
                          label: Text(sortOption.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                _filter = _filter.copyWith(sortBy: sortOption);
                              });
                              setState(() {});
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // College Membership Filters
                    Text('College Membership', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All Categories'),
                          selected: !_filter.onlyManitStudents &&
                              !_filter.onlyVerifiedManit &&
                              !_filter.onlyOtherCollegeStudents &&
                              _filter.membershipCategory == null,
                          onSelected: (_) {
                            setModalState(() {
                              _filter = _filter.copyWith(
                                onlyManitStudents: false,
                                onlyVerifiedManit: false,
                                onlyOtherCollegeStudents: false,
                                membershipCategory: null,
                              );
                            });
                            setState(() {});
                          },
                        ),
                        FilterChip(
                          label: const Text('MANIT Students'),
                          selected: _filter.onlyManitStudents && !_filter.onlyVerifiedManit,
                          onSelected: (selected) {
                            setModalState(() {
                              _filter = _filter.copyWith(
                                onlyManitStudents: selected,
                                onlyVerifiedManit: false,
                                onlyOtherCollegeStudents: false,
                                membershipCategory: selected ? MembershipStatus.manitStudent : null,
                              );
                            });
                            setState(() {});
                          },
                        ),
                        FilterChip(
                          avatar: const Icon(Icons.verified_rounded, size: 16, color: AppColors.statusSuccess),
                          label: const Text('Verified MANIT Only'),
                          selected: _filter.onlyVerifiedManit,
                          onSelected: (selected) {
                            setModalState(() {
                              _filter = _filter.copyWith(
                                onlyVerifiedManit: selected,
                                onlyManitStudents: selected ? true : _filter.onlyManitStudents,
                                onlyOtherCollegeStudents: false,
                                membershipCategory: selected ? MembershipStatus.manitStudent : null,
                              );
                            });
                            setState(() {});
                          },
                        ),
                        FilterChip(
                          avatar: const Icon(Icons.school_outlined, size: 16, color: AppColors.cyanLight),
                          label: const Text('Other Colleges'),
                          selected: _filter.onlyOtherCollegeStudents,
                          onSelected: (selected) {
                            setModalState(() {
                              _filter = _filter.copyWith(
                                onlyOtherCollegeStudents: selected,
                                onlyManitStudents: false,
                                onlyVerifiedManit: false,
                                membershipCategory: selected ? MembershipStatus.otherCollege : null,
                              );
                            });
                            setState(() {});
                          },
                        ),
                        FilterChip(
                          label: const Text('Non-students'),
                          selected: _filter.membershipCategory == MembershipStatus.nonStudent,
                          onSelected: (selected) {
                            setModalState(() {
                              _filter = _filter.copyWith(
                                membershipCategory: selected ? MembershipStatus.nonStudent : null,
                                onlyManitStudents: false,
                                onlyVerifiedManit: false,
                                onlyOtherCollegeStudents: false,
                              );
                            });
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Branch Filter
                    Text('Branch / Department', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: _filter.branch,
                      dropdownColor: AppColors.charcoalSurfaceElevated,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Department Filter',
                        prefixIcon: Icon(Icons.category_outlined, color: AppColors.textMuted),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Branches')),
                        DropdownMenuItem(value: 'Computer Science', child: Text('Computer Science & Engineering')),
                        DropdownMenuItem(value: 'Information Technology', child: Text('Information Technology')),
                        DropdownMenuItem(value: 'Electronics', child: Text('Electronics & Communication')),
                        DropdownMenuItem(value: 'Electrical', child: Text('Electrical Engineering')),
                        DropdownMenuItem(value: 'Mechanical', child: Text('Mechanical Engineering')),
                        DropdownMenuItem(value: 'Civil', child: Text('Civil Engineering')),
                        DropdownMenuItem(value: 'Chemical', child: Text('Chemical Engineering')),
                        DropdownMenuItem(value: 'Postgraduate', child: Text('Postgraduate / PhD')),
                      ],
                      onChanged: (val) {
                        setModalState(() => _filter = _filter.copyWith(branch: val));
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),

                    // Academic Year Filter
                    Text('Academic Year', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: _filter.academicYear,
                      dropdownColor: AppColors.charcoalSurfaceElevated,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Year Filter',
                        prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textMuted),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Academic Years')),
                        DropdownMenuItem(value: '1st Year', child: Text('1st Year B.Tech')),
                        DropdownMenuItem(value: '2nd Year', child: Text('2nd Year B.Tech')),
                        DropdownMenuItem(value: '3rd Year', child: Text('3rd Year B.Tech')),
                        DropdownMenuItem(value: '4th Year', child: Text('4th Year B.Tech')),
                        DropdownMenuItem(value: 'Postgraduate', child: Text('Postgraduate / PhD')),
                      ],
                      onChanged: (val) {
                        setModalState(() => _filter = _filter.copyWith(academicYear: val));
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),

                    // Skills Filter
                    Text('Technical Skills', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Flutter', 'AI/ML', 'Python', 'React', 'Cloud', 'IoT', 'UI/UX', 'System Design'].map((skill) {
                        final isSelected = _filter.skill?.toLowerCase() == skill.toLowerCase();
                        return FilterChip(
                          label: Text(skill),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              _filter = _filter.copyWith(skill: selected ? skill : null);
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Interests Filter
                    Text('Areas of Interest', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Hackathons', 'Research', 'Open Source', 'Startups', 'Web3', 'Robotics'].map((interest) {
                        final isSelected = _filter.interest?.toLowerCase() == interest.toLowerCase();
                        return FilterChip(
                          label: Text(interest),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              _filter = _filter.copyWith(interest: selected ? interest : null);
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (_mode == DiscoveryMode.scholars) {
                          _fetchScholars(reset: true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      floatingActionButton: _mode == DiscoveryMode.teams
          ? FloatingActionButton.extended(
              onPressed: () {
                if (widget.onOpenCreateTeam != null) {
                  widget.onOpenCreateTeam!();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateTeamScreen(onCreated: _fetchData),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Launch Team'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          if (_mode == DiscoveryMode.scholars) {
            await _fetchScholars(reset: true);
          } else {
            await _fetchData();
          }
        },
        color: AppColors.electricVioletLight,
        backgroundColor: AppColors.charcoalSurfaceElevated,
        child: Column(
          children: [
            // Mode Toggle Bar (Broadcasts vs Scholars)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: AppColors.charcoalSurface,
              child: SegmentedButton<DiscoveryMode>(
                segments: [
                  ButtonSegment(
                    value: DiscoveryMode.teams,
                    label: Text(DiscoveryMode.teams.label),
                    icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: DiscoveryMode.scholars,
                    label: Text(DiscoveryMode.scholars.label),
                    icon: const Icon(Icons.school_outlined, size: 18),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (newSelection) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _mode = newSelection.first;
                  });
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),

            // Search & Filter Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              color: AppColors.charcoalSurface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: _mode == DiscoveryMode.teams
                            ? 'Search broadcasts, hackathons, skills...'
                            : 'Search students by name, skills, bio...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                        suffixIcon: _filter.query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    children: [
                      IconButton.filledTonal(
                        onPressed: _openFilterSheet,
                        icon: const Icon(Icons.tune_rounded),
                        tooltip: 'Filter criteria',
                      ),
                      if (_filter.hasActiveFilters)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.statusSuccess,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick Filter Chips Bar
            Container(
              width: double.infinity,
              color: AppColors.charcoalSurface,
              padding: const EdgeInsets.only(bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _mode == DiscoveryMode.teams
                      ? _buildTeamQuickChips()
                      : _buildScholarQuickChips(),
                ),
              ),
            ),

            // Main Content Area
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTeamQuickChips() {
    final chips = <Widget>[];

    // All
    final isAll = !_filter.onlyRecruiting &&
        !_filter.onlyVerifiedManit &&
        _filter.category == null;
    chips.add(_buildFilterChip(
      label: 'All Broadcasts',
      isSelected: isAll,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _filter = _filter.copyWith(
            onlyRecruiting: false,
            onlyVerifiedManit: false,
            category: null,
          );
        });
      },
    ));

    // Recruiting
    chips.add(_buildFilterChip(
      label: '⚡ Open Vacancies',
      isSelected: _filter.onlyRecruiting,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _filter = _filter.copyWith(onlyRecruiting: !_filter.onlyRecruiting);
        });
      },
    ));

    // Verified
    chips.add(_buildFilterChip(
      label: '✓ MANIT Verified',
      isSelected: _filter.onlyVerifiedManit,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _filter = _filter.copyWith(onlyVerifiedManit: !_filter.onlyVerifiedManit);
        });
      },
    ));

    // Hackathon Category
    final isHackathon = _filter.category == ProjectCategory.hackathon;
    chips.add(_buildFilterChip(
      label: '🏆 Hackathon',
      isSelected: isHackathon,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _filter = _filter.copyWith(category: isHackathon ? null : ProjectCategory.hackathon);
        });
      },
    ));

    // AI/ML Category
    final isAi = _filter.category == ProjectCategory.aiMl;
    chips.add(_buildFilterChip(
      label: '🤖 AI / ML',
      isSelected: isAi,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _filter = _filter.copyWith(category: isAi ? null : ProjectCategory.aiMl);
        });
      },
    ));

    return chips;
  }

  List<Widget> _buildScholarQuickChips() {
    final chips = <Widget>[];

    // All
    final isAll = !_filter.onlyVerifiedManit &&
        _filter.membershipCategory == null &&
        _filter.skill == null;
    chips.add(_buildFilterChip(
      label: 'All Scholars',
      isSelected: isAll,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _filter = _filter.copyWith(
            onlyVerifiedManit: false,
            membershipCategory: null,
            skill: null,
          );
        });
        _fetchScholars(reset: true);
      },
    ));

    // Verified Only
    chips.add(_buildFilterChip(
      label: '✓ Verified Scholar',
      isSelected: _filter.onlyVerifiedManit,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _filter = _filter.copyWith(onlyVerifiedManit: !_filter.onlyVerifiedManit);
        });
        _fetchScholars(reset: true);
      },
    ));

    // Skills
    for (final skill in ['Flutter', 'AI/ML', 'Python', 'UI/UX']) {
      final isSelected = _filter.skill?.toLowerCase() == skill.toLowerCase();
      chips.add(_buildFilterChip(
        label: skill,
        isSelected: isSelected,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _filter = _filter.copyWith(skill: isSelected ? null : skill);
          });
          _fetchScholars(reset: true);
        },
      ));
    }

    return chips;
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.electricVioletSubtle
                : AppColors.charcoalSurfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.electricVioletLight
                  : AppColors.charcoalBorder,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppColors.electricVioletGlow
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          CardSkeleton(height: 170),
          CardSkeleton(height: 170),
          CardSkeleton(height: 170),
        ],
      );
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: () {
          if (_mode == DiscoveryMode.scholars) {
            _fetchScholars(reset: true);
          } else {
            _fetchData();
          }
        },
      );
    }

    if (_mode == DiscoveryMode.teams) {
      final displayedTeams = _filteredTeams;
      if (displayedTeams.isEmpty) {
        return EmptyStateView(
          icon: Icons.groups_outlined,
          title: 'No Teams Found',
          message: _filter.hasActiveFilters
              ? 'No team broadcasts match the active criteria. Broaden your filters.'
              : 'No active team broadcasts found. Launch the first team roster!',
          actionLabel: 'Launch a Team',
          onAction: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateTeamScreen(onCreated: _fetchData),
              ),
            );
          },
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: displayedTeams.length,
        itemBuilder: (context, index) {
          final team = displayedTeams[index];
          return StaggeredEntrance(
            index: index,
            child: _TeamDiscoveryCard(
              team: team,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TeamDetailScreen(
                      team: team,
                      onTeamModified: _fetchData,
                    ),
                  ),
                );
              },
              onApply: () => _showApplySheet(team),
            ),
          );
        },
      );
    } else {
      if (_scholars.isEmpty) {
        return EmptyStateView(
          icon: Icons.person_search_outlined,
          title: 'No Scholars Found',
          message: _filter.hasActiveFilters
              ? 'No teammates match the selected membership, skill, or interest criteria.'
              : 'No public scholar profiles found. Be the first to share your skills!',
          actionLabel: _filter.hasActiveFilters ? 'Clear Filters' : null,
          onAction: _filter.hasActiveFilters
              ? () {
                  setState(() {
                    _filter = const DiscoveryFilter();
                    _searchController.clear();
                  });
                  _fetchScholars(reset: true);
                }
              : null,
        );
      }

      return ListView.builder(
        controller: _scholarScrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _scholars.length + (_hasMoreScholars ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _scholars.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: _isLoadingMoreScholars
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                        label: const Text('Load More Scholars'),
                        onPressed: _loadMoreScholars,
                      ),
              ),
            );
          }

          final scholar = _scholars[index];
          return StaggeredEntrance(
            index: index,
            child: _ScholarDiscoveryCard(
              scholar: scholar,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudentDetailScreen(student: scholar),
                  ),
                );
              },
            ),
          );
        },
      );
    }
  }

  void _showApplySheet(Team team) {
    final noteController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.charcoalSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Request to Join', style: AppTypography.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Pitch your skills to ${team.ownerName} for "${team.title}"',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Share your background, GitHub/portfolio, and what you will build...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() => isSubmitting = true);
                            final text = noteController.text.trim();
                            final res = await JoinRequestRepository.instance.submitJoinRequest(
                              teamId: team.id,
                              message: text,
                            );

                            if (ctx.mounted) {
                              setModalState(() => isSubmitting = false);
                              Navigator.of(ctx).pop();
                            }

                            if (!mounted) return;

                            if (res.isSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(child: Text('Join request submitted successfully!')),
                                    ],
                                  ),
                                  backgroundColor: AppColors.charcoalSurfaceElevated,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res.errorMessage ?? 'Failed to submit join request.'),
                                  backgroundColor: AppColors.statusError,
                                ),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                          )
                        : const Text('Submit Pitch'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TeamDiscoveryCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;
  final VoidCallback onApply;

  const _TeamDiscoveryCard({
    required this.team,
    required this.onTap,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.title, style: AppTypography.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      team.eventName,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (team.isRecruiting && team.vacanciesLeft > 0)
                ManitBadge.vacancies(team.vacanciesLeft)
              else
                const ManitBadge(
                  label: 'Roster Full',
                  variant: ManitBadgeVariant.openVacancies,
                  icon: Icons.lock_outline_rounded,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(team.description, style: AppTypography.bodyMedium),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: team.requiredSkills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.charcoalSurfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.charcoalBorder, width: 0.8),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(fontSize: 11, color: AppColors.cyanLight),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.electricVioletSubtle,
                    child: Text(
                      team.ownerName.isNotEmpty ? team.ownerName[0] : 'O',
                      style: const TextStyle(fontSize: 10, color: AppColors.electricVioletGlow),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    team.ownerName,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  if (team.ownerIsManitVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, size: 14, color: AppColors.statusSuccess),
                  ],
                ],
              ),
              ElevatedButton(
                onPressed: team.isRecruiting ? onApply : null,
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _ScholarDiscoveryCard extends StatelessWidget {
  final UserProfile scholar;
  final VoidCallback onTap;

  const _ScholarDiscoveryCard({
    required this.scholar,
    required this.onTap,
  });

  Widget _buildBadge() {
    if (scholar.membershipStatus == null) {
      return ManitBadge.notSpecified();
    }
    switch (scholar.membershipStatus!) {
      case MembershipStatus.manitStudent:
        if (scholar.verificationStatus == VerificationStatus.verified) {
          return ManitBadge.verified(label: 'MANIT Verified');
        } else if (scholar.verificationStatus == VerificationStatus.pendingReview) {
          return const ManitBadge(
            label: 'MANIT Student — Review Pending',
            variant: ManitBadgeVariant.unverifiedStudent,
            icon: Icons.hourglass_top_rounded,
          );
        } else if (scholar.verificationStatus == VerificationStatus.rejected) {
          return const ManitBadge(
            label: 'MANIT Student — Declined',
            variant: ManitBadgeVariant.unverifiedStudent,
            icon: Icons.cancel_outlined,
          );
        } else {
          return ManitBadge.unverified(label: 'MANIT Student — Unverified');
        }
      case MembershipStatus.otherCollege:
        return ManitBadge.otherCollege(
          scholar.collegeName.isNotEmpty ? scholar.collegeName : 'Other College',
        );
      case MembershipStatus.nonStudent:
        return ManitBadge.nonStudent(label: 'Non-student');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Note: Strictly protects sensitive student IDs, contact numbers, and private documents
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GradientCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.electricVioletSubtle,
                  child: Text(
                    scholar.fullName.isNotEmpty ? scholar.fullName[0].toUpperCase() : 'M',
                    style: const TextStyle(color: AppColors.electricVioletGlow, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scholar.fullName, style: AppTypography.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${scholar.branch} • ${scholar.academicYear}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                _buildBadge(),
              ],
            ),
            if (scholar.bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                scholar.bio,
                style: AppTypography.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (scholar.skills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: scholar.skills.map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.charcoalSurfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.charcoalBorder, width: 0.8),
                    ),
                    child: Text(s, style: const TextStyle(fontSize: 11, color: AppColors.cyanLight)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View Profile',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.electricVioletLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.electricVioletLight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
