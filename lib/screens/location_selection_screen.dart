import 'package:flutter/material.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/screens/map_screen.dart';

import 'package:tripbook/l10n/app_localizations.dart';

class LocationSelectionScreen extends StatefulWidget {
  final List<TravelLocation>? initialLocations;
  final TravelLocation? endLocation;

  const LocationSelectionScreen({
    super.key,
    this.initialLocations,
    this.endLocation,
  });

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  List<TravelLocation> _selectedLocations = [];
  TravelLocation? _currentEndLocation; // New state variable

  @override
  void initState() {
    super.initState();
    if (widget.initialLocations != null) {
      _selectedLocations = List.from(widget.initialLocations!);
    }
    if (widget.endLocation != null) {
      _selectedLocations.add(widget.endLocation!);
      _currentEndLocation = widget.endLocation; // Initialize new state variable
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sortAndEdit),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop(_selectedLocations);
            },
          ),
        ],
      ),
      body: ReorderableListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: <Widget>[
          for (int index = 0; index < _selectedLocations.length; index++)
            // Check if this is the end location
            if (_selectedLocations[index].firestoreId ==
                _currentEndLocation?.firestoreId)
              ListTile(
                // Regular ListTile for the non-reorderable end location
                key: Key(
                  _selectedLocations[index].firestoreId ?? index.toString(),
                ),
                title: Text(_selectedLocations[index].name),
                subtitle: Text(l10n.endLocationLabel),
                leading: const Icon(Icons.location_pin),
                trailing: TextButton(
                  child: Text(l10n.change),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapScreen(
                          isChangingEndPoint: true,
                          initialLocation: _selectedLocations[index],
                        ),
                      ),
                    ).then((newEndPoint) {
                      if (newEndPoint != null) {
                        setState(() {
                          final oldEndIndex = _selectedLocations.indexWhere(
                            (loc) =>
                                loc.firestoreId ==
                                _currentEndLocation?.firestoreId,
                          );
                          if (oldEndIndex != -1) {
                            _selectedLocations[oldEndIndex] = newEndPoint;
                            _currentEndLocation = newEndPoint;
                          }
                        });
                      }
                    });
                  },
                ),
              )
            else
              ListTile(
                // Reorderable ListTile for intermediate locations
                key: Key(
                  _selectedLocations[index].firestoreId ?? index.toString(),
                ),
                title: Text(_selectedLocations[index].name),
                leading: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _selectedLocations.removeAt(index);
                    });
                  },
                ),
              ),
        ],
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            // If the item being moved is the end location, do nothing.
            if (_selectedLocations[oldIndex].firestoreId ==
                _currentEndLocation?.firestoreId) {
              return;
            }

            if (newIndex == _selectedLocations.length) {
              newIndex--;
            }
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final TravelLocation item = _selectedLocations.removeAt(oldIndex);
            _selectedLocations.insert(newIndex, item);
          });
        },
      ),
    );
  }
}
