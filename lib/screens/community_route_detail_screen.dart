import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/models/travel_route.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:tripbook/models/route_comment.dart';
import 'package:tripbook/models/user_profile.dart';
import 'package:tripbook/widgets/route_mini_map.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  void _showUserProfileInfo() {
    if (_sharedByUserProfile == null) return;
    
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text('${l10n.sharedBy("")} ${_sharedByUserProfile!.getPublicDisplayName()}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_sharedByUserProfile!.showBioInPublic && 
                  _sharedByUserProfile!.bio?.isNotEmpty == true) ...[
                Text(
                  l10n.aboutLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(_sharedByUserProfile!.bio!),
                const SizedBox(height: 12),
              ],
              if (_sharedByUserProfile!.showPhoneInPublic && 
                  _sharedByUserProfile!.phone?.isNotEmpty == true) ...[
                Text(
                  l10n.profileEmailLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(_sharedByUserProfile!.phone!),
                const SizedBox(height: 12),
              ],
              if (_sharedByUserProfile!.showGenderInPublic && 
                  _sharedByUserProfile!.gender?.isNotEmpty == true) ...[
                Text(
                  l10n.genderLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(_sharedByUserProfile!.gender!),
                const SizedBox(height: 12),
              ],
              if (_sharedByUserProfile!.showBirthDateInPublic && 
                  _sharedByUserProfile!.birthDate != null) ...[
                Text(
                  l10n.birthDateLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_sharedByUserProfile!.birthDate!.toDate().day}/'
                  '${_sharedByUserProfile!.birthDate!.toDate().month}/'
                  '${_sharedByUserProfile!.birthDate!.toDate().year}',
                ),
                const SizedBox(height: 12),
              ],
              if (!_sharedByUserProfile!.showBioInPublic && 
                  !_sharedByUserProfile!.showPhoneInPublic &&
                  !_sharedByUserProfile!.showGenderInPublic &&
                  !_sharedByUserProfile!.showBirthDateInPublic)
                Text(
                  l10n.privacyNotShared,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  void _submitComment() {
    final l10n = AppLocalizations.of(context)!;
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty || widget.route.firestoreId == null) {
      return;
    }

    // Basic validation for potentially harmful characters
    final invalidChars = RegExp(r'[<>]');
    if (invalidChars.hasMatch(commentText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invalidCommentError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    _firestoreService.addComment(
      widget.route.firestoreId!,
      commentText, // Already trimmed
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
                isImported: true, userId: '', // Mark as imported
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.of(context).pop(_madeChanges);
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            widget.route.name,
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
            onPressed: () => Navigator.of(context).pop(_madeChanges),
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
                    _isSaved ? Icons.download_done : Icons.save_alt,
                    color: Colors.white,
                  ),
                  tooltip: l10n.saveRoute,
                  onPressed: _saveRoute,
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
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route Map
              if (widget.route.locations != null && widget.route.locations!.isNotEmpty)
                Stack(
                  children: [
                    RouteMiniMap(route: widget.route),
                    if (_isSaved)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                                l10n.saved,
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
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route info header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Author info
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.blue[600],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.sharedBy(
                                    _sharedByUserProfile?.getPublicDisplayName() ?? l10n.unknownUser,
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ),
                              if (_sharedByUserProfile != null)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: Colors.blue[600],
                                    ),
                                    onPressed: () => _showUserProfileInfo(),
                                    tooltip: l10n.authorProfileTooltip,
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          // Route stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.route,
                                  label: l10n.distance,
                                  value: widget.route.totalDistance,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.access_time,
                                  label: l10n.duration,
                                  value: widget.route.totalTravelTime,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          
                          if (widget.route.totalStopDuration != null || widget.route.totalTripDuration != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (widget.route.totalStopDuration != null)
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: Icons.pause_circle,
                                      label: l10n.totalBreakTime,
                                      value: widget.route.totalStopDuration!,
                                      color: Colors.orange,
                                    ),
                                  ),
                                if (widget.route.totalStopDuration != null && widget.route.totalTripDuration != null)
                                  const SizedBox(width: 12),
                                if (widget.route.totalTripDuration != null)
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: Icons.schedule,
                                      label: l10n.totalTripTime,
                                      value: widget.route.totalTripDuration!,
                                      color: Colors.purple,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    // Needs Section
                    if (widget.route.needs != null && widget.route.needs!.isNotEmpty)
                      _buildNeedsSection(),

                    // Notes Section
                    if (widget.route.notes != null && widget.route.notes!.isNotEmpty)
                      _buildNotesSection(),

                    // Rating Section
                    _buildRatingSection(),

                    const SizedBox(height: 20),

                    // Comments Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.comment,
                                  color: Colors.purple[600],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.commentsTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCommentInput(),
                          const SizedBox(height: 16),
                          _buildCommentsList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyRoute = currentUser != null && currentUser.uid == widget.route.sharedBy;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.amber[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.rate,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isMyRoute)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.mySharedRoute,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[25],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber[100]!,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => _submitRating(index + 1.0),
                      child: Icon(
                        (_userRating ?? 0) >= index + 1
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber[600],
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color[600],
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color[700],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNeedsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.shopping_bag,
                  color: Colors.orange[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.routeNeeds,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: widget.route.needs!
                .map((need) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orange[200]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        need,
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.note,
                  color: Colors.blue[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.routeNotes,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.route.notes!.map((note) {
            final title = note['title'];
            final content = note['content'];
            if (title == null || content == null) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[25],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue[100]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[25],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple[100]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: l10n.addCommentHint,
                hintStyle: TextStyle(
                  color: Colors.purple[400],
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.purple[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _submitComment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    final l10n = AppLocalizations.of(context)!;
    if (widget.route.firestoreId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red[200]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.commentsLoadingError,
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return StreamBuilder<List<RouteComment>>(
      stream: _firestoreService.getComments(widget.route.firestoreId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Colors.purple[600],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.commentsLoadingErrorDescription(snapshot.error.toString()),
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.noCommentsYet,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final comments = snapshot.data!;
        return Column(
          children: comments.map((comment) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[25],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple[100]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.purple[600],
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          comment.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.purple[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${comment.timestamp.toDate().day}/${comment.timestamp.toDate().month}/${comment.timestamp.toDate().year}',
                        style: TextStyle(
                          color: Colors.purple[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment.comment,
                    style: TextStyle(
                      color: Colors.purple[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}