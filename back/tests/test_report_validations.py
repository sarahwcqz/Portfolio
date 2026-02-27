import pytest
from fastapi import HTTPException
from unittest.mock import Mock, patch
from app.utils.report_validations import (
    check_report_exists,
    check_user_has_not_voted
)


# ─── TEST check_report_exists ──────────────────────────────────

def test_check_report_exists_success():
    """Test : Le signalement existe → Retourne les données"""
    
    # Mock Supabase
    mock_response = Mock()
    mock_response.data = {
        "id": "abc123",
        "type": "accident",
        "confirmations_count": 5
    }
    
    # Patch de supabase.table().select()...
    with patch('app.utils.report_validations.supabase') as mock_supabase:
        mock_supabase.table.return_value \
            .select.return_value \
            .eq.return_value \
            .single.return_value \
            .execute.return_value = mock_response
        
        result = check_report_exists("abc123")
        
        assert result == mock_response.data
        assert result["type"] == "accident"


def test_check_report_exists_not_found():
    """Test : REport doesn't exists → HTTPException 404"""
    
    # Mock Supabase
    mock_response = Mock()
    mock_response.data = None
    
    with patch('app.utils.report_validations.supabase') as mock_supabase:
        mock_supabase.table.return_value \
            .select.return_value \
            .eq.return_value \
            .single.return_value \
            .execute.return_value = mock_response
        
        # expecting exception
        with pytest.raises(HTTPException) as exc_info:
            check_report_exists("xyz999")
        
        # Vérify code
        assert exc_info.value.status_code == 404
        assert "introuvable" in exc_info.value.detail


# ─── TEST check_user_has_not_voted ─────────────────────────────

def test_check_user_has_not_voted_success():
    """Test : User hasn't voted yet → OK"""
    
    # Mock : No confirmation found
    mock_response = Mock()
    mock_response.data = []
    
    with patch('app.utils.report_validations.supabase') as mock_supabase:
        mock_supabase.table.return_value \
            .select.return_value \
            .eq.return_value \
            .eq.return_value \
            .execute.return_value = mock_response
        
        # no exception
        check_user_has_not_voted("abc123", "user-456")


def test_check_user_has_not_voted_already_voted():
    """Test : User has already voted → HTTPException 400"""
    
    # Mock confirmation found
    mock_response = Mock()
    mock_response.data = [{"id": "confirmation-789"}]
    
    with patch('app.utils.report_validations.supabase') as mock_supabase:
        mock_supabase.table.return_value \
            .select.return_value \
            .eq.return_value \
            .eq.return_value \
            .execute.return_value = mock_response
        
        # expect exception
        with pytest.raises(HTTPException) as exc_info:
            check_user_has_not_voted("abc123", "user-456")
        
        assert exc_info.value.status_code == 400
        assert "déjà voté" in exc_info.value.detail