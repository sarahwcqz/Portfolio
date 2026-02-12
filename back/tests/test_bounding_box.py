import unittest
from app.services.inject_reports_route import calculate_bounding_box

class TestCalculateBoundingBox(unittest.TestCase):
    def test_basic_case(self):
        """Test a simple case with start < dest for both lat and lng"""
        start_lat = 48.8566
        start_lng = 2.3522
        dest_lat = 48.8606
        dest_lng = 2.3572

        min_lat, max_lat, min_lng, max_lng = calculate_bounding_box(
            start_lat, start_lng, dest_lat, dest_lng, margin=0.05
        )

        self.assertAlmostEqual(min_lat, 48.8566 - 0.05)
        self.assertAlmostEqual(max_lat, 48.8606 + 0.05)
        self.assertAlmostEqual(min_lng, 2.3522 - 0.05)
        self.assertAlmostEqual(max_lng, 2.3572 + 0.05)

    def test_reverse_coordinates(self):
        """Test when start > dest to ensure min/max logic works"""
        start_lat = 48.8606
        start_lng = 2.3572
        dest_lat = 48.8566
        dest_lng = 2.3522

        min_lat, max_lat, min_lng, max_lng = calculate_bounding_box(
            start_lat, start_lng, dest_lat, dest_lng, margin=0.05
        )

        self.assertAlmostEqual(min_lat, 48.8566 - 0.05)
        self.assertAlmostEqual(max_lat, 48.8606 + 0.05)
        self.assertAlmostEqual(min_lng, 2.3522 - 0.05)
        self.assertAlmostEqual(max_lng, 2.3572 + 0.05)

    def test_custom_margin(self):
        """Test with a custom margin"""
        start_lat = 0
        start_lng = 0
        dest_lat = 1
        dest_lng = 1
        margin = 0.1

        min_lat, max_lat, min_lng, max_lng = calculate_bounding_box(
            start_lat, start_lng, dest_lat, dest_lng, margin=margin
        )

        self.assertEqual(min_lat, -0.1)
        self.assertEqual(max_lat, 1.1)
        self.assertEqual(min_lng, -0.1)
        self.assertEqual(max_lng, 1.1)

if __name__ == "__main__":
    unittest.main()
