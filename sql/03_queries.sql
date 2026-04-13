USE article_magasin;
#Produits avec les plus gros rabais
SELECT * from Produit p
ORDER BY rabais DESC;
#Produits souvent commandés ensemble (Pas utilisée)
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