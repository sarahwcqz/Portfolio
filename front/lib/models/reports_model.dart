class ReportModel {
  final String id;
  final String type;
  final double lat;
  final double lng;

  ReportModel({
    required this.id,
    required this.type,
    required this.lat,
    required this.lng,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      type: json['type'],
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
    );
  }
}