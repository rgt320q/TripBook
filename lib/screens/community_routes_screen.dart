import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/travel_route.dart';
import 'package:tripbook/models/user_profile.dart';
import 'package:tripbook/providers/community_routes_provider.dart';
import 'package:tripbook/screens/community_route_detail_screen.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:tripbook/utils/brand_colors.dart';
import 'package:tripbook/widgets/route_mini_map.dart';

class CommunityRoutesScreen extends StatefulWidget {
  const CommunityRoutesScreen({super.key});

  @override
  State<CommunityRoutesScreen> createState() => _CommunityRoutesScreenState();
}

class _CommunityRoutesScreenState extends State<CommunityRoutesScreen> {
  bool _hideDownloaded = false;

  // No longer need initState to fetch data, provider handles it.

  Future<void> _handleRouteTap(
    TravelRoute route,
  ) async {
    // The provider will update automatically, so we don't need to pass it
    // or call fetchRoutes anymore.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommunityRouteDetailScreen(route: route),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.communityRoutes,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  _hideDownloaded ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                tooltip: _hideDownloaded
                    ? l10n.showDownloaded
                    : l10n.hideDownloaded,
                onPressed: () {
                  setState(() {
                    _hideDownloaded = !_hideDownloaded;
                  });
                },
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                brandAppBarBlue(Theme.of(context).brightness),
                brandAppBarBlue(Theme.of(context).brightness).withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<CommunityRoutesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (provider.items.isEmpty) {
            return Container(
              margin: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.public_off,
                        size: 64,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.noSharedRoutes,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Henüz paylaşılmış bir rota bulunmuyor',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final allItems = provider.items;
          final filteredItems = _hideDownloaded
              ? allItems.where((item) => !item.isDownloaded).toList()
              : allItems;

          if (filteredItems.isEmpty) {
            return Container(
              margin: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.download_done,
                        size: 64,
                        color: Colors.green[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.allRoutesDownloaded,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.allRoutesDownloaded,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Stats header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[50]!, Colors.purple[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.public,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.communityRoutes,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[800],
                            ),
                          ),
                          Text(
                            '${filteredItems.length} ${filteredItems.length == 1 ? "route" : "routes"} • ${_hideDownloaded ? l10n.newRoutes : l10n.allRoutes}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.purple[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _hideDownloaded ? Colors.orange[600] : Colors.purple[600],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _hideDownloaded ? l10n.filtered : l10n.all,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Routes list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => provider.refreshRoutes(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final route = item.route;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: item.isDownloaded
                                ? Colors.green[200]!
                                : colorScheme.outlineVariant,
                            width: item.isDownloaded ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _handleRouteTap(route),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Route map with overlay
                              if (route.locations != null && route.locations!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: Stack(
                                    children: [
                                      RouteMiniMap(
                                        route: route,
                                        onTap: () => _handleRouteTap(route),
                                      ),
                                      if (item.isDownloaded)
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green[600],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.download_done,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  l10n.downloaded,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              
                              // Route info
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title and distance
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                route.name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.route,
                                                    size: 16,
                                                    color: colorScheme.onSurfaceVariant,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    l10n.routeDistanceAndDuration(
                                                      route.totalDistance,
                                                      route.totalTravelTime,
                                                    ),
                                                    style: TextStyle(
                                                      color: colorScheme.onSurfaceVariant,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Author info
                                    if (item.route.sharedBy != null)
                                      FutureBuilder<UserProfile?>(
                                        future: FirestoreService().getUserProfileById(item.route.sharedBy!),
                                        builder: (context, snapshot) {
                                          final authorName = snapshot.hasData && snapshot.data != null
                                              ? snapshot.data!.getPublicDisplayName()
                                              : item.authorName;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primaryContainer,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.blue[200]!),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: 16,
                                                  color: Colors.blue[600],
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  l10n.sharedBy(authorName),
                                                  style: TextStyle(
                                                    color: Colors.blue[600],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.blue[200]!),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.person,
                                              size: 16,
                                              color: Colors.blue[600],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              l10n.sharedBy(item.authorName),
                                              style: TextStyle(
                                                color: Colors.blue[600],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Rating and comments
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                l10n.rating(
                                                  route.averageRating.toStringAsFixed(1),
                                                  route.ratingCount,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.amber[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.comment_outlined,
                                                color: colorScheme.onSurfaceVariant,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                l10n.comments(route.commentCount),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
