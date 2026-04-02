-- Utiliser la base de données
USE article_magasin;

-- 1. Vérifier le nombre de produits (doit être >= 100)
SELECT COUNT(*) AS nb_produits FROM produits;

-- 2. Voir tous les utilisateurs
SELECT courriel, nom, est_admin FROM utilisateurs;

-- 3. Voir les commandes avec les noms des utilisateurs
SELECT c.id, u.nom, c.date_commande, c.total, c.statut
FROM commandes c
JOIN utilisateurs u ON c.utilisateur_courriel = u.courriel
ORDER BY c.date_commande DESC;

-- 4. Voir le détail d'une commande (exemple commande #1)
SELECT p.nom, dc.quantite, dc.prix_unitaire, (dc.quantite * dc.prix_unitaire) AS sous_total
FROM details_commandes dc
JOIN produits p ON dc.produit_id = p.id
WHERE dc.commande_id = 1;

-- 5. Voir les produits les plus vendus
SELECT p.nom, SUM(dc.quantite) AS quantite_vendue
FROM details_commandes dc
JOIN produits p ON dc.produit_id = p.id
GROUP BY p.id, p.nom
ORDER BY quantite_vendue DESC
LIMIT 10;

-- 6. Voir la moyenne des notes par produit
SELECT p.nom, AVG(a.note) AS note_moyenne, COUNT(a.id) AS nb_avis
FROM produits p
LEFT JOIN avis a ON p.id = a.produit_id
GROUP BY p.id, p.nom
HAVING nb_avis > 0;

-- 7. Voir le chiffre d'affaires total par utilisateur
SELECT u.nom, SUM(c.total) AS total_depenses
FROM commandes c
JOIN utilisateurs u ON c.utilisateur_courriel = u.courriel
WHERE c.statut != 'annulee'
GROUP BY u.courriel, u.nom
ORDER BY total_depenses DESC;