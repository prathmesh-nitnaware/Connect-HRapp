class VaultDocument {
  final String id;
  final String employeeId;
  final String title;
  final String category;
  final String fileName;
  final String fileSize;
  final String uploadDate;
  final bool verified;

  VaultDocument({
    required this.id,
    required this.employeeId,
    required this.title,
    required this.category,
    required this.fileName,
    required this.fileSize,
    required this.uploadDate,
    required this.verified,
  });

  factory VaultDocument.fromJson(Map<String, dynamic> json) {
    return VaultDocument(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Other',
      fileName: json['file_name']?.toString() ?? '',
      fileSize: json['file_size']?.toString() ?? '',
      uploadDate: json['upload_date']?.toString() ?? '',
      verified: json['verified'] == true,
    );
  }
}

class CompanyAsset {
  final String id;
  final String employeeId;
  final String employeeName;
  final String assetTag;
  final String assetName;
  final String type;
  final String serialNumber;
  final String assignedDate;
  final String status;

  CompanyAsset({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.assetTag,
    required this.assetName,
    required this.type,
    required this.serialNumber,
    required this.assignedDate,
    required this.status,
  });

  factory CompanyAsset.fromJson(Map<String, dynamic> json) {
    return CompanyAsset(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      assetTag: json['asset_tag']?.toString() ?? '',
      assetName: json['asset_name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'General',
      serialNumber: json['serial_number']?.toString() ?? '',
      assignedDate: json['assigned_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
    );
  }
}
