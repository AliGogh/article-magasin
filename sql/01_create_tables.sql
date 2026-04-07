#Création de la base de données
CREATE DATABASE IF NOT EXISTS article_magasin;
USE article_magasin;
#
CREATE TABLE Produit
    (
     pid int PRIMARY KEY,
     prix float,
     rabais float,
     nom varchar(50)


    );
#Spécialisation de produit
CREATE TABLE Vetement (
    pid INT PRIMARY KEY,
    taille VARCHAR(10),
    sexe VARCHAR(10),
    couleur VARCHAR(20),
    FOREIGN KEY (pid) REFERENCES Produit(pid)
);
#Ajout d'un nouvel attribut
ALTER TABLE Vetement
ADD COLUMN Marque varchar(50);

#Spécialisation de produit
CREATE TABLE Meuble (
    pid INT PRIMARY KEY,
    materiau varchar(20),
    dimension varchar(20),
    couleur VARCHAR(20),
    poids int,
    FOREIGN KEY (pid) REFERENCES Produit(pid)
);
#Spécialisation de produit
CREATE TABLE Livre (
    pid INT PRIMARY KEY,
    genre varchar(20),
    auteur varchar(20),
    dateParution varchar(25),
    langue varchar(20),
    FOREIGN KEY (pid) REFERENCES Produit(pid)
);

CREATE TABLE Utilisateur (
    uid INT AUTO_INCREMENT PRIMARY KEY,
    courriel VARCHAR(100) NOT NULL UNIQUE,
    soldeCompte DECIMAL(10,2) DEFAULT 0 CHECK (soldeCompte >= 0),
    motDePasse VARCHAR(255) NOT NULL
);

CREATE TABLE Panier (
    panierId INT PRIMARY KEY,
    uid INT NOT NULL,
    UNIQUE(uid),
    FOREIGN KEY (uid) REFERENCES Utilisateur(uid) ON DELETE CASCADE
);

CREATE TABLE LignePanier(
    panierId int,
    pid int,
    quantite int NOT NULL default 1 CHECK(quantite > 0),
    PRIMARY KEY (panierId, pid),
    FOREIGN KEY (panierId) REFERENCES Panier(panierId) ON DELETE CASCADE ,
    FOREIGN KEY (pid) REFERENCES Produit(pid) ON DELETE CASCADE
);