import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/user_profile.dart';
import 'package:tripbook/utils/avatar_utils.dart';
import 'package:tripbook/utils/brand_colors.dart';

class UserProfileCard extends StatelessWidget {
  final UserProfile userProfile;
  final bool showFullProfile;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final bool isCurrentUser;

  const UserProfileCard({
    super.key,
    required this.userProfile,
    this.showFullProfile = false,
    this.onTap,
    this.margin,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    // Herkese açık profil bilgilerini al
    final publicProfile = isCurrentUser ? userProfile : userProfile.getPublicProfile();
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Profil resmi
                _buildProfileAvatar(publicProfile),
                const SizedBox(width: 12),
                
                // Kullanıcı bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İsim - Yeni displayNameInPublic mantığıyla
                      Text(
                        isCurrentUser ? userProfile.getDisplayName() : userProfile.getPublicDisplayName(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Bio (sadece full profile'da ve izin verilmişse)
                      if (showFullProfile && publicProfile.bio != null && publicProfile.bio!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          publicProfile.bio!,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                          maxLines: showFullProfile ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      // Kullanıcı durumu göstergesi
                      if (isCurrentUser) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'You', // Simplified as it's a minor tag
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Sağ taraf ok ikonu (tıklanabilirse)
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(UserProfile profile) {
    final avatarPath = AvatarUtils.validateAvatarPath(profile.selectedAvatarPath);
    
    return Container(
      width: showFullProfile ? 60 : 50,
      height: showFullProfile ? 60 : 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.blue[300]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: SvgPicture.asset(
          avatarPath,
          fit: BoxFit.cover,
          placeholderBuilder: (context) => _buildDefaultAvatar(),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.blue[300]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: showFullProfile ? 30 : 25,
      ),
    );
  }
}

/// Kullanıcı detaylarını gösteren modal bottom sheet
class UserDetailSheet {
  static void show(BuildContext context, UserProfile userProfile, {bool isCurrentUser = false}) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    brandButtonBlue(Theme.of(context).brightness),
                    brandGradientEndBlue(Theme.of(context).brightness),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  UserProfileCard(
                    userProfile: userProfile,
                    showFullProfile: true,
                    isCurrentUser: isCurrentUser,
                    margin: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCurrentUser) ...[
                      Text(
                        l10n.thisIsYourProfile,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.privacyNotice,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ] else ...[
                      Text(
                        l10n.profileScreenTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.publicProfileInfo,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Gizlilik bilgileri
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.privacyPreferencesNotice,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[800],
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
],
      ),
      );
    },
    );
  }
}
