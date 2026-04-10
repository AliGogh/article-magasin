USE article_magasin;

DELIMITER $$

CREATE PROCEDURE ajouter_au_panier(
    IN p_panierId INT,
    IN p_pid INT,
    IN p_quantite INT
)
BEGIN
    INSERT INTO LignePanier(panierId, pid, quantite)
    VALUES (p_panierId, p_pid, p_quantite)
    ON DUPLICATE KEY UPDATE quantite = quantite + VALUES(quantite);
END $$

DELIMITER ;




DELIMITER $$

CREATE PROCEDURE creer_commande(IN p_panierId INT)
BEGIN
    DECLARE v_uid INT;
    DECLARE v_cid INT;
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_solde DECIMAL(10,2);

    -- 1. Trouver l'utilisateur du panier
    SELECT uid INTO v_uid
    FROM Panier
    WHERE panierId = p_panierId;

    -- 2. Calculer le total avant de créer la commande afin de vérifier le solde.
    SELECT COALESCE(SUM(lp.quantite * ROUND(p.prix * (1 - COALESCE(p.rabais, 0)), 2)), 0)
    INTO v_total
    FROM LignePanier lp
    JOIN Produit p ON lp.pid = p.pid
    WHERE lp.panierId = p_panierId;

    SELECT soldeCompte INTO v_solde
    FROM Utilisateur
    WHERE uid = v_uid;

    IF v_total > v_solde THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Solde insuffisant';
    END IF;

    -- 3. Créer la commande
    -- Le total commence à 0 parce que le trigger maj_total_commande l'augmente
    -- automatiquement quand les lignes de commande sont insérées.
    INSERT INTO Commande ( uid, total, dateCommande, statut)
    VALUES (v_uid, 0, NOW(), 'en cours');

    -- 4. Récupérer l'id de la commande créée
    SET v_cid = LAST_INSERT_ID();

    -- 5. Copier les produits du panier vers la commande
    -- prixAuMoment conserve le prix après rabais au moment de l'achat.
    INSERT INTO LigneDeCommande (cid, pid, prixAuMoment, quantite)
    SELECT
        v_cid,
        lp.pid,
        ROUND(p.prix * (1 - COALESCE(p.rabais, 0)), 2),
        lp.quantite
    FROM LignePanier lp
    JOIN Produit p ON lp.pid = p.pid
    WHERE lp.panierId = p_panierId;

    -- 6. Débiter le solde maintenant que la commande est créée.
    UPDATE Utilisateur
    SET soldeCompte = soldeCompte - v_total
    WHERE uid = v_uid;

    -- 7. Vider le panier
    DELETE FROM LignePanier
    WHERE panierId = p_panierId;

END $$

DELIMITER ;

#Vérifier que chaque ligne du panier ne contient pas de valeur négative
CREATE TRIGGER verifier_quantite_panier
BEFORE INSERT ON LignePanier
FOR EACH ROW
BEGIN
    IF NEW.quantite <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La quantité doit être positive';
    END IF;
END;

#Vérifier que le total de commande est mis à jour après l'ajout d'une ligne de commande
CREATE TRIGGER maj_total_commande
AFTER INSERT ON LigneDeCommande
FOR EACH ROW
BEGIN
    UPDATE Commande
    SET total = total + (NEW.prixAuMoment * NEW.quantite)
    WHERE cid = NEW.cid;
END;

#Vérifier que le solde du compte est suffisant pour effectuer un achat
CREATE TRIGGER verif_solde_avant_commande
BEFORE INSERT ON Commande
FOR EACH ROW
BEGIN
    DECLARE solde DECIMAL(10,2);

    SELECT soldeCompte INTO solde
    FROM Utilisateur
    WHERE uid = NEW.uid;

    IF solde < NEW.total THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Solde insuffisant';
    END IF;
END;

#Mettre à jour le solde du compte après achat
CREATE TRIGGER maj_solde_utilisateur
AFTER INSERT ON Commande
FOR EACH ROW
BEGIN
    UPDATE Utilisateur
    SET soldeCompte = soldeCompte - NEW.total
    WHERE uid = NEW.uid;
END;
