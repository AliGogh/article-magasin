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