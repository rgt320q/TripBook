import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:intl/intl.dart';
import 'package:tripbook/models/reached_location_log.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/utils/brand_colors.dart';

class ReachedLocationsScreen extends StatefulWidget {
  final String? highlightedLogId;
  const ReachedLocationsScreen({super.key, this.highlightedLogId});

  @override
  State<ReachedLocationsScreen> createState() => _ReachedLocationsScreenState();
}

class _ReachedLocationsScreenState extends State<ReachedLocationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  SortOrder _sortOrder = SortOrder.dateDescending;
  final Set<String> _expandedNoteIds = {};
  final RegExp _urlPattern = RegExp(r'https?://\S+');

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
              backgroundColor: brandAppBarBlue(Theme.of(context).brightness),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.reachedLocationsLog),
              backgroundColor: brandAppBarBlue(Theme.of(context).brightness),
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
            title: Text(
              l10n.reachedLocationsLog,
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
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.done_all, color: Colors.white),
                    tooltip: areAllRead ? l10n.unselectAll : l10n.selectAll,
                    onPressed: () async {
                  if (areAllRead) {
                    await _firestoreService.markAllLogsAsUnread();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.allLogsMarkedAsUnread)),
                      );
                    }
                  } else {
                    await _firestoreService.markAllLogsAsRead();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.allLogsMarkedAsRead)),
                      );
                    }
                  }
                },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.white),
                    tooltip: l10n.deleteRead,
                    onPressed: () async {
                      await _firestoreService.deleteReadLogs();
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(l10n.readLogsDeleted)));
                      }
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PopupMenuButton<SortOrder>(
                    icon: const Icon(Icons.sort, color: Colors.white),
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
                  ),
                ),
              ),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    brandAppBarBlue(Theme.of(context).brightness),
                    Colors.blue[900]!,
                  ],
                ),
              ),
            ),
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
                  subtitle: _buildLogSubtitle(context, log),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.open_in_browser,
                      color: Colors.blue,
                    ), // Changed icon
                    tooltip: l10n.moreInfo, // Changed tooltip
                    onPressed: () async {
                      if (log.infoUrl.isNotEmpty) {
                        final uri = Uri.parse(log.infoUrl);
                        // Only allow http(s) so a crafted infoUrl cannot
                        // trigger custom schemes (e.g. intent:) on tap.
                        if ((uri.isScheme('https') || uri.isScheme('http')) &&
                            await canLaunchUrl(uri)) {
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

  Widget _buildLogSubtitle(BuildContext context, ReachedLocationLog log) {
    final l10n = AppLocalizations.of(context)!;
    final note = log.note;
    final hasNote = note != null && note.isNotEmpty;
    final expanded = _expandedNoteIds.contains(log.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.reachedAt}: '
          '${DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp.toDate())}',
        ),
        if (hasNote) ...[
          const SizedBox(height: 4),
          GestureDetector(
            // Tapping the note body expands/collapses it; taps on a link
            // inside win over this handler.
            onTap: () => _toggleNote(log.id),
            child: Text.rich(
              TextSpan(children: _buildNoteSpans(context, note)),
              maxLines: expanded ? null : 2,
              overflow: expanded ? null : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (log.id != null)
            GestureDetector(
              onTap: () => _toggleNote(log.id),
              child: Text(
                expanded ? l10n.collapse : l10n.expand,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ],
    );
  }

  /// Splits the note into plain text and tappable http(s) link spans.
  List<InlineSpan> _buildNoteSpans(BuildContext context, String note) {
    const linkStyle = TextStyle(
      color: Colors.blue,
      decoration: TextDecoration.underline,
    );

    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in _urlPattern.allMatches(note)) {
      if (match.start > start) {
        spans.add(TextSpan(text: note.substring(start, match.start)));
      }
      final cleanUrl = _trimTrailingPunctuation(note.substring(
        match.start,
        match.end,
      ));
      spans.add(
        TextSpan(
          text: cleanUrl,
          style: linkStyle,
          recognizer: TapGestureRecognizer()..onTap = () => _openNoteUrl(cleanUrl),
        ),
      );
      start = match.end;
    }
    if (start < note.length) {
      spans.add(TextSpan(text: note.substring(start)));
    }
    return spans;
  }

  String _trimTrailingPunctuation(String url) {
    var end = url.length;
    while (end > 0 && '.,;:!?)]}"\'`'.contains(url[end - 1])) {
      end--;
    }
    return url.substring(0, end);
  }

  Future<void> _openNoteUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    // Only allow http(s) so a crafted note cannot trigger custom schemes.
    if (!(uri.isScheme('https') || uri.isScheme('http'))) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _toggleNote(String? logId) {
    if (logId == null) return;
    setState(() {
      if (_expandedNoteIds.contains(logId)) {
        _expandedNoteIds.remove(logId);
      } else {
        _expandedNoteIds.add(logId);
      }
    });
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
