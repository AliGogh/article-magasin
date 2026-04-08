USE article_magasin;
#Produit avec le plus gros rabais
SELECT * from Produit p where p.rabais = (SELECT MAX(rabais) from Produit);