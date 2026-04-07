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

CREATE TABLE Meuble (
    pid INT PRIMARY KEY,
    materiau varchar(20),
    dimension varchar(20),
    couleur VARCHAR(20),
    poids int,
    FOREIGN KEY (pid) REFERENCES Produit(pid)
);

CREATE TABLE Livre (
    pid INT PRIMARY KEY,
    genre varchar(20),
    auteur varchar(20),
    dateParution varchar(25),
    langue varchar(20),
    FOREIGN KEY (pid) REFERENCES Produit(pid)
);













CREATE TABLE Commande (
    cid int AUTO_INCREMENT PRIMARY KEY,
    uid INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    dateCommande DATETIME NOT NULL,
    statut varchar(20),
    FOREIGN KEY (uid) REFERENCES Utilisateurs(uid)
);

CREATE TABLE LigneDeCommande (
    cid INT NOT NULL,
    pid INT NOT NULL,
    prixAuMoment DECIMAL(10,2) NOT NULL,
    quantite int NOT NULL,
    FOREIGN KEY (cid) REFERENCES Commande (cid),
    FOREIGN KEY (pid) REFERENCES Produit (pid)
);