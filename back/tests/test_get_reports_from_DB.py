import pytest
from app.services.get_reports_from_DB import get_reports_from_DB

# Example coordinates in a small area
MIN_LAT = 48.8560
MAX_LAT = 48.8580
MIN_LNG = 2.3520
MAX_LNG = 2.3540

@pytest.mark.asyncio
async def test_get_reports_returns_list():
    """
    Test that get_reports_from_DB returns a list, even if empty.
    """
    reports = await get_reports_from_DB(MIN_LAT, MAX_LAT, MIN_LNG, MAX_LNG)
    assert isinstance(reports, list)

@pytest.mark.asyncio
async def test_reports_have_expected_fields():
    """
    Test that each report contains lat, lng, and radius_meters.
    """
    reports = await get_reports_from_DB(MIN_LAT, MAX_LAT, MIN_LNG, MAX_LNG)
    for report in reports:
        assert "lat" in report
        assert "lng" in report
        assert "radius_meters" in report

@pytest.mark.asyncio
async def test_reports_inside_bounding_box():
    """
    Test that returned reports are within the bounding box.
    """
    reports = await get_reports_from_DB(MIN_LAT, MAX_LAT, MIN_LNG, MAX_LNG)
    for report in reports:
        assert MIN_LAT <= report["lat"] <= MAX_LAT
        assert MIN_LNG <= report["lng"] <= MAX_LNG
