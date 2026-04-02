-- Utiliser la base de données
USE article_magasin;

-- ============================================
-- 1. INSERTION DES UTILISATEURS
-- ============================================

INSERT INTO utilisateurs (courriel, mot_passe, nom, avatar, est_admin) VALUES
('admin@magasin.com', 'password123', 'Admin Principal', 'admin.jpg', TRUE),
('alice@email.com', 'password123', 'Alice Martin', 'alice.jpg', FALSE),
('bob@email.com', 'password123', 'Bob Tremblay', 'bob.jpg', FALSE),
('claire@email.com', 'password123', 'Claire Dubois', 'claire.jpg', FALSE),
('david@email.com', 'password123', 'David Gagnon', 'david.jpg', FALSE);

-- ============================================
-- 2. INSERTION DES PRODUITS (30 premiers)
-- ============================================

INSERT INTO produits (nom, prix, quantite_stock, description, image_url) VALUES
('Cahier A4 200 pages', 2.50, 150, 'Cahier à spirales, papier ligné 90g', 'cahier.jpg'),
('Stylo à bille bleu', 1.20, 300, 'Stylo à bille, encre bleue, tracé 0.7mm', 'stylo_bleu.jpg'),
('Stylo à bille rouge', 1.20, 200, 'Stylo à bille, encre rouge, tracé 0.7mm', 'stylo_rouge.jpg'),
('Surligneur jaune', 2.00, 100, 'Surligneur fluorescent jaune', 'surligneur.jpg'),
('Trousse à crayons', 5.99, 75, 'Trousse en toile, fermeture éclair', 'trousse.jpg'),
('Classeur 3 anneaux', 4.50, 60, 'Classeur format lettre, capacité 200 pages', 'classeur.jpg'),
('Calculatrice scientifique', 19.99, 30, 'Calculatrice avec 240 fonctions', 'calculatrice.jpg'),
('Règle 30cm', 1.50, 120, 'Règle transparente graduée', 'regle.jpg'),
('Gomme à effacer', 0.80, 250, 'Gomme blanche sans poussière', 'gomme.jpg'),
('Taille-crayon', 1.99, 150, 'Taille-crayon double trou', 'taillecrayon.jpg'),
('Marqueur permanent noir', 2.50, 90, 'Marqueur indélébile pointe fine', 'marqueur.jpg'),
('Post-it 76x76mm', 3.99, 85, 'Bloc de notes adhésives jaunes', 'postit.jpg'),
('Agenda 2025', 12.99, 40, 'Agenda hebdomadaire, couverture rigide', 'agenda.jpg'),
('Crayon à mine HB', 0.50, 500, 'Crayon bois, mine HB, lot de 12', 'crayon_hb.jpg'),
('Correcteur liquide', 2.99, 70, 'Correcteur à bille 10ml', 'correcteur.jpg'),
('Dossier suspendu', 8.99, 45, 'Dossier suspendu avec onglets', 'dossier.jpg'),
('Pochette à rabats', 3.50, 100, 'Pochette cartonnée avec élastique', 'pochette.jpg'),
('Ciseaux scolaires', 4.99, 55, 'Ciseaux pointe arrondie 15cm', 'ciseaux.jpg'),
('Colle en bâton', 1.75, 130, 'Colle blanche en bâton 21g', 'colle.jpg'),
('Ruban adhésif transparent', 2.99, 80, 'Ruban adhésif 18mm x 33m', 'ruban.jpg'),
('Feuilles mobiles A4', 3.99, 120, 'Paquet de 100 feuilles lignées', 'feuilles.jpg'),
('Cahier de notes A5', 3.50, 90, 'Cahier à couverture cartonnée', 'cahier_a5.jpg'),
('Porte-documents', 6.99, 40, 'Porte-documents en plastique rigide', 'porte_doc.jpg'),
('Équerre triangle', 2.50, 70, 'Équerre transparente 20cm', 'equerre.jpg'),
('Rapporteur d\'angle', 2.50, 60, 'Rapporteur 180 degrés', 'rapporteur.jpg'),
('Compass', 4.50, 50, 'Compass métallique avec mine', 'compas.jpg'),
('Lot de 10 pochettes plastique', 2.99, 100, 'Pochettes transparentes perforées', 'pochette_plastique.jpg'),
('Crayons de couleur 12 couleurs', 7.99, 45, 'Lot de 12 crayons de couleur', 'crayons_couleur.jpg'),
('Feutres lavables 10 couleurs', 6.99, 40, 'Lot de 10 feutres lavables', 'feutres.jpg'),
('Papier cartonné A4', 5.99, 60, 'Paquet de 20 feuilles cartonnées', 'papier_cartonne.jpg');

