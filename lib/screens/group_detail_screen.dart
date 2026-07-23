import 'package:flutter/material.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<TravelLocation> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final fetched = await _firestoreService.getLocationsForGroup(widget.groupId);
      if (mounted) {
        setState(() {
          _locations = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _locations.removeAt(oldIndex);
      _locations.insert(newIndex, item);
    });

    final ids = _locations.map((l) => l.firestoreId!).toList();
    try {
      await _firestoreService.updateGroupLocationOrder(widget.groupId, ids);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sıralama güncellenemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locations.isEmpty
              ? Center(child: Text(l10n.noLocationsInGroup))
              : ReorderableListView.builder(
                  itemCount: _locations.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final location = _locations[index];
                    return ListTile(
                      key: ValueKey(location.firestoreId),
                      leading: const Icon(Icons.location_on),
                      title: Text(location.name),
                      subtitle: Text(location.description ?? ''),
                      trailing: const Icon(Icons.drag_handle),
                    );
                  },
                ),
    );
  }
}
