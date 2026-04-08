import pymysql
import os
from dotenv import load_dotenv


class Database:
    def __init__(self):
        load_dotenv()

        self.host = os.getenv("HOST")
        self.port = int(os.getenv("PORT"))
        self.database = os.getenv("DATABASE")
        self.user = os.getenv("DB_USER")
        self.password = os.getenv("PASSWORD")

        self._open_sql_connection()

    def _open_sql_connection(self):
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
        try:
            self.cursor.execute(query, params or ())
            return self.cursor
        except Exception as e:
            print(f"Erreur SQL: {e}")
            self.connection.rollback()
            raise

    def fetchall(self):
        return self.cursor.fetchall()

    def fetchone(self):
        return self.cursor.fetchone()

    def call_procedure(self, name, params=None):
        self.cursor.callproc(name, params or ())

    def close(self):
        self.cursor.close()
        self.connection.close()