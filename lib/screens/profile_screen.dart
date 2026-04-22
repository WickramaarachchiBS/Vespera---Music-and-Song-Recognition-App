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
    final username = userProvider.username;
    String capitalizedUsername = username.isEmpty ? 'User' : username[0].toUpperCase() + username.substring(1);

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
            color: AppColors.textMuted)),
        actions: [
          TextButton.icon(
            onPressed: () => _showEditProfileDialog(userProvider),
            icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.textMuted),
            label: const Text('Edit', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
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
              _ProfileHeader(
                username: capitalizedUsername,
                email: userProvider.email,
                profilePictureUrl: userProvider.profilePicture,
              ),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'Listening Time'),
              const SizedBox(height: 10),
              _buildListeningAnalytics(),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Playlists'),
              const SizedBox(height: 10),
              _buildLibraryLink(),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to show custom notifications
  Widget _buildLibraryLink() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const CommonScreen(initialIndex: 2),
            ),
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
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to show edit profile dialog
  Future<void> _showEditProfileDialog(UserProvider userProvider) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to edit profile.')));
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
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textPrimary)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: photoController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Profile Photo URL',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textPrimary)),
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
                  onPressed:
                      isSaving
                          ? null
                          : () async {
                            final updatedName = nameController.text.trim();
                            final updatedPhoto = photoController.text.trim();

                            if (updatedName.isEmpty) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(const SnackBar(content: Text('Username cannot be empty.')));
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
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(const SnackBar(content: Text('Profile updated successfully.')));
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
                              setDialogState(() => isSaving = false);
                            }
                          },
                  child:
                      isSaving
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
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

  // Helper method to show listening analytics
  Widget _buildListeningAnalytics() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const _AnalyticsFallbackCard(message: 'Sign in to view listening analytics.');
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
          return const _AnalyticsFallbackCard(message: 'Could not load analytics right now.');
        }

        final docs = snapshot.data?.docs ?? const [];
        final analytics = _ListeningAnalytics.fromSessionDocs(docs);

        return Row(
          children: [
            Expanded(
              child: _AnalyticsCard(
                label: 'Daily',
                value: _formatDuration(analytics.daily),
                accentColor: AppColors.accentBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AnalyticsCard(
                label: 'Weekly',
                value: _formatDuration(analytics.weekly),
                accentColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AnalyticsCard(
                label: 'All-time',
                value: _formatDuration(analytics.allTime),
                accentColor: AppColors.success,
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final totalHours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (totalHours > 0) {
      return '${totalHours}h ${minutes}m';
    }

    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    }

    return '${duration.inSeconds}s';
  }
}

// Sub-widgets for ProfileScreen
class _ProfileHeader extends StatelessWidget {
  final String username;
  final String email;
  final String profilePictureUrl;

  const _ProfileHeader({required this.username, required this.email, required this.profilePictureUrl});

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
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primaryBlue,
            backgroundImage: hasNetworkImage ? NetworkImage(profilePictureUrl) : null,
            child:
                hasNetworkImage
                    ? null
                    : Text(
                      initials,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isEmpty ? 'No email found' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper classes for ProfileScreen
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.w700));
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
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
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

class _AnalyticsFallbackCard extends StatelessWidget {
  final String message;

  const _AnalyticsFallbackCard({required this.message});

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

class _ListeningAnalytics {
  final Duration daily;
  final Duration weekly;
  final Duration allTime;

  const _ListeningAnalytics({required this.daily, required this.weekly, required this.allTime});

  factory _ListeningAnalytics.fromSessionDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    final dailyThreshold = now.subtract(const Duration(days: 1));
    final weeklyThreshold = now.subtract(const Duration(days: 7));

    var dailySeconds = 0;
    var weeklySeconds = 0;
    var allTimeSeconds = 0;

    for (final doc in docs) {
      final data = doc.data();
      final sessionSeconds = _extractSessionSeconds(data);
      allTimeSeconds += sessionSeconds;

      final listenedAt = _extractSessionTime(data);
      if (listenedAt == null) {
        continue;
      }

      if (listenedAt.isAfter(weeklyThreshold)) {
        weeklySeconds += sessionSeconds;
      }

      if (listenedAt.isAfter(dailyThreshold)) {
        dailySeconds += sessionSeconds;
      }
    }

    return _ListeningAnalytics(
      daily: Duration(seconds: dailySeconds),
      weekly: Duration(seconds: weeklySeconds),
      allTime: Duration(seconds: allTimeSeconds),
    );
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
