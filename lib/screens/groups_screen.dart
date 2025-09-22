import 'package:tripbook/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:tripbook/models/location_group.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:tripbook/screens/group_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum GroupSortBy { nameAsc, nameDesc, dateNewest, dateOldest }

class GroupsScreen extends StatefulWidget {
  final bool isForSelection;

  const GroupsScreen({super.key, this.isForSelection = false});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _groupNameController = TextEditingController();
  Color? _selectedColor;
  GroupSortBy _currentSortBy = GroupSortBy.nameAsc;

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
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _sortGroups(List<LocationGroup> groups) {
    switch (_currentSortBy) {
      case GroupSortBy.nameAsc:
        groups.sort((a, b) => a.name.compareTo(b.name));
        break;
      case GroupSortBy.nameDesc:
        groups.sort((a, b) => b.name.compareTo(a.name));
        break;
      case GroupSortBy.dateNewest:
        groups.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
        break;
      case GroupSortBy.dateOldest:
        groups.sort(
          (a, b) => (a.createdAt ?? DateTime(0)).compareTo(
            b.createdAt ?? DateTime(0),
          ),
        );
        break;
    }
  }

  void _showGroupDialog({LocationGroup? groupToEdit}) {
    _groupNameController.text = groupToEdit?.name ?? '';
    _selectedColor = groupToEdit != null
        ? Color(groupToEdit.color ?? Colors.blue.value)
        : Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                groupToEdit == null
                    ? AppLocalizations.of(context)!.newGroup
                    : AppLocalizations.of(context)!.editGroup,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _groupNameController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.groupName,
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    Text(AppLocalizations.of(context)!.selectGroupColor),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _groupColors.map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColor == color
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
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _groupNameController.clear();
                    _selectedColor = null;
                  },
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final l10n = AppLocalizations.of(context)!;
                    final groupName = _groupNameController.text.trim();

                    if (groupName.isEmpty) {
                      // Optionally show a snackbar for empty name
                      return;
                    }

                    final invalidChars = RegExp(r'[<>]');
                    if (invalidChars.hasMatch(groupName)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.invalidGroupNameError),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                      return;
                    }

                    final group = LocationGroup(
                      firestoreId: groupToEdit?.firestoreId,
                      name: groupName,
                      color: _selectedColor?.value,
                      createdAt: groupToEdit
                          ?.createdAt, userId: '', // Preserve original creation date
                    );

                    if (groupToEdit == null) {
                      await _firestoreService.addGroup(group);
                    } else {
                      await _firestoreService.updateGroup(
                        group.firestoreId!,
                        group,
                      );
                    }

                    _groupNameController.clear();
                    _selectedColor = null;
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isForSelection
              ? AppLocalizations.of(context)!.selectGroup
              : AppLocalizations.of(context)!.travelGroups,
        ),
        actions: [
          if (!widget.isForSelection)
            PopupMenuButton<GroupSortBy>(
              icon: const Icon(Icons.sort),
              onSelected: (GroupSortBy result) {
                setState(() {
                  _currentSortBy = result;
                });
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<GroupSortBy>>[
                    PopupMenuItem<GroupSortBy>(
                      value: GroupSortBy.nameAsc,
                      child: Text(AppLocalizations.of(context)!.sortByNameAsc),
                    ),
                    PopupMenuItem<GroupSortBy>(
                      value: GroupSortBy.nameDesc,
                      child: Text(AppLocalizations.of(context)!.sortByNameDesc),
                    ),
                    PopupMenuItem<GroupSortBy>(
                      value: GroupSortBy.dateNewest,
                      child: Text(
                        AppLocalizations.of(context)!.sortByDateNewest,
                      ),
                    ),
                    PopupMenuItem<GroupSortBy>(
                      value: GroupSortBy.dateOldest,
                      child: Text(
                        AppLocalizations.of(context)!.sortByDateOldest,
                      ),
                    ),
                  ],
            ),
        ],
      ),
      body: StreamBuilder<List<LocationGroup>>(
        stream: _firestoreService.getGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noGroupsYet),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.error(snapshot.error.toString()),
              ),
            );
          }

          final groups = snapshot.data!;
          _sortGroups(groups);

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(group.color ?? Colors.blue.value),
                            radius: 15,
                          ),
                          title: Text(group.name, style: Theme.of(context).textTheme.titleMedium),
                          trailing: widget.isForSelection
                              ? const Icon(Icons.arrow_forward_ios)
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        _showGroupDialog(groupToEdit: group);
                                      },
                                      tooltip: AppLocalizations.of(context)!.editGroup,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                                      onPressed: () async {
                                        final bool? confirmDelete =
                                            await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.deleteGroup,
                                                ),
                                                content: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.deleteGroupConfirmation(
                                                    group.name,
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(
                                                      context,
                                                    ).pop(false),
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.cancel,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.of(
                                                      context,
                                                    ).pop(true),
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.delete,
                                                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                        if (confirmDelete == true) {
                                          await _firestoreService.deleteGroup(
                                            group.firestoreId!,
                                          );
                                        }
                                      },
                                      tooltip: AppLocalizations.of(context)!.deleteGroup,
                                    ),
                                  ],
                                ),
                          onTap: () {
                            if (widget.isForSelection) {
                              Navigator.of(context).pop({
                                'id': group.firestoreId!,
                                'name': group.name,
                              });
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => GroupDetailScreen(
                                    groupId: group.firestoreId!,
                                    groupName: group.name,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addGroupFab', // Unique tag
        onPressed: () => _showGroupDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}