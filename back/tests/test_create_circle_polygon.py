import unittest
from shapely.geometry import Point
from app.services.inject_reports_route import create_circle_polygon

class TestCreateCirclePolygon(unittest.TestCase):
    def test_output_type(self):
        """Test that the function returns a list of coordinates"""
        lat, lng = 48.8566, 2.3522
        radius = 5  # 5 meters
        polygon = create_circle_polygon(lat, lng, radius)

        # Output should be a list
        self.assertIsInstance(polygon, list)
        # Each element should be a tuple/list of 2 floats
        for coord in polygon:
            self.assertEqual(len(coord), 2)
            self.assertIsInstance(coord[0], float)
            self.assertIsInstance(coord[1], float)

    def test_number_of_points(self):
        """Test that the function returns the correct number of points for quad_segs=2"""
        lat, lng = 48.8566, 2.3522
        radius = 5
        polygon = create_circle_polygon(lat, lng, radius)

        # quad_segs=2 → octagon → 8 points + 1 to close the polygon
        self.assertEqual(len(polygon), 9)  # Shapely automatically closes the polygon

    def test_point_inside_polygon(self):
        """Test that the center point is approximately at the polygon's center"""
        lat, lng = 48.8566, 2.3522
        radius = 5
        polygon = create_circle_polygon(lat, lng, radius)

        # Approximate the center of the polygon
        avg_lat = sum(coord[1] for coord in polygon) / len(polygon)
        avg_lng = sum(coord[0] for coord in polygon) / len(polygon)

        self.assertAlmostEqual(avg_lat, lat, places=4)
        self.assertAlmostEqual(avg_lng, lng, places=4)

    def test_radius_conversion(self):
        """Test that the radius in meters is correctly converted to degrees"""
        lat, lng = 48.8566, 2.3522
        radius = 111  # 111 meters → approx 0.001°
        polygon = create_circle_polygon(lat, lng, radius)

        # Check that the distance between the center and a vertex is close to 0.001°
        first_point = polygon[0]
        delta_lat = abs(first_point[1] - lat)
        delta_lng = abs(first_point[0] - lng)
        self.assertAlmostEqual(delta_lat, radius / 111000, places=5)
        self.assertAlmostEqual(delta_lng, radius / 111000, places=5)  # approximate

if __name__ == "__main__":
    unittest.main()
