import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import '../services/api_service.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

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

  String _pretty(String value) =>
      value.replaceAll('_', ' ').split(' ').map((word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1)}';
      }).join(' ');

  IconData _statusIcon(String status) {
    switch (status) {
      case 'resolved':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.build_circle_outlined;
      default:
        return Icons.schedule_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StudentReport>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => setState(_reload),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
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
              children: const <Widget>[
                SizedBox(height: 170),
                Icon(Icons.inbox_outlined, size: 58),
                SizedBox(height: 12),
                Center(child: Text('You have not submitted any reports yet.')),
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
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              report.reportCode,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Chip(
                            avatar: Icon(_statusIcon(report.status), size: 18),
                            label: Text(_pretty(report.status)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Laboratory ${report.roomName} • ${report.pcName}'),
                      Text('${_pretty(report.category)} • ${_pretty(report.severity)}'),
                      const Divider(height: 22),
                      Text(report.description),
                      const SizedBox(height: 10),
                      if (report.createdAt != null)
                        Text(
                          'Submitted: ${_dateFormat.format(report.createdAt!.toLocal())}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (report.handlerName != null &&
                          report.handlerName!.isNotEmpty)
                        Text(
                          'Handled by: ${report.handlerName}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (report.resolvedAt != null)
                        Text(
                          'Resolved: ${_dateFormat.format(report.resolvedAt!.toLocal())}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
