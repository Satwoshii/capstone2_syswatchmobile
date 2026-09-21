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
    final scheme = Theme.of(context).colorScheme;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_camera_outlined, color: scheme.primary),
                ),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_outlined, color: scheme.primary),
                ),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
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
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Select a laboratory first.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
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
      final scheme = Theme.of(context).colorScheme;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              result.duplicate
                  ? Icons.info_outline_rounded
                  : Icons.check_circle_outline_rounded,
              size: 42,
              color: scheme.primary,
            ),
          ),
          title: Text(
            result.duplicate ? 'Report Already Exists' : 'Report Submitted',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  result.code,
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                result.duplicate
                    ? 'An unresolved report for this issue was recently submitted. SysWatch kept the existing report to prevent duplicate tickets.'
                    : 'Your report has been sent to ITSO. You can track its progress under My Reports.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View My Reports'),
              ),
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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(e.message),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('$e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(color: scheme.primary, strokeWidth: 2.5),
            const SizedBox(height: 16),
            Text(
              'Loading laboratory stations...',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_loadError != null) {
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
                      Icons.wifi_off_rounded,
                      size: 38,
                      color: scheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connection Error',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _loadError!,
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
                      onPressed: _loadLabs,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Header Banner
                _buildHeaderCard(scheme),
                const SizedBox(height: 18),

                // Card 1: Location Selection
                _buildCardContainer(
                  scheme: scheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildSectionTitle(
                        scheme: scheme,
                        stepNumber: '1',
                        title: 'Laboratory Location',
                        subtitle: 'Select the affected laboratory room and computer.',
                      ),
                      const SizedBox(height: 18),

                      // Laboratory Room Dropdown
                      DropdownButtonFormField<LabRoom>(
                        initialValue: _room,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Laboratory Room',
                          hintText: 'Select lab room',
                          prefixIcon: const Icon(Icons.science_outlined, size: 20),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                            value == null ? 'Please select a laboratory.' : null,
                      ),
                      const SizedBox(height: 14),

                      // Workstation/PC Dropdown
                      DropdownButtonFormField<LabPc?>(
                        initialValue: _pc,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Computer / Workstation',
                          helperText:
                              'Select "General" if the problem affects the entire lab.',
                          prefixIcon: const Icon(Icons.computer_outlined, size: 20),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                child: Text(
                                  '${pc.name} • ${pc.status.toUpperCase()}',
                                ),
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

                const SizedBox(height: 16),

                // Card 2: Issue Details
                _buildCardContainer(
                  scheme: scheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildSectionTitle(
                        scheme: scheme,
                        stepNumber: '2',
                        title: 'Problem Details',
                        subtitle: 'Specify the issue category and describe what happened.',
                      ),
                      const SizedBox(height: 18),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: InputDecoration(
                          labelText: 'Problem Category',
                          prefixIcon:
                              const Icon(Icons.category_outlined, size: 20),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                            : (value) => setState(
                                  () => _category = value ?? 'other',
                                ),
                      ),
                      const SizedBox(height: 14),

                      // Description Field
                      TextFormField(
                        controller: _description,
                        enabled: !_sending,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          labelText: 'Describe the problem',
                          hintText:
                              'Example: The keyboard spacebar is unresponsive or missing.',
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 50),
                            child: Icon(Icons.edit_note_outlined, size: 22),
                          ),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          final text = (value ?? '').trim();
                          if (text.length < 5) {
                            return 'Please describe the issue in at least 5 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Evidence Photo Attachment Section
                      _buildPhotoPicker(scheme),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Primary Submit Button
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _sending ? null : _submit,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.send_outlined, size: 19),
                              SizedBox(width: 10),
                              Text(
                                'Submit Report',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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

  // ── Header Card Banner ───────────────────────────────────────────────────
  Widget _buildHeaderCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.report_problem_outlined,
              color: scheme.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Submit a Laboratory Report',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Report malfunctioning PC hardware, peripherals, or lab equipment to ITSO.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable Card Styling ────────────────────────────────────────────────
  Widget _buildCardContainer({
    required ColorScheme scheme,
    required Widget child,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildSectionTitle({
    required ColorScheme scheme,
    required String stepNumber,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                stepNumber,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            subtitle,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── Evidence Photo Component ──────────────────────────────────────────────
  Widget _buildPhotoPicker(ColorScheme scheme) {
    if (_evidence == null) {
      return InkWell(
        onTap: _sending ? null : _chooseImageSource,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.add_a_photo_outlined,
                size: 20,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Attach Photo Evidence (Optional)',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.topRight,
            children: <Widget>[
              Image.file(
                File(_evidence!.path),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton.filled(
                  onPressed: _sending
                      ? null
                      : () => setState(() => _evidence = null),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: _sending ? null : _chooseImageSource,
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Change photo'),
        ),
      ],
    );
  }
}
