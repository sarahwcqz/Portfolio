class BoundingBox {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  BoundingBox({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  // checks if mouvement >~100m
  bool hasSignificantlyChangedFrom(BoundingBox? other) {
    if (other == null) return true;

    const threshold = 0.001;
    return (minLat - other.minLat).abs() > threshold ||
        (maxLat - other.maxLat).abs() > threshold ||
        (minLng - other.minLng).abs() > threshold ||
        (maxLng - other.maxLng).abs() > threshold;
  }
}