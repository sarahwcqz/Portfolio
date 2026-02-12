// DEBUG < - les choses a enlever
// DEV <- les choses a changer en prod

commande pour lancer le serveur (from back/): uvicorn app.main:app --reload
/!\ activer la venv (from back) : .\env\Scripts\activate 

commande pour mettre a jour les dpdces :
    back : pip install -r requirements.txt

commande pour lancer les tests:
back : pytest -v tests/test_get_reports_from_db.py