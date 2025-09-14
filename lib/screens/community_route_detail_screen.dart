import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/models/travel_route.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:tripbook/models/route_comment.dart';
import 'package:tripbook/models/user_profile.dart';
import 'package:tripbook/widgets/route_mini_map.dart';

import 'package:tripbook/l10n/app_localizations.dart';

class CommunityRouteDetailScreen extends StatefulWidget {
  final TravelRoute route;

  const CommunityRouteDetailScreen({super.key, required this.route});

  @override
  State<CommunityRouteDetailScreen> createState() =>
      _CommunityRouteDetailScreenState();
}

class _CommunityRouteDetailScreenState
    extends State<CommunityRouteDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _commentController = TextEditingController();

  // User and Rating State
  double? _userRating;
  UserProfile? _sharedByUserProfile;

  bool _isSaved = false;
  bool _madeChanges = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _loadInitialData();
  }

  Future<void> _checkIfSaved() async {
    if (widget.route.firestoreId == null) return;
    final existingRoute = await _firestoreService.getDownloadedCommunityRoute(
      widget.route.firestoreId!,
    );
    if (mounted) {
      setState(() {
        _isSaved = existingRoute != null;
      });
    }
  }

  Future<void> _loadInitialData() async {
    _loadSharedByUserProfile();
    _fetchUserRating();
  }

  Future<void> _loadSharedByUserProfile() async {
    if (widget.route.sharedBy != null) {
      final profile = await _firestoreService.getUserProfileById(
        widget.route.sharedBy!,
      );
      if (mounted) {
        setState(() {
          _sharedByUserProfile = profile;
        });
      }
    }
  }

  Future<void> _fetchUserRating() async {
    if (widget.route.firestoreId == null) return;
    final rating = await _firestoreService.getUserRating(
      widget.route.firestoreId!,
    );
    if (mounted && rating != null) {
      setState(() {
        _userRating = rating;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty ||
        widget.route.firestoreId == null) {
      return;
    }
    _firestoreService.addComment(
      widget.route.firestoreId!,
      _commentController.text.trim(),
    );
    _commentController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _madeChanges = true;
    });
  }

  void _submitRating(double rating) {
    if (widget.route.firestoreId == null) return;
    // Optimistically update the UI
    setState(() {
      _userRating = rating;
      _madeChanges = true;
    });
    _firestoreService.addOrUpdateRating(widget.route.firestoreId!, rating);
  }

  Future<void> _saveRoute() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.routeAlreadySaved),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saveRoute),
        content: Text(l10n.saveRouteConfirmation(widget.route.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (confirm == true) {
      List<String> newLocationIds = [];
      if (widget.route.locations != null &&
          widget.route.locations!.isNotEmpty) {
        final locationsToImport = widget.route.locations!
            .map(
              (locMap) => TravelLocation.fromFirestore(
                locMap['firestoreId'] ?? '',
                locMap,
              ),
            )
            .map(
              (loc) => TravelLocation(
                name: loc.name,
                geoName: loc.geoName,
                description: loc.description,
                latitude: loc.latitude,
                longitude: loc.longitude,
                notes: loc.notes,
                needsList: loc.needsList,
                estimatedDuration: loc.estimatedDuration,
                isImported: true, // Mark as imported
              ),
            )
            .toList();

        newLocationIds = await _firestoreService.addLocations(
          locationsToImport,
        );
      }

      final newRoute = widget.route.copyWith(
        locationIds: newLocationIds.isNotEmpty
            ? newLocationIds
            : widget.route.locationIds,
        isShared: false,
        sharedBy: null,
        averageRating: 0.0,
        ratingCount: 0,
        commentCount: 0,
        locations: [], // Clear locations when saving to user's own routes
        communityRouteId: widget.route.firestoreId,
      );

      await _firestoreService.addRoute(newRoute);

      if (mounted) {
        setState(() {
          _isSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.routeSavedSuccessfully(widget.route.name)),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // TODO: WillPopScope is deprecated, but PopScope is not yet flexible enough to handle this case.
    // This should be migrated to PopScope when possible.
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _madeChanges);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.route.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.save_alt),
              tooltip: l10n.saveRoute,
              onPressed: _saveRoute,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.route.locations != null &&
                  widget.route.locations!.isNotEmpty)
                RouteMiniMap(route: widget.route),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Route Info
                    Text(
                      l10n.sharedBy(
                        _sharedByUserProfile?.name ?? l10n.unknownUser,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.distance}: ${widget.route.totalDistance} | ${l10n.duration}: ${widget.route.totalTravelTime}',
                    ),
                    if (widget.route.totalStopDuration != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${l10n.totalBreakTime}: ${widget.route.totalStopDuration}',
                        ),
                      ),
                    if (widget.route.totalTripDuration != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${l10n.totalTripTime}: ${widget.route.totalTripDuration}',
                        ),
                      ),
                    const Divider(height: 30),

                    // Needs Section
                    if (widget.route.needs != null &&
                        widget.route.needs!.isNotEmpty)
                      _buildNeedsSection(),

                    // Notes Section
                    if (widget.route.notes != null &&
                        widget.route.notes!.isNotEmpty)
                      _buildNotesSection(),

                    // Rating Section
                    Text(
                      l10n.rate,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            (_userRating ?? 0) >= index + 1
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () => _submitRating(index + 1.0),
                        );
                      }),
                    ),
                    const Divider(height: 30),

                    // Comments Section
                    Text(
                      l10n.commentsTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildCommentInput(),
                    const SizedBox(height: 16),
                    _buildCommentsList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeedsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.routeNeeds, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: widget.route.needs!
              .map((need) => Chip(label: Text(need)))
              .toList(),
        ),
        const Divider(height: 30),
      ],
    );
  }

  Widget _buildNotesSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.routeNotes, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...widget.route.notes!.map((note) {
          final title = note['title'];
          final content = note['content'];
          if (title == null || content == null) {
            return const SizedBox.shrink(); // Or some other placeholder
          }
          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: ListTile(title: Text(title), subtitle: Text(content)),
          );
        }),
        const Divider(height: 30),
      ],
    );
  }

  Widget _buildCommentInput() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: l10n.addCommentHint,
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submitComment(),
          ),
        ),
        IconButton(icon: const Icon(Icons.send), onPressed: _submitComment),
      ],
    );
  }

  Widget _buildCommentsList() {
    final l10n = AppLocalizations.of(context)!;
    if (widget.route.firestoreId == null) {
      return Center(child: Text(l10n.commentsLoadingError));
    }
    return StreamBuilder<List<RouteComment>>(
      stream: _firestoreService.getComments(widget.route.firestoreId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              l10n.commentsLoadingErrorDescription(snapshot.error.toString()),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(l10n.noCommentsYet));
        }
        final comments = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: Text(
                  comment.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(comment.comment),
                trailing: Text(
                  '${comment.timestamp.toDate().day}/${comment.timestamp.toDate().month}/${comment.timestamp.toDate().year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
