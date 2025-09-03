import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tripbook/models/location_group.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/screens/map_screen.dart';
import 'package:tripbook/services/firestore_service.dart';

class ManageLocationsScreen extends StatefulWidget {
  final String? initiallyExpandedLocationId;
  const ManageLocationsScreen({super.key, this.initiallyExpandedLocationId});

  @override
  State<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

enum SortBy { nameAsc, nameDesc, dateNewest, dateOldest }

class _ManageLocationsScreenState extends State<ManageLocationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  SortBy _currentSortBy = SortBy.dateNewest;
  GlobalKey? _scrollKey;

  void _sortLocations(List<TravelLocation> locations) {
    switch (_currentSortBy) {
      case SortBy.nameAsc:
        locations.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortBy.nameDesc:
        locations.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortBy.dateNewest:
        locations.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        break;
      case SortBy.dateOldest:
        locations.sort((a, b) =>
            (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
        break;
    }
  }

  void _scrollToSelected() {
    if (_scrollKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollKey?.currentContext != null) {
          Scrollable.ensureVisible(
            _scrollKey!.currentContext!,
            duration: const Duration(milliseconds: 600),
            alignment: 0.0, // Align to the top of the viewport
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konumları Yönet'),
        actions: [
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            onSelected: (SortBy result) {
              setState(() {
                _currentSortBy = result;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortBy>>[
              const PopupMenuItem<SortBy>(
                value: SortBy.nameAsc,
                child: Text('Ada Göre (A-Z)'),
              ),
              const PopupMenuItem<SortBy>(
                value: SortBy.nameDesc,
                child: Text('Ada Göre (Z-A)'),
              ),
              const PopupMenuItem<SortBy>(
                value: SortBy.dateNewest,
                child: Text('Tarihe Göre (Yeni)'),
              ),
              const PopupMenuItem<SortBy>(
                value: SortBy.dateOldest,
                child: Text('Tarihe Göre (Eski)'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<TravelLocation>>(
        stream: _firestoreService.getLocations(),
        builder: (context, locationSnapshot) {
          if (locationSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!locationSnapshot.hasData || locationSnapshot.data!.isEmpty) {
            return const Center(child: Text('Kaydedilmiş konum bulunamadı.'));
          }
          if (locationSnapshot.hasError) {
            return Center(
                child: Text('Bir hata oluştu: ${locationSnapshot.error}'));
          }

          final locations = locationSnapshot.data!;
          _sortLocations(locations);

          // Find the index of the item to scroll to
          final targetLocationIndex = widget.initiallyExpandedLocationId != null
              ? locations.indexWhere((loc) => loc.firestoreId == widget.initiallyExpandedLocationId)
              : -1;

          if (targetLocationIndex != -1) {
            _scrollKey = GlobalKey();
            _scrollToSelected();
          }

          return StreamBuilder<List<LocationGroup>>(
            stream: _firestoreService.getGroups(),
            builder: (context, groupSnapshot) {
              final groups = groupSnapshot.data ?? [];
              groups.sort((a, b) => a.name.compareTo(b.name));
              final groupMap = {for (var g in groups) g.firestoreId: g.name};

              return ListView.builder(
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final location = locations[index];
                  final bool isTarget = index == targetLocationIndex;

                  Widget listItem = LocationListItem(
                    key: ValueKey(location.firestoreId ?? location.hashCode),
                    location: location,
                    groupName: groupMap[location.groupId] ?? 'Yok',
                    allGroups: groups,
                    firestoreService: _firestoreService,
                    isInitiallyExpanded: isTarget,
                  );

                  if (isTarget) {
                    return Container(key: _scrollKey, child: listItem);
                  }
                  return listItem;
                },
              );
            },
          );
        },
      ),
    );
  }
}

class LocationListItem extends StatefulWidget {
  final TravelLocation location;
  final String groupName;
  final List<LocationGroup> allGroups;
  final FirestoreService firestoreService;
  final bool isInitiallyExpanded;

  const LocationListItem({
    super.key,
    required this.location,
    required this.groupName,
    required this.allGroups,
    required this.firestoreService,
    this.isInitiallyExpanded = false,
  });

  @override
  State<LocationListItem> createState() => _LocationListItemState();
}

class _LocationListItemState extends State<LocationListItem> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _needsController;
  late TextEditingController _durationController;
  String? _selectedGroupId;

  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location.name);
    _descriptionController = TextEditingController(text: widget.location.description);
    _notesController = TextEditingController(text: widget.location.notes);
    final needNames = widget.location.needsList?.map((need) => need['name'] as String).join(', ') ?? '';
    _needsController = TextEditingController(text: needNames);
    _durationController = TextEditingController(text: widget.location.estimatedDuration?.toString());
    _selectedGroupId = widget.location.groupId;
    _isExpanded = widget.isInitiallyExpanded;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _needsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (widget.location.firestoreId == null) return;

    final newNames = _needsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    final oldNeedsMap = {
      for (var need in (widget.location.needsList ?? []))
        if (need['name'] is String)
          (need['name'] as String): (need['checked'] as bool? ?? false)
    };

    final List<Map<String, dynamic>> needsList = [];
    for (var name in newNames) {
      needsList.add({
        'name': name,
        'checked': oldNeedsMap[name] ?? false,
      });
    }

    final updatedLocation = TravelLocation(
      firestoreId: widget.location.firestoreId,
      name: _nameController.text,
      geoName: widget.location.geoName,
      latitude: widget.location.latitude,
      longitude: widget.location.longitude,
      description: _descriptionController.text,
      groupId: _selectedGroupId,
      notes: _notesController.text,
      needsList: needsList,
      estimatedDuration: int.tryParse(_durationController.text),
      createdAt: widget.location.createdAt,
    );

    try {
      await widget.firestoreService
          .updateLocation(widget.location.firestoreId!, updatedLocation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Konum güncellendi!'),
              backgroundColor: Colors.green),
        );
        setState(() {
          _isExpanded = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ExpansionTile(
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        title: Text(
          widget.location.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: <TextSpan>[
              TextSpan(text: 'Grup: ${widget.groupName}\n'),
              TextSpan(text: widget.location.geoName),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _isExpanded
            ? null
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteLocation(context),
              ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(_nameController, 'Kullanıcı Adı'),
                const SizedBox(height: 16),
                _buildTextField(_descriptionController, 'Açıklama'),
                const SizedBox(height: 16),
                _buildTextField(_notesController, 'Özel Notlar'),
                const SizedBox(height: 16),
                _buildTextField(_needsController, 'İhtiyaçlar (virgülle ayırın)'),
                const SizedBox(height: 16),
                _buildTextField(_durationController, 'Tahmini Süre (dakika)', inputType: TextInputType.number),
                const SizedBox(height: 16),
                _buildGroupDropdown(),
                const SizedBox(height: 16),
                const Text('Google Haritalar Adı:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.location.geoName),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.map, color: Colors.blue),
                      tooltip: 'Haritada Göster',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapScreen(
                              initialLocation: widget.location,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.orange),
                      tooltip: 'Konum Bilgisini Kopyala',
                      onPressed: () {
                        final lat = widget.location.latitude;
                        final lon = widget.location.longitude;
                        Clipboard.setData(ClipboardData(text: '$lat,$lon'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Konum bilgileri kopyalandı!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.save, color: Colors.green),
                      tooltip: 'Değişiklikleri Kaydet',
                      onPressed: _saveChanges,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Konumu Sil',
                      onPressed: () => _deleteLocation(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: inputType,
    );
  }

  Widget _buildGroupDropdown() {
    final allGroupIds = widget.allGroups.map((g) => g.firestoreId).toSet();
    allGroupIds.add(null);

    final String? validSelectedGroupId = 
        allGroupIds.contains(_selectedGroupId) ? _selectedGroupId : null;

    return DropdownButtonFormField<String>(
      initialValue: validSelectedGroupId,
      decoration: const InputDecoration(
        labelText: 'Grup',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Yok'),
        ),
        ...widget.allGroups.map((group) {
          return DropdownMenuItem<String>(
            value: group.firestoreId,
            child: Text(group.name),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedGroupId = value;
        });
      },
    );
  }

  Future<void> _deleteLocation(BuildContext context) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konumu Sil'),
        content: Text(
            '${widget.location.name} konumunu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmDelete == true && widget.location.firestoreId != null) {
      await widget.firestoreService.deleteLocation(widget.location.firestoreId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konum silindi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}