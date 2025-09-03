import 'package:flutter/material.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/services/firestore_service.dart';

class LocationSelectionScreen extends StatefulWidget {
  final List<TravelLocation>? initialLocations;
  final TravelLocation? endLocation;

  const LocationSelectionScreen({super.key, this.initialLocations, this.endLocation});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<TravelLocation> _selectedLocations = [];
  // A screen can be in selection mode or reorder mode.
  // If initialLocations are provided, it starts in reorder mode.
  bool _isSelectionMode = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocations != null && widget.initialLocations!.isNotEmpty) {
      _selectedLocations = List.from(widget.initialLocations!);
      if (widget.endLocation != null) {
        _selectedLocations.add(widget.endLocation!);
      }
      _isSelectionMode = false;
    }
  }

  // The list of all available locations for the user to pick from.
  Widget _buildSelectionList(List<TravelLocation> allLocations) {
    return ListView.builder(
      itemCount: allLocations.length,
      itemBuilder: (context, index) {
        final location = allLocations[index];
        final isSelected = _selectedLocations.any((loc) => loc.firestoreId == location.firestoreId);
        return ListTile(
          tileColor: isSelected ? Colors.blue.withAlpha(25) : null,
          leading: Icon(
            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
            color: isSelected ? Colors.blue : null,
          ),
          title: Text(location.name),
          subtitle: Text(location.geoName, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedLocations.removeWhere((loc) => loc.firestoreId == location.firestoreId);
              } else {
                _selectedLocations.add(location);
              }
            });
          },
        );
      },
    );
  }

  // The list of selected locations, which can be reordered.
  Widget _buildReorderList() {
    return ReorderableListView.builder(
      header: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Konumları sürükleyerek rotanızı sıralayın.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
      ),
      itemCount: _selectedLocations.length,
      itemBuilder: (context, index) {
        final location = _selectedLocations[index];
        final bool isEndpoint = widget.endLocation != null && index == _selectedLocations.length - 1;

        return Card(
          key: ValueKey(location.firestoreId),
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: isEndpoint ? const Icon(Icons.flag) : const Icon(Icons.drag_handle),
            title: Text(location.name),
            subtitle: Text(location.geoName, maxLines: 1, overflow: TextOverflow.ellipsis),
            tileColor: isEndpoint ? Colors.grey[300] : null,
          ),
        );
      },
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (widget.endLocation != null && (oldIndex == _selectedLocations.length - 1 || newIndex == _selectedLocations.length)) {
            return;
          }
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final TravelLocation item = _selectedLocations.removeAt(oldIndex);
          _selectedLocations.insert(newIndex, item);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the title and actions based on the mode.
    final bool isReorderMode = !_isSelectionMode || (widget.initialLocations != null && widget.initialLocations!.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(isReorderMode ? 'Rotayı Sırala ve Onayla' : 'Konumları Seç'),
      ),
      body: isReorderMode
          ? _buildReorderList()
          : StreamBuilder<List<TravelLocation>>(
              stream: _firestoreService.getLocations(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return _buildSelectionList(snapshot.data!);
              },
            ),
      floatingActionButton: isReorderMode
          ? FloatingActionButton.extended(
              onPressed: () {
                if (_selectedLocations.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen en az 2 konum seçin.')),
                  );
                  return;
                }
                Navigator.of(context).pop(_selectedLocations);
              },
              label: const Text('Rotayı Onayla'),
              icon: const Icon(Icons.check),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                if (_selectedLocations.length >= 2) {
                  setState(() {
                    _isSelectionMode = false;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen en az 2 konum seçin.')),
                  );
                }
              },
              label: const Text('Sırala ve Onayla'),
              icon: const Icon(Icons.check),
            ),
    );
  }
}
