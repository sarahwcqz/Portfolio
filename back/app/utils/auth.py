from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from supabase import create_client
from app.config import settings

supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)
security = HTTPBearer()


async def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> str:
    """
    Get user_id with JWT Supabase token.

    """
    token = credentials.credentials
    
    try:
        user_info = supabase.auth.get_user(token)
        
        if not user_info or not user_info.user:
            raise HTTPException(
                status_code=401,
                detail="Token invalide ou expiré"
            )
        
        return user_info.user.id
        
    except Exception as e:
        raise HTTPException(
            status_code=401,
            detail=f"Authentification échouée: {str(e)}"
        )