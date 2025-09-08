import 'package:flutter/material.dart';
import 'package:tripbook/models/travel_location.dart';

class LocationSelectionScreen extends StatefulWidget {
  final List<TravelLocation>? initialLocations;
  final TravelLocation? endLocation;

  const LocationSelectionScreen({super.key, this.initialLocations, this.endLocation});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  List<TravelLocation> _selectedLocations = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocations != null) {
      _selectedLocations = List.from(widget.initialLocations!);
    }
    if (widget.endLocation != null) {
      _selectedLocations.add(widget.endLocation!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sırala ve Düzenle'),
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
            ListTile(
              key: Key('$index'),
              title: Text(_selectedLocations[index].name),
              subtitle: index == _selectedLocations.length - 1
                  ? const Text("Bitiş Konumu")
                  : null,
              leading: index == _selectedLocations.length - 1
                  ? const Icon(Icons.location_pin)
                  : ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
              trailing: index == _selectedLocations.length - 1
                  ? TextButton(
                      child: const Text("Değiştir"),
                      onPressed: () {
                        Navigator.of(context).pop('change_end_location');
                      },
                    )
                  : null,
            ),
        ],
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
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