-- ============================================
-- 3. INSERTION DES 70 PRODUITS SUPPLÉMENTAIRES
-- ============================================

INSERT INTO produits (nom, prix, quantite_stock, description, image_url) SELECT
CONCAT('Produit ', seq, ' - Article Magasin'),
ROUND(RAND() * 50 + 1, 2),
FLOOR(RAND() * 200 + 10),
CONCAT('Description du produit ', seq, '. Article de qualité pour votre magasin.'),
CONCAT('produit', seq, '.jpg')
FROM
(SELECT @row := @row + 1 AS seq FROM
(SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
(SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
(SELECT @row := 0) r
LIMIT 70) seq_gen;

-- ============================================
-- 4. INSERTION DES COMMANDES
-- ============================================

INSERT INTO commandes (utilisateur_courriel, date_commande, statut, total) VALUES
('alice@email.com', '2025-03-01 10:30:00', 'livree', 0),
('alice@email.com', '2025-03-15 14:20:00', 'en_attente', 0),
('bob@email.com', '2025-03-05 09:15:00', 'expediee', 0),
('bob@email.com', '2025-03-20 16:45:00', 'en_attente', 0),
('claire@email.com', '2025-03-10 11:00:00', 'livree', 0),
('david@email.com', '2025-03-12 13:30:00', 'annulee', 0),
('alice@email.com', '2025-03-25 10:00:00', 'en_attente', 0),
('claire@email.com', '2025-03-28 15:30:00', 'en_attente', 0);

-- ============================================
-- 5. INSERTION DES DÉTAILS DES COMMANDES
-- ============================================

INSERT INTO details_commandes (commande_id, produit_id, quantite, prix_unitaire) VALUES
(1, 1, 2, 2.50),
(1, 2, 3, 1.20),
(2, 5, 1, 5.99),
(2, 7, 1, 19.99),
(3, 3, 2, 1.20),
(3, 4, 1, 2.00),
(4, 10, 3, 1.99),
(4, 11, 1, 2.50),
(5, 13, 1, 12.99),
(5, 14, 5, 0.50),
(6, 6, 1, 4.50),
(7, 8, 2, 1.50),
(7, 9, 3, 0.80),
(8, 12, 2, 3.99),
(8, 15, 1, 2.99);

-- ============================================
-- 6. INSERTION DES AVIS
-- ============================================

INSERT INTO avis (produit_id, utilisateur_courriel, note, commentaire) VALUES
(1, 'alice@email.com', 5, 'Excellent cahier, papier de qualité'),
(1, 'bob@email.com', 4, 'Très bon, mais un peu cher'),
(2, 'claire@email.com', 5, 'Stylo fluide, très agréable'),
(3, 'david@email.com', 3, 'Rouge pas assez vif'),
(4, 'alice@email.com', 4, 'Bien, mais tache un peu'),
(5, 'bob@email.com', 5, 'Parfaite pour l\'école'),
(7, 'claire@email.com', 5, 'Calculatrice géniale'),
(13, 'david@email.com', 4, 'Agenda bien organisé');

-- ============================================
-- 7. MISE À JOUR DES TOTAUX DES COMMANDES
-- ============================================

UPDATE commandes SET total = (
    SELECT SUM(quantite * prix_unitaire)
    FROM details_commandes
    WHERE details_commandes.commande_id = commandes.id
);