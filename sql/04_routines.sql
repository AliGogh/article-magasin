USE article_magasin;

DELIMITER $$

# Procédure utilitaire pour ajouter un produit dans un panier.
# Si le produit est déjà présent, la quantité existante est augmentée au lieu de
# créer une deuxième ligne, ce qui respecte la clé primaire (panierId, pid).
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

# Procédure principale de commande.
# Elle transforme le contenu d'un panier en commande, vérifie le solde du compte,
# copie les lignes au prix courant après rabais, débite le compte, puis vide le
# panier seulement si tout s'est bien déroulé.
CREATE PROCEDURE creer_commande(IN p_panierId INT)
BEGIN
    # Variables locales utilisées pour mémoriser l'utilisateur du panier, la
    # commande créée, le total calculé et le solde disponible.
    DECLARE v_uid INT;
    DECLARE v_cid INT;
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_solde DECIMAL(10,2);

    -- 1. Trouver l'utilisateur propriétaire du panier.
    SELECT uid INTO v_uid
    FROM Panier
    WHERE panierId = p_panierId;

    -- 2. Calculer le total avant de créer la commande afin de vérifier le solde.
    -- Le prix utilisé est le prix après rabais au moment de l'achat.
    SELECT COALESCE(SUM(lp.quantite * ROUND(p.prix * (1 - COALESCE(p.rabais, 0)), 2)), 0)
    INTO v_total
    FROM LignePanier lp
    JOIN Produit p ON lp.pid = p.pid
    WHERE lp.panierId = p_panierId;

    -- 3. Charger le solde de l'utilisateur pour refuser les commandes trop chères.
    SELECT soldeCompte INTO v_solde
    FROM Utilisateur
    WHERE uid = v_uid;

    IF v_total > v_solde THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Solde insuffisant';
    END IF;

    -- 4. Créer la commande.
    -- Le total commence à 0 parce que le trigger maj_total_commande l'augmente
    -- automatiquement quand les lignes de commande sont insérées.
    INSERT INTO Commande (uid, total, dateCommande, statut)
    VALUES (v_uid, 0, NOW(), 'en cours');

    -- 5. Récupérer l'id de la commande créée.
    SET v_cid = LAST_INSERT_ID();

    -- 6. Copier les produits du panier vers la commande.
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

    -- 7. Débiter le solde maintenant que la commande est créée.
    UPDATE Utilisateur
    SET soldeCompte = soldeCompte - v_total
    WHERE uid = v_uid;

    -- 8. Vider le panier après la création de commande réussie.
    DELETE FROM LignePanier
    WHERE panierId = p_panierId;

END $$

DELIMITER ;

# Empêche une quantité nulle ou négative dans une nouvelle ligne de panier.
# Le CHECK de la table fait déjà une validation semblable, mais ce trigger donne
# un message d'erreur explicite.
CREATE TRIGGER verifier_quantite_panier
BEFORE INSERT ON LignePanier
FOR EACH ROW
BEGIN
    IF NEW.quantite <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La quantité doit être positive';
    END IF;
END;

# Met à jour automatiquement le total de commande après l'ajout d'une ligne.
# Cela permet à la commande de commencer à total = 0, puis d'accumuler les
# sous-totaux ligne par ligne.
CREATE TRIGGER maj_total_commande
AFTER INSERT ON LigneDeCommande
FOR EACH ROW
BEGIN
    UPDATE Commande
    SET total = total + (NEW.prixAuMoment * NEW.quantite)
    WHERE cid = NEW.cid;
END;

# Vérifie qu'un utilisateur a assez d'argent avant la création d'une commande.
# Dans le flux Flask actuel, la commande est d'abord créée à total = 0 puis le
# vrai total est écrit après les lignes; la route Flask fait donc aussi une
# vérification explicite du solde avant l'insertion.
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

# Débite automatiquement le solde lorsqu'une commande est insérée.
# Comme le flux Flask insère d'abord total = 0, il débite ensuite explicitement
# le vrai total dans server.py.
CREATE TRIGGER maj_solde_utilisateur
AFTER INSERT ON Commande
FOR EACH ROW
BEGIN
    UPDATE Utilisateur
    SET soldeCompte = soldeCompte - NEW.total
    WHERE uid = NEW.uid;
END;
