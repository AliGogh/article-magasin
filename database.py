import pymysql
import os
from dotenv import load_dotenv


class Database:
    """Petit wrapper autour de PyMySQL utilisé par les routes Flask.

    Cette classe centralise la connexion et les opérations fréquentes pour que
    server.py n'ait pas à répéter la configuration MySQL à chaque requête.
    """

    def __init__(self):
        # Charge les variables d'environnement définies dans .env afin de ne pas
        # écrire les identifiants de connexion directement dans le code.
        load_dotenv()

        self.host = os.getenv("HOST")
        self.port = int(os.getenv("PORT"))
        self.database = os.getenv("DATABASE")
        self.user = os.getenv("DB_USER")
        self.password = os.getenv("PASSWORD")

        self._open_sql_connection()

    def _open_sql_connection(self):
        """Ouvre une connexion MySQL avec des résultats sous forme de dictionnaires."""
        self.connection = pymysql.connect(
            host=self.host,
            port=self.port,
            user=self.user,
            password=self.password,
            db=self.database,
            autocommit=True,
            cursorclass=pymysql.cursors.DictCursor
        )
        self.cursor = self.connection.cursor()

    def execute(self, query, params=None):
        """Exécute une requête SQL paramétrée.

        Les paramètres sont passés séparément de la requête pour éviter les
        injections SQL et pour laisser PyMySQL convertir correctement les types.
        """
        try:
            self.cursor.execute(query, params or ())
            return self.cursor
        except Exception as e:
            print(f"Erreur SQL: {e}")
            self.connection.rollback()
            raise

    def fetchall(self):
        """Retourne toutes les lignes de la dernière requête SELECT."""
        return self.cursor.fetchall()

    def fetchone(self):
        """Retourne une seule ligne de la dernière requête SELECT."""
        return self.cursor.fetchone()

    def call_procedure(self, name, params=None):
        """Appelle une procédure stockée MySQL par son nom."""
        self.cursor.callproc(name, params or ())

    def close(self):
        """Ferme proprement le curseur et la connexion à la base."""
        self.cursor.close()
        self.connection.close()
