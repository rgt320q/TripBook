import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/models/travel_route.dart';
import 'package:tripbook/services/directions_service.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:tripbook/models/route_comment.dart';
import 'package:tripbook/models/user_profile.dart';
import 'package:tripbook/utils/marker_utils.dart' as marker_utils;

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
  final DirectionsService _directionsService = DirectionsService();
  final TextEditingController _commentController = TextEditingController();

  // User and Rating State
  double? _userRating;
  UserProfile? _sharedByUserProfile;

  // Map State
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isMapLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _loadSharedByUserProfile();
    _fetchUserRating();
    _loadRouteData();
  }

  Future<void> _loadSharedByUserProfile() async {
    if (widget.route.sharedBy != null) {
      final profile =
          await _firestoreService.getUserProfileById(widget.route.sharedBy!);
      if (mounted) {
        setState(() {
          _sharedByUserProfile = profile;
        });
      }
    }
  }

  Future<void> _fetchUserRating() async {
    if (widget.route.firestoreId == null) return;
    final rating =
        await _firestoreService.getUserRating(widget.route.firestoreId!);
    if (mounted && rating != null) {
      setState(() {
        _userRating = rating;
      });
    }
  }

  Future<void> _loadRouteData() async {
    if (widget.route.locationIds.isEmpty) {
      if (mounted) setState(() => _isMapLoading = false);
      return;
    }

    final locations =
        await _firestoreService.getLocationsByIds(widget.route.locationIds);
    if (locations.length < 2) {
      if (mounted) setState(() => _isMapLoading = false);
      return;
    }

    final directionsInfo = await _directionsService.getDirections(locations);
    await _updateMapElements(locations, directionsInfo);

    if (mounted) {
      setState(() {
        _isMapLoading = false;
      });
      if (directionsInfo != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(directionsInfo.bounds, 50),
        );
      }
    }
  }

  Future<void> _updateMapElements(
      List<TravelLocation> locations, DirectionsInfo? info) async {
    final Set<Marker> newMarkers = {};
    for (final loc in locations) {
      final icon = await marker_utils.getCustomMarkerIcon(Colors.blue);
      newMarkers.add(
        Marker(
          markerId: MarkerId(loc.firestoreId!),
          position: LatLng(loc.latitude, loc.longitude),
          infoWindow: InfoWindow(title: loc.name),
          icon: icon,
        ),
      );
    }

    final Set<Polyline> newPolylines = {};
    if (info != null) {
      for (int i = 0; i < info.legsPoints.length; i++) {
        newPolylines.add(Polyline(
          polylineId: PolylineId('route_leg_$i'),
          color: Colors.blue.withOpacity(0.8),
          width: 5,
          points:
              info.legsPoints[i].map((p) => LatLng(p.latitude, p.longitude)).toList(),
        ));
      }
    }

    if (mounted) {
      setState(() {
        _markers.addAll(newMarkers);
        _polylines.addAll(newPolylines);
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty ||
        widget.route.firestoreId == null) return;
    _firestoreService.addComment(
        widget.route.firestoreId!, _commentController.text.trim());
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  void _submitRating(double rating) {
    if (widget.route.firestoreId == null) return;
    // Optimistically update the UI
    setState(() {
      _userRating = rating;
    });
    _firestoreService.addOrUpdateRating(widget.route.firestoreId!, rating);
  }

  Future<void> _saveRoute() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rotayı Kaydet'),
        content: Text(
            "'${widget.route.name}' rotasını kendi kayıtlı rotalarınıza eklemek istediğinizden emin misiniz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Kaydet')),
        ],
      ),
    );

    if (confirm == true) {
      final newRoute = widget.route.copyWith(
        isShared: false,
        sharedBy: null,
        averageRating: 0.0,
        ratingCount: 0,
        commentCount: 0,
      );

      await _firestoreService.addRoute(newRoute);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("'${widget.route.name}' rotası başarıyla kaydedildi!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Rotayı Kaydet',
            onPressed: _saveRoute,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMapSection(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Route Info
                  Text(
                    'Paylaşan: ${_sharedByUserProfile?.name ?? 'Bilinmiyor'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Mesafe: ${widget.route.totalDistance} | Süre: ${widget.route.totalTravelTime}'),
                  const Divider(height: 30),

                  // Rating Section
                  Text('Puanla', style: Theme.of(context).textTheme.titleLarge),
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
                  Text('Yorumlar',
                      style: Theme.of(context).textTheme.titleLarge),
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
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 300,
      color: Colors.grey[300],
      child: _isMapLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: const CameraPosition(
                target: LatLng(39.9334, 32.8597), // Default to Ankara
                zoom: 5,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
    );
  }

  Widget _buildCommentInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'Yorum ekle...',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submitComment(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: _submitComment,
        ),
      ],
    );
  }

  Widget _buildCommentsList() {
    if (widget.route.firestoreId == null) {
      return const Center(child: Text('Yorumlar yüklenemiyor.'));
    }
    return StreamBuilder<List<RouteComment>>(
      stream: _firestoreService.getComments(widget.route.firestoreId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Yorumlar yüklenirken bir hata oluştu: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Henüz yorum yapılmamış.'));
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
                title: Text(comment.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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