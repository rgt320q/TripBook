import 'package:flutter/material.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/location_group.dart';

class MultiGroupSelector extends StatelessWidget {
  final List<String> selectedGroupIds;
  final List<LocationGroup> allGroups;
  final Function(List<String>) onChanged;
  final Future<LocationGroup?> Function() onAddNewGroup;
  final bool readOnly;

  const MultiGroupSelector({
    super.key,
    required this.selectedGroupIds,
    required this.allGroups,
    required this.onChanged,
    required this.onAddNewGroup,
    this.readOnly = false,
  });

  void _showSelectionDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<String> tempSelectedIds = List.from(selectedGroupIds);
    List<LocationGroup> tempAllGroups = List.from(allGroups);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.selectGroups),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: tempAllGroups.length,
                        itemBuilder: (context, index) {
                          final group = tempAllGroups[index];
                          final isSelected = tempSelectedIds.contains(group.firestoreId);
                          return CheckboxListTile(
                            title: Text(group.name),
                            secondary: CircleAvatar(
                              backgroundColor: Color(group.color!),
                              radius: 12,
                            ),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  tempSelectedIds.add(group.firestoreId!);
                                } else {
                                  tempSelectedIds.remove(group.firestoreId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
                      title: Text(
                        l10n.addNewGroup,
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                      onTap: () async {
                        final newGroup = await onAddNewGroup();
                        if (newGroup != null) {
                          setState(() {
                            tempAllGroups.add(newGroup);
                            tempSelectedIds.add(newGroup.firestoreId!);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    onChanged(tempSelectedIds);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('OK'),
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
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.groups,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...selectedGroupIds.map((id) {
              final group = allGroups.firstWhere(
                (g) => g.firestoreId == id,
                orElse: () => LocationGroup(name: '?', userId: ''),
              );
              if (group.name == '?') return const SizedBox.shrink();
              
              final color = Color(group.color!);
              return InputChip(
                label: Text(group.name),
                backgroundColor: color.withOpacity(0.1),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: readOnly ? null : () {
                  final newList = List<String>.from(selectedGroupIds)..remove(id);
                  onChanged(newList);
                },
              );
            }),
            if (!readOnly)
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: Text(l10n.addGroups),
                onPressed: () => _showSelectionDialog(context),
              ),
          ],
        ),
      ],
    );
  }
}
