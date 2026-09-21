import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import '../services/api_service.dart';

class MyReportsScreen extends StatefulWidget {
  final VoidCallback? onNewReportRequested;

  const MyReportsScreen({
    super.key,
    this.onNewReportRequested,
  });

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late Future<List<StudentReport>> _future;
  final _dateFormat = DateFormat('MMM d, yyyy • h:mm a');

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = ApiService.instance.fetchMyReports();
  }

  String _pretty(String value) {
    if (value.isEmpty) return value;
    return value.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  // ── Status Pill Customization ─────────────────────────────────────────────
  IconData _statusIcon(String status) {
    switch (status) {
      case 'resolved':
        return Icons.check_circle_rounded;
      case 'in_progress':
        return Icons.build_circle_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _statusColor(ColorScheme scheme, String status) {
    switch (status) {
      case 'resolved':
        return const Color(0xFF10B981); // Emerald Green
      case 'in_progress':
        return const Color(0xFF0284C7); // Light Blue
      default:
        return scheme.secondary; // SysWatch Gold / Amber
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<StudentReport>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(
                  color: scheme.primary,
                  strokeWidth: 2.5,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading your reports...',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 38,
                          color: scheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to Load Reports',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () => setState(_reload),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Try Again'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final reports = snapshot.data ?? const <StudentReport>[];

        if (reports.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                const SizedBox(height: 60),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              Icons.inbox_outlined,
                              size: 42,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'No Reports Yet',
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You have not submitted any laboratory issue reports. Submitted tickets will appear here for status updates.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                          if (widget.onNewReportRequested != null) ...<Widget>[
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: widget.onNewReportRequested,
                                icon: const Icon(Icons.add_alert_rounded,
                                    size: 18),
                                label: const Text('Report a Problem'),
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _future;
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(scheme, report);
            },
          ),
        );
      },
    );
  }

  // ── Report Item Card ──────────────────────────────────────────────────────
  Widget _buildReportCard(ColorScheme scheme, StudentReport report) {
    final statusColor = _statusColor(scheme, report.status);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header row: Report Code & Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.reportCode,
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            _statusIcon(report.status),
                            size: 15,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _pretty(report.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Location detail
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.science_outlined,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Laboratory ${report.roomName}',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.computer_outlined,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        report.pcName,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Category & Severity tags
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: <Widget>[
                    Chip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      labelPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: scheme.surface,
                      side: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                      label: Text(
                        _pretty(report.category),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    if (report.severity.isNotEmpty)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: scheme.surface,
                        side: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                        label: Text(
                          _pretty(report.severity),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    report.description,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 10),

                // Metadata Timeline
                if (report.createdAt != null)
                  _buildTimelineRow(
                    scheme: scheme,
                    icon: Icons.calendar_today_outlined,
                    label:
                        'Submitted: ${_dateFormat.format(report.createdAt!.toLocal())}',
                  ),
                if (report.handlerName != null &&
                    report.handlerName!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  _buildTimelineRow(
                    scheme: scheme,
                    icon: Icons.person_outline_rounded,
                    label: 'Handled by: ${report.handlerName}',
                  ),
                ],
                if (report.resolvedAt != null) ...<Widget>[
                  const SizedBox(height: 4),
                  _buildTimelineRow(
                    scheme: scheme,
                    icon: Icons.verified_outlined,
                    label:
                        'Resolved: ${_dateFormat.format(report.resolvedAt!.toLocal())}',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineRow({
    required ColorScheme scheme,
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 13,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}
