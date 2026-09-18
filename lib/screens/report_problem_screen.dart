import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_models.dart';
import '../services/api_service.dart';

class ReportProblemScreen extends StatefulWidget {
  final VoidCallback onSubmitted;

  const ReportProblemScreen({super.key, required this.onSubmitted});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _picker = ImagePicker();

  List<LabRoom> _rooms = <LabRoom>[];
  LabRoom? _room;
  LabPc? _pc;
  String _category = 'peripheral';
  XFile? _evidence;
  bool _loading = true;
  bool _sending = false;
  String? _loadError;

  static const Map<String, String> _categories = <String, String>{
    'peripheral': 'Keyboard / Mouse / Monitor',
    'hardware': 'Internal Hardware / PC',
    'software': 'Software / Application',
    'network': 'Network / LAN',
    'other': 'Other Laboratory Problem',
  };

  @override
  void initState() {
    super.initState();
    _loadLabs();
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadLabs() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final rooms = await ApiService.instance.fetchLabs();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _room = null;
        _pc = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chooseImageSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (image != null && mounted) {
      setState(() => _evidence = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a laboratory first.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final result = await ApiService.instance.createReport(
        roomId: _room!.id,
        workstationId: _pc?.id,
        category: _category,
        description: _description.text,
        evidencePath: _evidence?.path,
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, size: 46),
          title: Text(result.duplicate ? 'Report Already Exists' : 'Report Submitted'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                result.code,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                result.duplicate
                    ? 'The same unresolved report was recently submitted. Syswatch kept the existing report instead of creating a duplicate.'
                    : 'Your report has been sent to ITSO. You can track its status under My Reports.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('View My Reports'),
            ),
          ],
        ),
      );

      _description.clear();
      setState(() {
        _room = null;
        _pc = null;
        _category = 'peripheral';
        _evidence = null;
      });
      widget.onSubmitted();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.wifi_off_outlined, size: 52),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadLabs,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Select the laboratory and computer with the problem.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<LabRoom>(
                    value: _room,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Laboratory'),
                    items: _rooms
                        .map(
                          (room) => DropdownMenuItem<LabRoom>(
                            value: room,
                            child: Text('Laboratory ${room.name}'),
                          ),
                        )
                        .toList(),
                    onChanged: _sending
                        ? null
                        : (room) => setState(() {
                              _room = room;
                              _pc = null;
                            }),
                    validator: (value) =>
                        value == null ? 'Select a laboratory.' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<LabPc?>(
                    value: _pc,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Computer',
                      helperText: 'Choose General only if the issue affects the laboratory rather than one PC.',
                    ),
                    items: <DropdownMenuItem<LabPc?>>[
                      const DropdownMenuItem<LabPc?>(
                        value: null,
                        child: Text('General laboratory issue'),
                      ),
                      if (_room != null)
                        ..._room!.pcs.map(
                          (pc) => DropdownMenuItem<LabPc?>(
                            value: pc,
                            child: Text('${pc.name} • ${pc.status.toUpperCase()}'),
                          ),
                        ),
                    ],
                    onChanged: _room == null || _sending
                        ? null
                        : (pc) => setState(() => _pc = pc),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Problem Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Problem type'),
                    items: _categories.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: _sending
                        ? null
                        : (value) =>
                            setState(() => _category = value ?? 'other'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    enabled: !_sending,
                    minLines: 4,
                    maxLines: 7,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Describe the problem',
                      hintText: 'Example: The keyboard spacebar is not responding.',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.length < 5) {
                        return 'Describe the problem in at least 5 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _sending ? null : _chooseImageSource,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      _evidence == null ? 'Add Photo Evidence' : 'Change Photo',
                    ),
                  ),
                  if (_evidence != null) ...<Widget>[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_evidence!.path),
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _sending
                          ? null
                          : () => setState(() => _evidence = null),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove Photo'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _sending ? null : _submit,
            icon: _sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Text('Submit Report'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
