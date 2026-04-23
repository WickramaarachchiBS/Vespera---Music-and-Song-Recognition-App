import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/components/analytics_card.dart';
import 'package:vespera/components/dialogs/profile_edit_dialog.dart';
import 'package:vespera/components/profile_hero_header.dart';
import 'package:vespera/components/top_list_card.dart';
import 'package:vespera/elements/fallback_card.dart';
import 'package:vespera/elements/section_title.dart';
import 'package:vespera/helpers/duration_formatter.dart';
import 'package:vespera/helpers/profile_tags_helper.dart';
import 'package:vespera/models/listening_insights.dart';
import 'package:vespera/providers/user_provider.dart';
import 'package:vespera/screens/common_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule loading data after first frame to avoid issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
            onPressed: () => ProfileEditDialog.show(context, userProvider),
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
              ProfileHeroHeader(
                username: capitalizedUsername,
                email: userProvider.email,
                profilePictureUrl: userProvider.profilePicture,
                onEditPhotoTap: () => ProfileEditDialog.show(context, userProvider),
              ),
              const SizedBox(height: 20),
              const SectionTitle(title: 'Listening Insights'),
              const SizedBox(height: 10),
              _buildListeningInsights(),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Personalization'),
              const SizedBox(height: 10),
              _buildPersonalizationFromSearches(),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Playlists'),
              const SizedBox(height: 10),
              _buildLibraryLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListeningInsights() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const FallbackCard(message: 'Sign in to view listening insights.');
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
          return const FallbackCard(message: 'Could not load listening insights right now.');
        }

        final docs = snapshot.data?.docs ?? const [];
        final insights = ListeningInsights.fromSessionDocs(docs);

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AnalyticsCard(
                    label: 'Daily',
                    value: DurationFormatter.formatDuration(insights.daily),
                    accentColor: AppColors.accentBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnalyticsCard(
                    label: 'Weekly',
                    value: DurationFormatter.formatDuration(insights.weekly),
                    accentColor: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnalyticsCard(
                    label: 'All-time',
                    value: DurationFormatter.formatDuration(insights.allTime),
                    accentColor: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FallbackCard(
              message: insights.streakDays > 0
                  ? 'Listening streak: ${insights.streakDays} day${insights.streakDays == 1 ? '' : 's'}'
                  : 'No active streak yet. Listen daily to build one.',
            ),
            const SizedBox(height: 10),
            TopListCard(
              title: 'Top Artists',
              thisWeekItems: insights.topArtistsWeek,
              allTimeItems: insights.topArtistsAllTime,
            ),
            const SizedBox(height: 10),
            TopListCard(
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
      return const FallbackCard(message: 'Sign in to personalize your profile.');
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
          return const FallbackCard(message: 'Could not load personalization tags right now.');
        }

        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const FallbackCard(message: 'Search for songs to unlock your profile tags.');
        }

        final tags = ProfileTagsHelper.buildProfileTagsFromSearches(docs);
        if (tags.isEmpty) {
          return const FallbackCard(message: 'Not enough search data to build tags yet.');
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

  Widget _buildLibraryLink() {
    return Material(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blueGrey.withOpacity(0.1),
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
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.library_music_rounded, color: AppColors.textPrimary),
              SizedBox(width: 12),
              Text('Go to your library', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
              Spacer(),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }
}