
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/utils/marker_utils.dart' as marker_utils;

class HomeLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const HomeLocationPickerScreen({super.key, this.initialLocation});

  @override
  State<HomeLocationPickerScreen> createState() => _HomeLocationPickerScreenState();
}

class _HomeLocationPickerScreenState extends State<HomeLocationPickerScreen> {
  LatLng? _pickedLocation;
  Marker? _pickedLocationMarker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialLocation != null && _pickedLocation == null) {
      _pickedLocation = widget.initialLocation;
      _updateMarker(widget.initialLocation!, AppLocalizations.of(context)!.homeLocation);
    }
  }

  void _updateMarker(LatLng position, String markerTitle) async {
    // Make _updateMarker async because getHomeMarkerIcon is async
    final icon = await marker_utils.getHomeMarkerIcon();
    setState(() {
      _pickedLocation = position;
      _pickedLocationMarker = Marker(
        markerId: const MarkerId('pickedLocation'),
        position: position,
        icon: icon,
        infoWindow: InfoWindow(title: markerTitle),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectHomeLocation),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _pickedLocation == null
                ? null
                : () {
                    Navigator.of(context).pop(_pickedLocation);
                  },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.initialLocation ?? const LatLng(38.9637, 35.2433), // Turkey
          zoom: widget.initialLocation != null ? 15.0 : 5.0,
        ),
        onTap: (latLng) => _updateMarker(latLng, l10n.homeLocation),
        markers: _pickedLocationMarker != null ? {_pickedLocationMarker!} : {},
      ),
    );
  }
}
