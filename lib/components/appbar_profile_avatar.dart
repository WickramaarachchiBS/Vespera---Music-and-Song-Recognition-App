import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/providers/user_provider.dart';
import 'package:vespera/screens/profile_screen.dart';

class AppBarProfileAvatar extends StatelessWidget {
  const AppBarProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final username = userProvider.username.trim();
        final profilePicture = userProvider.profilePicture.trim();
        final initials = username.isEmpty ? 'U' : username[0].toUpperCase();

        final uri = Uri.tryParse(profilePicture);
        final hasNetworkImage =
            uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(right: 6.0),
          child: IconButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: false).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            icon: CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.primaryBlue,
              backgroundImage: hasNetworkImage ? NetworkImage(profilePicture) : null,
              child: hasNetworkImage
                  ? null
                  : Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
