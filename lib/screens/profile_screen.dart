import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/providers/user_provider.dart';
import 'package:vespera/screens/common_screen.dart';
import 'package:vespera/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.username == 'User') {
        userProvider.loadUserData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final username = userProvider.username.trim();
    final capitalizedUsername = username.isEmpty ? 'User' : username[0].toUpperCase() + username.substring(1);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textMuted,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showEditProfileDialog(userProvider),
            icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.textMuted),
            label: const Text(
              'Edit',
              style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.textPrimary,
          backgroundColor: AppColors.cardBackground,
          onRefresh: () async {
            await userProvider.loadUserData();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _ProfileHeroHeader(
                username: capitalizedUsername,
                email: userProvider.email,
                profilePictureUrl: userProvider.profilePicture,
                onEditPhotoTap: () => _showEditProfileDialog(userProvider),
              ),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'Listening Insights'),
              const SizedBox(height: 10),
              _buildListeningInsights(),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Personalization'),
              const SizedBox(height: 10),
              _buildPersonalizationFromSearches(),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Playlists'),
              const SizedBox(height: 10),
              _buildLibraryLink(),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Account & Security'),
              const SizedBox(height: 10),
              _buildAccountSecurity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListeningInsights() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const _FallbackCard(message: 'Sign in to view listening insights.');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('listeningSessions').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 108,
            child: Center(child: CircularProgressIndicator(color: AppColors.textPrimary)),
          );
        }

        if (snapshot.hasError) {
          return const _FallbackCard(message: 'Could not load listening insights right now.');
        }

        final docs = snapshot.data?.docs ?? const [];
        final insights = _ListeningInsights.fromSessionDocs(docs);

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _AnalyticsCard(
                    label: 'Daily',
                    value: _formatDuration(insights.daily),
                    accentColor: AppColors.accentBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AnalyticsCard(
                    label: 'Weekly',
                    value: _formatDuration(insights.weekly),
                    accentColor: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AnalyticsCard(
                    label: 'All-time',
                    value: _formatDuration(insights.allTime),
                    accentColor: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _FallbackCard(
              message: insights.streakDays > 0
                  ? 'Listening streak: ${insights.streakDays} day${insights.streakDays == 1 ? '' : 's'}'
                  : 'No active streak yet. Listen daily to build one.',
            ),
            const SizedBox(height: 10),
            _TopListCard(
              title: 'Top Artists',
              thisWeekItems: insights.topArtistsWeek,
              allTimeItems: insights.topArtistsAllTime,
            ),
            const SizedBox(height: 10),
            _TopListCard(
              title: 'Top Songs',
              thisWeekItems: insights.topSongsWeek,
              allTimeItems: insights.topSongsAllTime,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPersonalizationFromSearches() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const _FallbackCard(message: 'Sign in to personalize your profile.');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('recentSongSearches')
          .orderBy('updatedAt', descending: true)
          .limit(25)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator(color: AppColors.textPrimary)),
          );
        }

        if (snapshot.hasError) {
          return const _FallbackCard(message: 'Could not load personalization tags right now.');
        }

        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const _FallbackCard(message: 'Search for songs to unlock your profile tags.');
        }

        final tags = _buildProfileTagsFromSearches(docs);
        if (tags.isEmpty) {
          return const _FallbackCard(message: 'Not enough search data to build tags yet.');
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider.withOpacity(0.4)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundMedium,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.divider.withOpacity(0.35)),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  List<String> _buildProfileTagsFromSearches(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final artistCounts = <String, int>{};
    final moodCounts = <String, int>{};

    for (final doc in docs) {
      final data = doc.data();
      final artist = (data['artist'] as String?)?.trim() ?? '';
      final title = (data['title'] as String?)?.toLowerCase().trim() ?? '';

      if (artist.isNotEmpty) {
        artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
      }

      final moods = _extractMoodsFromTitle(title);
      for (final mood in moods) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }

    final topArtists = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final tags = <String>[];
    for (final artist in topArtists.take(3)) {
      tags.add('Fan of ${artist.key}');
    }
    for (final mood in topMoods.take(3)) {
      tags.add(mood.key);
    }

    if (tags.length < 5) {
      tags.add('Music Explorer');
    }

    return tags.take(6).toList();
  }

  List<String> _extractMoodsFromTitle(String title) {
    if (title.isEmpty) return const [];

    const moodMap = {
      'chill': ['chill', 'calm', 'relax', 'lofi', 'ambient'],
      'hype': ['hype', 'party', 'dance', 'club', 'drop'],
      'romantic': ['love', 'heart', 'romance', 'kiss'],
      'sad vibes': ['sad', 'lonely', 'cry', 'broken'],
      'focus': ['study', 'focus', 'work', 'instrumental'],
      'throwback': ['classic', 'retro', 'old', 'nostalgia'],
    };

    final matched = <String>[];
    for (final entry in moodMap.entries) {
      for (final keyword in entry.value) {
        if (title.contains(keyword)) {
          matched.add(entry.key);
          break;
        }
      }
    }
    return matched;
  }

  Widget _buildLibraryLink() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const CommonScreen(initialIndex: 2)),
            (route) => false,
          );
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withOpacity(0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.library_music_rounded, color: AppColors.textPrimary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Go to your Library',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSecurity() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.alternate_email_rounded, color: AppColors.textPrimary),
            title: const Text('Change email', style: TextStyle(color: AppColors.textPrimary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            onTap: _showChangeEmailDialog,
          ),
          Divider(height: 1, color: AppColors.divider.withOpacity(0.35)),
          ListTile(
            leading: const Icon(Icons.password_rounded, color: AppColors.textPrimary),
            title: const Text('Change password', style: TextStyle(color: AppColors.textPrimary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            onTap: _showChangePasswordDialog,
          ),
          Divider(height: 1, color: AppColors.divider.withOpacity(0.35)),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
            title: const Text('Delete account', style: TextStyle(color: AppColors.error)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog(UserProvider userProvider) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to edit profile.')),
      );
      return;
    }

    final nameController = TextEditingController(text: userProvider.username);
    final photoController = TextEditingController(text: userProvider.profilePicture);
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: const Text('Edit Profile', style: TextStyle(color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: photoController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Profile Photo URL',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final updatedName = nameController.text.trim();
                          final updatedPhoto = photoController.text.trim();

                          if (updatedName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Username cannot be empty.')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          try {
                            await _authService.updateUserProfile(
                              uid: uid,
                              name: updatedName,
                              profilePicture: updatedPhoto,
                            );
                            await userProvider.loadUserData();

                            if (!mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile updated successfully.')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update profile: $e')),
                            );
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    photoController.dispose();
  }

  Future<void> _showChangeEmailDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final emailController = TextEditingController(text: currentUser.email ?? '');
    final passwordController = TextEditingController();
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: const Text('Change Email', style: TextStyle(color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'New email',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newEmail = emailController.text.trim();
                          final password = passwordController.text;
                          if (newEmail.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Email and password are required.')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            await _authService.changeEmail(
                              newEmail: newEmail,
                              currentPassword: password,
                            );
                            if (!mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Verification email sent. Confirm new email to finish update.'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: const Text('Change Password', style: TextStyle(color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'New password',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final currentPassword = currentPasswordController.text;
                          final newPassword = newPasswordController.text;

                          if (currentPassword.isEmpty || newPassword.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enter current password and a new password (min 6 chars).'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            await _authService.changePassword(
                              currentPassword: currentPassword,
                              newPassword: newPassword,
                            );
                            if (!mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password updated successfully.')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
  }

  Future<void> _showDeleteAccountDialog() async {
    final passwordController = TextEditingController();
    bool isDeleting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: const Text('Delete Account', style: TextStyle(color: AppColors.error)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This permanently deletes your account and profile data. This action cannot be undone.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          final password = passwordController.text;
                          if (password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password is required to delete account.')),
                            );
                            return;
                          }

                          setDialogState(() => isDeleting = true);
                          try {
                            await _authService.deleteAccount(currentPassword: password);
                            if (!mounted) return;

                            Provider.of<UserProvider>(context, listen: false).clearUserData();
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context, rootNavigator: true)
                                .pushNamedAndRemoveUntil('/welcome', (route) => false);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                            setDialogState(() => isDeleting = false);
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
  }

  String _formatDuration(Duration duration) {
    final totalHours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (totalHours > 0) return '${totalHours}h ${minutes}m';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return '${duration.inSeconds}s';
  }
}

class _ProfileHeroHeader extends StatelessWidget {
  final String username;
  final String email;
  final String profilePictureUrl;
  final VoidCallback onEditPhotoTap;

  const _ProfileHeroHeader({
    required this.username,
    required this.email,
    required this.profilePictureUrl,
    required this.onEditPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasNetworkImage =
        profilePictureUrl.trim().isNotEmpty &&
        (profilePictureUrl.startsWith('http://') || profilePictureUrl.startsWith('https://'));

    final displayName = username.trim().isEmpty ? 'User' : username.trim();
    final initials = displayName.isEmpty ? 'U' : displayName[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 54,
                backgroundColor: AppColors.primaryBlue,
                backgroundImage: hasNetworkImage ? NetworkImage(profilePictureUrl) : null,
                child: hasNetworkImage
                    ? null
                    : Text(
                        initials,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              Positioned(
                right: -6,
                bottom: -6,
                child: Material(
                  color: AppColors.buttonPrimary,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: onEditPhotoTap,
                    icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.textPrimary),
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email.isEmpty ? 'No email found' : email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(child: _StatPill(label: 'Followers', value: '0')),
              SizedBox(width: 10),
              Expanded(child: _StatPill(label: 'Following', value: '0')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _AnalyticsCard({required this.label, required this.value, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TopListCard extends StatelessWidget {
  final String title;
  final List<_TopItem> thisWeekItems;
  final List<_TopItem> allTimeItems;

  const _TopListCard({
    required this.title,
    required this.thisWeekItems,
    required this.allTimeItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _TopListGroup(label: 'This week', items: thisWeekItems),
          const SizedBox(height: 6),
          _TopListGroup(label: 'All-time', items: allTimeItems),
        ],
      ),
    );
  }
}

class _TopListGroup extends StatelessWidget {
  final String label;
  final List<_TopItem> items;

  const _TopListGroup({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        if (items.isEmpty)
          const Text(
            'No data yet',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          )
        else
          ...items.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${entry.key + 1}. ${entry.value.label} (${entry.value.count})',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                ),
              ),
      ],
    );
  }
}

class _FallbackCard extends StatelessWidget {
  final String message;

  const _FallbackCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withOpacity(0.4)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}

class _TopItem {
  final String label;
  final int count;

  const _TopItem({required this.label, required this.count});
}

class _ListeningInsights {
  final Duration daily;
  final Duration weekly;
  final Duration allTime;
  final int streakDays;
  final List<_TopItem> topArtistsWeek;
  final List<_TopItem> topArtistsAllTime;
  final List<_TopItem> topSongsWeek;
  final List<_TopItem> topSongsAllTime;

  const _ListeningInsights({
    required this.daily,
    required this.weekly,
    required this.allTime,
    required this.streakDays,
    required this.topArtistsWeek,
    required this.topArtistsAllTime,
    required this.topSongsWeek,
    required this.topSongsAllTime,
  });

  factory _ListeningInsights.fromSessionDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    final dailyThreshold = now.subtract(const Duration(days: 1));
    final weeklyThreshold = now.subtract(const Duration(days: 7));

    var dailySeconds = 0;
    var weeklySeconds = 0;
    var allTimeSeconds = 0;

    final allArtistCounts = <String, int>{};
    final weeklyArtistCounts = <String, int>{};
    final allSongCounts = <String, int>{};
    final weeklySongCounts = <String, int>{};
    final activeDays = <DateTime>{};

    for (final doc in docs) {
      final data = doc.data();
      final sessionSeconds = _extractSessionSeconds(data);
      allTimeSeconds += sessionSeconds;

      final listenedAt = _extractSessionTime(data);
      if (listenedAt != null) {
        final day = DateTime(listenedAt.year, listenedAt.month, listenedAt.day);
        activeDays.add(day);

        if (listenedAt.isAfter(weeklyThreshold)) {
          weeklySeconds += sessionSeconds;
        }

        if (listenedAt.isAfter(dailyThreshold)) {
          dailySeconds += sessionSeconds;
        }
      }

      final artist = ((data['artist'] as String?) ?? '').trim();
      if (artist.isNotEmpty) {
        allArtistCounts[artist] = (allArtistCounts[artist] ?? 0) + 1;
        if (listenedAt != null && listenedAt.isAfter(weeklyThreshold)) {
          weeklyArtistCounts[artist] = (weeklyArtistCounts[artist] ?? 0) + 1;
        }
      }

      final title = ((data['title'] as String?) ?? '').trim();
      if (title.isNotEmpty) {
        final songLabel = artist.isEmpty ? title : '$title - $artist';
        allSongCounts[songLabel] = (allSongCounts[songLabel] ?? 0) + 1;
        if (listenedAt != null && listenedAt.isAfter(weeklyThreshold)) {
          weeklySongCounts[songLabel] = (weeklySongCounts[songLabel] ?? 0) + 1;
        }
      }
    }

    return _ListeningInsights(
      daily: Duration(seconds: dailySeconds),
      weekly: Duration(seconds: weeklySeconds),
      allTime: Duration(seconds: allTimeSeconds),
      streakDays: _calculateStreak(activeDays),
      topArtistsWeek: _toTopItems(weeklyArtistCounts),
      topArtistsAllTime: _toTopItems(allArtistCounts),
      topSongsWeek: _toTopItems(weeklySongCounts),
      topSongsAllTime: _toTopItems(allSongCounts),
    );
  }

  static int _calculateStreak(Set<DateTime> activeDays) {
    if (activeDays.isEmpty) return 0;

    final sorted = activeDays.toList()..sort((a, b) => b.compareTo(a));
    DateTime cursor = sorted.first;
    var streak = 0;

    while (activeDays.contains(DateTime(cursor.year, cursor.month, cursor.day))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  static List<_TopItem> _toTopItems(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => _TopItem(label: e.key, count: e.value)).toList();
  }

  static int _extractSessionSeconds(Map<String, dynamic> data) {
    final durationSeconds = data['durationSeconds'];
    if (durationSeconds is int) return durationSeconds;
    if (durationSeconds is double) return durationSeconds.round();

    final durationMs = data['durationMs'];
    if (durationMs is int) return (durationMs / 1000).round();
    if (durationMs is double) return (durationMs / 1000).round();

    final durationMinutes = data['durationMinutes'];
    if (durationMinutes is int) return durationMinutes * 60;
    if (durationMinutes is double) return (durationMinutes * 60).round();

    final durationString = data['duration'];
    if (durationString is String) {
      final seconds = _parseDurationString(durationString);
      if (seconds >= 0) return seconds;
    }

    return 0;
  }

  static DateTime? _extractSessionTime(Map<String, dynamic> data) {
    final listenedAt = data['listenedAt'];
    if (listenedAt is Timestamp) return listenedAt.toDate();

    final startedAt = data['startedAt'];
    if (startedAt is Timestamp) return startedAt.toDate();

    final playedAt = data['playedAt'];
    if (playedAt is Timestamp) return playedAt.toDate();

    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();

    return null;
  }

  static int _parseDurationString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return -1;

    final chunks = trimmed.split(':');
    if (chunks.length == 2) {
      final minutes = int.tryParse(chunks[0]) ?? 0;
      final seconds = int.tryParse(chunks[1]) ?? 0;
      return (minutes * 60) + seconds;
    }

    if (chunks.length == 3) {
      final hours = int.tryParse(chunks[0]) ?? 0;
      final minutes = int.tryParse(chunks[1]) ?? 0;
      final seconds = int.tryParse(chunks[2]) ?? 0;
      return (hours * 3600) + (minutes * 60) + seconds;
    }

    return int.tryParse(trimmed) ?? -1;
  }
}
