import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:tripbook/models/location_group.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/widgets/multi_group_selector.dart';

class LocationDetailScreen extends StatefulWidget {
  final TravelLocation location;

  const LocationDetailScreen({super.key, required this.location});

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final _needsController = TextEditingController();

  late String _notes;
  late int _estimatedDuration;
  late List<Map<String, dynamic>> _needsList;
  late List<String> _selectedGroupIds;
  List<LocationGroup> _allGroups = [];

  final List<Color> _groupColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _notes = widget.location.notes ?? '';
    _estimatedDuration = widget.location.estimatedDuration ?? 0;
    _needsList = List<Map<String, dynamic>>.from(
      widget.location.needsList ?? [],
    );
    _selectedGroupIds = List.from(widget.location.groupIds);
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final groups = await _firestoreService.getGroupsOnce();
    if (mounted) {
      setState(() {
        _allGroups = groups;
      });
    }
  }

  Future<LocationGroup?> _showAddNewGroupDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final groupNameController = TextEditingController();
    Color selectedColor = _groupColors.first;
    final formKey = GlobalKey<FormState>();

    return await showDialog<LocationGroup>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.newGroup),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: groupNameController,
                        decoration: InputDecoration(
                          labelText: l10n.groupName,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.locationNameEmptyError;
                          }
                          final invalidChars = RegExp(r'[<>]');
                          if (invalidChars.hasMatch(value)) {
                            return l10n.invalidGroupNameError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(l10n.selectGroupColor),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _groupColors.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == color
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newGroup = LocationGroup(
                        name: groupNameController.text.trim(),
                        // ignore: deprecated_member_use
                        color: selectedColor.value,
                        createdAt: DateTime.now(),
                        userId: FirebaseAuth.instance.currentUser!.uid,
                      );
                      final docRef = await _firestoreService.addGroup(newGroup);
                      final createdGroup = LocationGroup(
                        firestoreId: docRef.id,
                        name: newGroup.name,
                        color: newGroup.color,
                        createdAt: newGroup.createdAt,
                        userId: newGroup.userId,
                      );
                      Navigator.of(dialogContext).pop(createdGroup);
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _needsController.dispose();
    super.dispose();
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Handle user not logged in
        return;
      }

      final updatedLocation = TravelLocation(
        firestoreId: widget.location.firestoreId,
        name: widget
            .location
            .name, // Name and other core properties are not editable here
        geoName: widget.location.geoName, // Pass the geoName along
        description: widget.location.description,
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        groupIds: _selectedGroupIds,
        notes: _notes,
        estimatedDuration: _estimatedDuration,
        needsList: _needsList,
        userId: user.uid,
      );

      if (widget.location.firestoreId != null) {
        await _firestoreService.updateLocation(
          widget.location.firestoreId!,
          updatedLocation,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  void _addNeed() {
    if (_needsController.text.isNotEmpty) {
      setState(() {
        _needsList.add({'name': _needsController.text, 'checked': false});
        _needsController.clear();
      });
    }
  }

  void _removeNeed(int index) {
    setState(() {
      _needsList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.location.name),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveForm),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: _notes,
                decoration: InputDecoration(
                  labelText: l10n.privateNotesLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                onSaved: (value) {
                  _notes = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _estimatedDuration.toString(),
                decoration: InputDecoration(
                  labelText: l10n.estimatedStayTimeLabel,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (int.tryParse(value ?? '') == null) {
                    return l10n.enterValidNumberError;
                  }
                  return null;
                },
                onSaved: (value) {
                  _estimatedDuration = int.tryParse(value ?? '0') ?? 0;
                },
              ),
              const SizedBox(height: 16),
              MultiGroupSelector(
                selectedGroupIds: _selectedGroupIds,
                allGroups: _allGroups,
                onChanged: (ids) {
                  setState(() {
                    _selectedGroupIds = ids;
                  });
                },
                onAddNewGroup: () async {
                  final newGroup = await _showAddNewGroupDialog();
                  if (newGroup != null) {
                    setState(() {
                      _allGroups.add(newGroup);
                    });
                  }
                  return newGroup;
                },
              ),
              const SizedBox(height: 24),
              Text(
                l10n.needsListLabel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _needsList.length,
                itemBuilder: (context, index) {
                  final need = _needsList[index];
                  return Card(
                    child: ListTile(
                      title: Text(need['name'] as String? ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeNeed(index),
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _needsController,
                        decoration: InputDecoration(
                          labelText: l10n.addNewNeedHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.green),
                      onPressed: _addNeed,
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
}
