# Création de la base de données principale du projet.
CREATE DATABASE IF NOT EXISTS article_magasin;
USE article_magasin;

# Table mère de tous les articles vendus dans le magasin.
# Les tables Vetement, Meuble et Livre ajoutent ensuite les attributs propres à
# chaque catégorie de produit.
CREATE TABLE Produit (
    pid INT PRIMARY KEY,        # Identifiant unique du produit.
    prix FLOAT,                 # Prix régulier avant rabais.
    rabais FLOAT,               # Rabais stocké sous forme décimale: 0.25 = 25%.
    nom VARCHAR(50)             # Nom court affiché dans la boutique.
);

# Spécialisation de Produit pour les vêtements.
# pid est à la fois la clé primaire de Vetement et une clé étrangère vers Produit:
# cela force un vêtement à exister d'abord comme produit général.
CREATE TABLE Vetement (
    pid INT PRIMARY KEY,
    taille VARCHAR(10),
    sexe VARCHAR(10),
    couleur VARCHAR(20),
    FOREIGN KEY (pid) REFERENCES Produit(pid)
);

# Attribut ajouté séparément pour montrer une évolution du schéma.
ALTER TABLE Vetement
ADD COLUMN Marque VARCHAR(50);

# Spécialisation de Produit pour les meubles.
# Les meubles gardent des caractéristiques physiques comme le matériau, les
# dimensions, la couleur et le poids.
CREATE TABLE Meuble (
    pid INT PRIMARY KEY,
    materiau VARCHAR(20),
    dimension VARCHAR(20),
    couleur VARCHAR(20),
    poids INT,
    FOREIGN KEY (pid) REFERENCES Produit(pid)
);

# Spécialisation de Produit pour les livres.
# Les livres ont des attributs bibliographiques plutôt que physiques.
CREATE TABLE Livre (
    pid INT PRIMARY KEY,
    genre VARCHAR(20),
    auteur VARCHAR(20),
    dateParution VARCHAR(25),
    langue VARCHAR(20),
    FOREIGN KEY (pid) REFERENCES Produit(pid)
);

# Compte client. Le courriel sert d'identifiant de connexion unique.
# soldeCompte représente l'argent disponible pour payer les commandes.
CREATE TABLE Utilisateur (
    uid INT AUTO_INCREMENT PRIMARY KEY,
    courriel VARCHAR(100) NOT NULL UNIQUE,
    soldeCompte DECIMAL(10,2) DEFAULT 0 CHECK (soldeCompte >= 0),
    motDePasse VARCHAR(255) NOT NULL
);

# Panier actif d'un utilisateur.
# UNIQUE(uid) impose un seul panier par utilisateur dans ce modèle.
CREATE TABLE Panier (
    panierId INT PRIMARY KEY,
    uid INT NOT NULL,
    UNIQUE(uid),
    FOREIGN KEY (uid) REFERENCES Utilisateur(uid) ON DELETE CASCADE
);

# Produits contenus dans un panier.
# La clé primaire composée empêche deux lignes séparées pour le même produit dans
# le même panier; l'application augmente plutôt la quantité.
CREATE TABLE LignePanier (
    panierId INT,
    pid INT,
    quantite INT NOT NULL DEFAULT 1 CHECK(quantite > 0),
    PRIMARY KEY (panierId, pid),
    FOREIGN KEY (panierId) REFERENCES Panier(panierId) ON DELETE CASCADE,
    FOREIGN KEY (pid) REFERENCES Produit(pid) ON DELETE CASCADE
);

# Commande passée par un utilisateur.
# total est stocké pour conserver l'historique du montant payé au moment exact
# de la commande.
CREATE TABLE Commande (
    cid INT AUTO_INCREMENT PRIMARY KEY,
    uid INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    dateCommande DATETIME NOT NULL,
    statut VARCHAR(20),
    FOREIGN KEY (uid) REFERENCES Utilisateur(uid)
);

# Détail des produits achetés dans une commande.
# prixAuMoment évite que l'historique change si le prix du produit est modifié
# plus tard dans la table Produit.
CREATE TABLE LigneDeCommande (
    cid INT NOT NULL,
    pid INT NOT NULL,
    prixAuMoment DECIMAL(10,2) NOT NULL,
    quantite INT NOT NULL,
    FOREIGN KEY (cid) REFERENCES Commande(cid),
    FOREIGN KEY (pid) REFERENCES Produit(pid)
);

# Index ajoutés sur les colonnes utilisées fréquemment dans les jointures et
# filtres. Ils accélèrent notamment les paniers, commandes et statistiques.
CREATE INDEX idx_commande_uid ON Commande(uid);
CREATE INDEX idx_panier_uid ON Panier(uid);
CREATE INDEX idx_lignedecommande_pid ON LigneDeCommande(pid);
CREATE INDEX idx_lignedupanier_pid ON LignePanier(pid);
