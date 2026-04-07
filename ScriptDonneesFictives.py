import random, mysql.connector
import os
from dotenv import load_dotenv

load_dotenv()

conn = mysql.connector.connect(
    host=os.getenv("MYSQL_HOST"),
    user=os.getenv("MYSQL_USER"),
    password=os.getenv("PASSWORD"),
    database=os.getenv("DATABASE"),
)

cursor = conn.cursor()

#######################################SECTION VÊTEMENT#######################################

tailles_list = ["S", "M", "L", "XL"]
couleurs_list = ["Noir", "Blanc", "Bleu", "Rouge", "Vert"]
sexes_list = ["Homme", "Femme"]
types_vetement = ["Tshirt", "Robe", "Jean", "Chemise", "Cotton ouatté"]
marques_list = ["Nike", "Lacoste", "Kenzo", "Uniqlo", "Levi's"]

for i in range(1, 101):
    prix = round(random.uniform(10, 200), 2)
    rabais = round(random.uniform(0, 0.5), 2)

    taille = random.choice(tailles_list)
    couleur = random.choice(couleurs_list)
    sexe = random.choice(sexes_list)
    nom = random.choice(types_vetement)
    marque = random.choice(marques_list)

    try:
        # Insert Produit
        cursor.execute(
            "INSERT INTO Produit (pid, prix, rabais, nom) VALUES (%s, %s, %s, %s)",
            (i, prix, rabais, nom)
        )

        # Insert Vetement
        cursor.execute(
            "INSERT INTO Vetement (pid, taille, sexe, couleur) VALUES (%s, %s, %s, %s)",
            (i, taille, sexe, couleur)
        )
        cursor.execute(
        "UPDATE Vetement SET marque = %s WHERE pid = %s",
        (marque, i)
    )

    except mysql.connector.Error as err:
        print(f"Erreur à l'insertion {i}: {err}")

conn.commit()
cursor.close()
conn.close()

#######################################SECTION MEUBLES#######################################

materiaux_list = ["Bois", "Tissu", "Métal", "Cuir"]
dimensions_list = ["100x50x60", "90x85x180", "150x50x60"]
couleursM_list = ["Noir", "Brun", "Blanc", "Gris"]
poids_list = [80, 160, 40, 200]
types_meubles = ["Frigidaire", "Commode", "Table", "Armoire"]

for i in range(101, 201):
    prix = round(random.uniform(100, 10000), 2)
    rabais = round(random.uniform(0, 0.5), 2)

    materiau = random.choice(materiaux_list)
    couleur = random.choice(couleursM_list)
    dimensionCM = random.choice(dimensions_list)
    nom = random.choice(types_meubles)
    poids = random.choice(poids_list)

    try:
        # Insert Produit
        cursor.execute(
            "INSERT INTO Produit (pid, prix, rabais, nom) VALUES (%s, %s, %s, %s)",
            (i, prix, rabais, nom)
        )

        # Insert Meuble
        cursor.execute(
            "INSERT INTO Meuble (pid, materiau, dimension, couleur, poids) VALUES (%s, %s, %s, %s, %s)",
            (i, materiau, dimensionCM, couleur, poids)
        )


    except mysql.connector.Error as err:
        print(f"Erreur à l'insertion {i}: {err}")

conn.commit()
cursor.close()
conn.close()

#######################################SECTION LIVRES##########################################
genres_list = ["Roman", "Science-fiction", "Fantaisie", "Histoire", "Informatique"]
auteurs_list = ["Jean Tremblay", "Marie Gagnon", "Luc Roy", "Sophie Martin", "Paul Lavoie"]
dates_list = ["2015", "2018", "2020", "2022", "2023"]
langues_list = ["Français", "Anglais", "Espagnol"]
types_livres = ["Le meilleur livre", "Guide du chasseur", "Story of My Life", "Comment faire la meilleure BD", "Le cuisinier"]

for i in range(201, 301):
    prix = round(random.uniform(10, 100), 2)
    rabais = round(random.uniform(0, 0.5), 2)

    genre = random.choice(genres_list)
    auteur = random.choice(auteurs_list)
    dateParution = random.choice(dates_list)
    langue = random.choice(langues_list)
    nom = f"{random.choice(types_livres)} {i}"

    try:
        # Insert Produit
        cursor.execute(
            "INSERT INTO Produit (pid, prix, rabais, nom) VALUES (%s, %s, %s, %s)",
            (i, prix, rabais, nom)
        )

        # Insert Livre
        cursor.execute(
            "INSERT INTO Livre (pid, genre, auteur, dateParution, langue) VALUES (%s, %s, %s, %s, %s)",
            (i, genre, auteur, dateParution, langue)
        )

    except mysql.connector.Error as err:
        print(f"Erreur à l'insertion {i}: {err}")

conn.commit()
cursor.close()
conn.close()