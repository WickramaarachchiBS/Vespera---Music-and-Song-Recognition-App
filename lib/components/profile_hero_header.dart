import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/components/stat_pill.dart';

class ProfileHeroHeader extends StatelessWidget {
  final String username;
  final String email;
  final String profilePictureUrl;
  final VoidCallback onEditPhotoTap;

  const ProfileHeroHeader({
    required this.username,
    required this.email,
    required this.profilePictureUrl,
    required this.onEditPhotoTap,
    super.key,
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
              Expanded(child: StatPill(label: 'Followers', value: '5')),
              SizedBox(width: 10),
              Expanded(child: StatPill(label: 'Following', value: '26')),
            ],
          ),
        ],
      ),
    );
  }
}
