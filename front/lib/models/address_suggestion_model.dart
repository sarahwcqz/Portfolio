class AddressSuggestion {
  final String label;
  final double lat;
  final double lon;
  final bool isCurrentPosition;

  AddressSuggestion({
    required this.label,
    required this.lat,
    required this.lon,
    this.isCurrentPosition = false,
  });

  // converts lat + long in double
  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      label: json['display_name'] as String,
      lat: double.parse(json['lat'] as String),
      lon: double.parse(json['lon'] as String),
    );
  }
}