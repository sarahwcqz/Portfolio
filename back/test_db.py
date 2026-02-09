from app.config import settings
from supabase import create_client

# Création du client Supabase
supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_ANON_KEY)

# Exemple : lister les tables
try:
    response = supabase.table("incidents").select("*").execute()
    print("Connexion OK, tables récupérées :")
    print(response.data)
except Exception as e:
    print("Erreur de connexion :", e)
