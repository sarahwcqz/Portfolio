from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    
    #server
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    #supabase
    SUPABASE_URL : str
    SUPABASE_ANON_KEY : str
    SUPABASE_SERVICE_ROLE_KEY: str

    #ORS
    ORS_URL : str
    ORS_KEY : str

    # pydantic-settings class to read var from a file and map them
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )

# to use 'settings.<...>' when calling APIs
settings = Settings()