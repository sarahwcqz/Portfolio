class RouteRequest {
  final double startLat;
  final double startLng;
  final double destLat;
  final double destLng;

  RouteRequest({
    required this.startLat,
    required this.startLng,
    required this.destLat,
    required this.destLng,
  });

  Map<String, dynamic> toJson() => {
        'start_lat': startLat,
        'start_lng': startLng,
        'dest_lat': destLat,
        'dest_lng': destLng,
      };
}