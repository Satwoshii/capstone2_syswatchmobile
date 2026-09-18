class StudentUser {
  final int id;
  final String displayName;
  final String email;
  final String? studentId;
  final String authMethod;

  const StudentUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.studentId,
    this.authMethod = 'email_otp',
  });

  factory StudentUser.fromJson(Map<String, dynamic> json) => StudentUser(
        id: int.tryParse('${json['id']}') ?? 0,
        displayName: '${json['display_name'] ?? ''}',
        email: '${json['email'] ?? ''}',
        studentId: json['student_id']?.toString(),
        authMethod: '${json['auth_method'] ?? 'email_otp'}',
      );
}

class OtpRequestResult {
  final String email;
  final int expiresInSeconds;
  final int resendAfterSeconds;
  final String? debugCode;

  const OtpRequestResult({
    required this.email,
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
    this.debugCode,
  });
}

class LabPc {
  final int id;
  final String workstationId;
  final String name;
  final String status;

  const LabPc({
    required this.id,
    required this.workstationId,
    required this.name,
    required this.status,
  });

  factory LabPc.fromJson(Map<String, dynamic> json) => LabPc(
        id: int.tryParse('${json['id']}') ?? 0,
        workstationId: '${json['workstation_id'] ?? ''}',
        name: '${json['pc_name'] ?? ''}',
        status: '${json['status'] ?? 'unknown'}',
      );
}

class LabRoom {
  final int id;
  final String name;
  final List<LabPc> pcs;

  const LabRoom({required this.id, required this.name, required this.pcs});

  factory LabRoom.fromJson(Map<String, dynamic> json) => LabRoom(
        id: int.tryParse('${json['id']}') ?? 0,
        name: '${json['name'] ?? ''}',
        pcs: (json['pcs'] as List? ?? const <dynamic>[])
            .map((e) => LabPc.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class StudentReport {
  final int id;
  final String reportCode;
  final String roomName;
  final String pcName;
  final String category;
  final String severity;
  final String description;
  final String status;
  final String? handlerName;
  final String? evidenceUrl;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? resolvedAt;

  const StudentReport({
    required this.id,
    required this.reportCode,
    required this.roomName,
    required this.pcName,
    required this.category,
    required this.severity,
    required this.description,
    required this.status,
    this.handlerName,
    this.evidenceUrl,
    this.createdAt,
    this.acceptedAt,
    this.resolvedAt,
  });

  factory StudentReport.fromJson(Map<String, dynamic> json) => StudentReport(
        id: int.tryParse('${json['id']}') ?? 0,
        reportCode: '${json['report_code'] ?? ''}',
        roomName: '${json['room_name'] ?? ''}',
        pcName: '${json['pc_name'] ?? 'General laboratory issue'}',
        category: '${json['category'] ?? ''}',
        severity: '${json['severity'] ?? ''}',
        description: '${json['description'] ?? ''}',
        status: '${json['status'] ?? ''}',
        handlerName: json['handler_name']?.toString(),
        evidenceUrl: json['evidence_url']?.toString(),
        createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
        acceptedAt: DateTime.tryParse('${json['accepted_at'] ?? ''}'),
        resolvedAt: DateTime.tryParse('${json['resolved_at'] ?? ''}'),
      );
}

class CreatedReport {
  final int id;
  final String code;
  final bool duplicate;

  const CreatedReport({
    required this.id,
    required this.code,
    required this.duplicate,
  });
}
