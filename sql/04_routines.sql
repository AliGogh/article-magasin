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