import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:tripbook/models/reached_location_log.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tripbook/l10n/app_localizations.dart';

class ReachedLocationsScreen extends StatefulWidget {
  final String? highlightedLogId;
  const ReachedLocationsScreen({super.key, this.highlightedLogId});

  @override
  State<ReachedLocationsScreen> createState() => _ReachedLocationsScreenState();
}

class _ReachedLocationsScreenState extends State<ReachedLocationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  SortOrder _sortOrder = SortOrder.dateDescending;

  @override
  void dispose() {
    _firestoreService.markAllLogsAsUnread();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<ReachedLocationLog>>(
      stream: _firestoreService.getReachedLocationLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.reachedLocationsLog),
              backgroundColor: Colors.blue[700],
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.reachedLocationsLog),
              backgroundColor: Colors.blue[700],
            ),
            body: Center(
              child: Text(l10n.noReachedLocations, textAlign: TextAlign.center),
            ),
          );
        }

        List<ReachedLocationLog> logs = snapshot.data!;
        _sortLogs(logs);

        final bool areAllRead = logs.every((log) => log.isRead);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.reachedLocationsLog),
            backgroundColor: Colors.blue[700],
            actions: [
              IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: areAllRead ? l10n.unselectAll : l10n.selectAll,
                onPressed: () async {
                  if (areAllRead) {
                    await _firestoreService.markAllLogsAsUnread();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.allLogsMarkedAsUnread)),
                    );
                  } else {
                    await _firestoreService.markAllLogsAsRead();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.allLogsMarkedAsRead)),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: l10n.deleteRead,
                onPressed: () async {
                  await _firestoreService.deleteReadLogs();
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.readLogsDeleted)));
                },
              ),
              PopupMenuButton<SortOrder>(
                onSelected: (SortOrder result) {
                  setState(() {
                    _sortOrder = result;
                  });
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<SortOrder>>[
                      PopupMenuItem<SortOrder>(
                        value: SortOrder.dateDescending,
                        child: Text(l10n.sortByDateNew),
                      ),
                      PopupMenuItem<SortOrder>(
                        value: SortOrder.dateAscending,
                        child: Text(l10n.sortByDateOld),
                      ),
                      PopupMenuItem<SortOrder>(
                        value: SortOrder.nameAscending,
                        child: Text(l10n.sortByNameAsc),
                      ),
                      PopupMenuItem<SortOrder>(
                        value: SortOrder.nameDescending,
                        child: Text(l10n.sortByNameDesc),
                      ),
                    ],
                icon: const Icon(Icons.sort),
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final isHighlighted = log.id == widget.highlightedLogId;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: isHighlighted ? Colors.yellow.shade100 : null,
                child: ListTile(
                  leading: Checkbox(
                    value: log.isRead,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _firestoreService.updateReachedLocationLog(
                          log.id!,
                          isRead: value,
                        );
                      }
                    },
                  ),
                  title: Text(
                    log.locationName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${l10n.reachedAt}: ${DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp.toDate())}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.open_in_browser,
                      color: Colors.blue,
                    ), // Changed icon
                    tooltip: l10n.moreInfo, // Changed tooltip
                    onPressed: () async {
                      if (log.infoUrl.isNotEmpty) {
                        final uri = Uri.parse(log.infoUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _sortLogs(List<ReachedLocationLog> logs) {
    logs.sort((a, b) {
      switch (_sortOrder) {
        case SortOrder.dateDescending:
          return b.timestamp.compareTo(a.timestamp);
        case SortOrder.dateAscending:
          return a.timestamp.compareTo(b.timestamp);
        case SortOrder.nameAscending:
          return a.locationName.compareTo(b.locationName);
        case SortOrder.nameDescending:
          return b.locationName.compareTo(a.locationName);
      }
    });
  }
}

enum SortOrder { dateDescending, dateAscending, nameAscending, nameDescending }
