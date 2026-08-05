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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          l10n.sortAndEdit,
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
      body: Column(
        children: [
          // Header info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.blue[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.reorder,
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
                        l10n.routeOrder,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      Text(
                        l10n.numLocationsDragToOrder(_selectedLocations.length),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.edit,
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
          
          // Locations list
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ReorderableListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: <Widget>[
                  for (int index = 0; index < _selectedLocations.length; index++)
                    // Check if this is the end location
                    if (_selectedLocations[index].firestoreId ==
                        _currentEndLocation?.firestoreId)
                      Container(
                        key: Key(
                          _selectedLocations[index].firestoreId ?? index.toString(),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
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
                          border: Border.all(color: Colors.purple[200]!, width: 2),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            _selectedLocations[index].name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple[200]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flag, color: Colors.purple[600], size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.endLocationLabel,
                                  style: TextStyle(
                                    color: Colors.purple[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.location_pin,
                              color: Colors.purple[600],
                              size: 24,
                            ),
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[600]!, Colors.blue[800]!],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextButton.icon(
                              icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                              label: Text(
                                l10n.change,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
                          ),
                        ),
                      ))
                    else
                      Container(
                        key: Key(
                          _selectedLocations[index].firestoreId ?? index.toString(),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
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
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            _selectedLocations[index].name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            _selectedLocations[index].geoName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                Icons.drag_handle,
                                color: Colors.blue[600],
                                size: 24,
                              ),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red[600],
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedLocations.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ),
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
            ),
          ),
          
          // Fixed bottom confirmation button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle, color: Colors.white, size: 24),
                  label: Text(
                    l10n.confirmRouteWithCount(_selectedLocations.length),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _selectedLocations.isNotEmpty
                      ? () {
                          Navigator.of(context).pop(_selectedLocations);
                        }
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
