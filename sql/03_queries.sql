USE article_magasin;
#Produits avec les plus gros rabais
SELECT * from Produit p
ORDER BY rabais DESC;
#Produits les plus vendus
SELECT p.nom, SUM(lc.quantite) AS total_vendu
FROM LigneDeCommande lc
JOIN Produit p ON lc.pid = p.pid
GROUP BY p.pid
ORDER BY total_vendu DESC;
#Produits jamais commandés
SELECT *
FROM Produit
WHERE pid NOT IN (
    SELECT pid FROM LigneDeCommande
);
#Produits souvent commandés ensemble
SELECT
    p1.nom AS produit1,
    p2.nom AS produit2,
    COUNT(*) AS fois_ensemble
FROM LigneDeCommande lc1
JOIN LigneDeCommande lc2
    ON lc1.cid = lc2.cid
    AND lc1.pid < lc2.pid
JOIN Produit p1 ON lc1.pid = p1.pid
JOIN Produit p2 ON lc2.pid = p2.pid
GROUP BY lc1.pid, lc2.pid
ORDER BY fois_ensemble DESC;