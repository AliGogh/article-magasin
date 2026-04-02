-- Création de la base de données
CREATE DATABASE IF NOT EXISTS article_magasin;
USE article_magasin;

-- Table utilisateurs
CREATE TABLE utilisateurs (
    courriel VARCHAR(100) PRIMARY KEY,
    mot_passe VARCHAR(255) NOT NULL,
    nom VARCHAR(100) NOT NULL,
    avatar VARCHAR(255),
    est_admin BOOLEAN DEFAULT FALSE
);

-- Table produits
CREATE TABLE produits (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(200) NOT NULL,
    prix DECIMAL(10,2) NOT NULL,
    quantite_stock INT NOT NULL,
    description TEXT,
    image_url VARCHAR(255)
);

-- Table commandes
CREATE TABLE commandes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_courriel VARCHAR(100),
    date_commande DATETIME DEFAULT CURRENT_TIMESTAMP,
    statut VARCHAR(50) DEFAULT 'en_attente',
    total DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (utilisateur_courriel) REFERENCES utilisateurs(courriel)
);

-- Table details_commandes
CREATE TABLE details_commandes (
    commande_id INT,
    produit_id INT,
    quantite INT NOT NULL,
    prix_unitaire DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (commande_id, produit_id),
    FOREIGN KEY (commande_id) REFERENCES commandes(id),
    FOREIGN KEY (produit_id) REFERENCES produits(id)
);

-- Table avis
CREATE TABLE avis (
    id INT PRIMARY KEY AUTO_INCREMENT,
    produit_id INT,
    utilisateur_courriel VARCHAR(100),
    note INT CHECK (note BETWEEN 1 AND 5),
    commentaire TEXT,
    date_avis DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (produit_id) REFERENCES produits(id),
    FOREIGN KEY (utilisateur_courriel) REFERENCES utilisateurs(courriel)
);