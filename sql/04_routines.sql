USE article_magasin;

DELIMITER $$

CREATE PROCEDURE ajouter_au_panier(
    IN p_panierId INT,
    IN p_pid INT,
    IN p_quantite INT
)
BEGIN
    INSERT INTO LignePanier(panierId, pid, quantite)
    VALUES (p_panierId, p_pid, p_quantite);
END $$

DELIMITER ;




DELIMITER $$

CREATE PROCEDURE creer_commande(IN p_panierId INT)
BEGIN
    DECLARE v_uid INT;
    DECLARE v_cid INT;

    -- 1. Trouver l'utilisateur du panier
    SELECT uid INTO v_uid
    FROM Panier
    WHERE panierId = p_panierId;

    -- 2. Créer la commande
    INSERT INTO Commande ( uid, total, dateCommande, statut)
    VALUES (v_uid, 0, NOW(), 'en cours');

    -- 3. Récupérer l'id de la commande créée
    SET v_cid = LAST_INSERT_ID();

    -- 4. Copier les produits du panier vers la commande
    INSERT INTO LigneDeCommande (cid, pid, prixAuMoment, quantite)
    SELECT
        v_cid,
        lp.pid,
        lp.quantite,
        p.prix
    FROM LignePanier lp
    JOIN Produit p ON lp.pid = p.pid
    WHERE lp.panierId = p_panierId;

    -- 5. Calculer le total
    UPDATE Commande
    SET total = (
        SELECT SUM(quantite * prixAuMoment)
        FROM LigneDeCommande
        WHERE cid = v_cid
    )
    WHERE cid = v_cid;

    -- 6. Vider le panier
    DELETE FROM LignePanier
    WHERE panierId = p_panierId;

END $$

DELIMITER ;