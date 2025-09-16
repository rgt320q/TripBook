import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/travel_route.dart';
import 'package:tripbook/providers/community_routes_provider.dart';
import 'package:tripbook/screens/community_route_detail_screen.dart';
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
    final provider = context.watch<CommunityRoutesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.communityRoutes),
        actions: [
          IconButton(
            icon: Icon(
              _hideDownloaded ? Icons.visibility_off : Icons.visibility,
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
        ],
      ),
      body: Consumer<CommunityRoutesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.items.isEmpty) {
            return Center(child: Text(l10n.noSharedRoutes));
          }

          final allItems = provider.items;
          final filteredItems = _hideDownloaded
              ? allItems.where((item) => !item.isDownloaded).toList()
              : allItems;

          if (filteredItems.isEmpty) {
            return Center(child: Text(l10n.allRoutesDownloaded));
          }

          return RefreshIndicator(
            onRefresh: () async => provider.refreshRoutes(),
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final route = item.route;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  clipBehavior: Clip.antiAlias,
                  color: item.isDownloaded ? Colors.green[50] : null,
                  child: InkWell(
                    onTap: () => _handleRouteTap(route),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (route.locations != null &&
                            route.locations!.isNotEmpty)
                          RouteMiniMap(route: route),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      route.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ),
                                  if (item.isDownloaded)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.routeDistanceAndDuration(
                                  route.totalDistance,
                                  route.totalTravelTime,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.sharedBy(item.authorName),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 8),
                              Row(
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.comment_outlined,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.comments(route.commentCount),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
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
          );
        },
      ),
    );
  }
}
