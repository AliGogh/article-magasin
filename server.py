from functools import wraps
from decimal import Decimal, InvalidOperation

from flask import Flask, render_template, jsonify, request, redirect, url_for, session, flash
from werkzeug.security import generate_password_hash, check_password_hash
from database import Database

app = Flask(__name__)
app.secret_key = "cle_secrete_projet"
db = Database()


def login_required(route):
    """Bloque les pages qui doivent connaitre l'utilisateur connecté.

    Le panier et les commandes appartiennent toujours à un utilisateur.
    Sans cette vérification, une personne non connectée pourrait forcer un
    identifiant de panier dans l'URL ou dans une requête POST et consulter /
    modifier le panier d'un autre utilisateur.
    """
    @wraps(route)
    def wrapper(*args, **kwargs):
        if "uid" not in session:
            # Les appels JavaScript préfèrent une réponse JSON avec un code
            # HTTP clair, tandis que les formulaires HTML doivent rediriger
            # vers la page de connexion avec un message visible.
            if request.is_json:
                return jsonify({"message": "Vous devez vous connecter."}), 401

            flash("Connectez-vous pour continuer.")
            return redirect(url_for("connexion"))

        return route(*args, **kwargs)

    return wrapper


def get_or_create_panier_id(uid):
    """Retourne le panier de l'utilisateur, ou en crée un s'il n'existe pas.

    La table Panier du projet n'utilise pas AUTO_INCREMENT pour panierId. Pour
    garder le schéma actuel intact, on choisit donc le prochain identifiant
    disponible avec MAX(panierId) + 1 au moment de la création.
    """
    db.execute("SELECT panierId FROM Panier WHERE uid = %s", (uid,))
    panier = db.fetchone()

    if panier:
        return panier["panierId"]

    db.execute("SELECT COALESCE(MAX(panierId), 0) + 1 AS prochain_id FROM Panier")
    prochain_panier = db.fetchone()
    panier_id = prochain_panier["prochain_id"]

    db.execute(
        "INSERT INTO Panier (panierId, uid) VALUES (%s, %s)",
        (panier_id, uid)
    )
    return panier_id


def get_utilisateur_connecte():
    """Recharge l'utilisateur connecté depuis la base de données.

    Le solde peut changer pendant la session, par exemple après un dépôt ou une
    commande. On évite donc de le stocker uniquement dans la session Flask.
    """
    db.execute(
        "SELECT uid, courriel, soldeCompte FROM Utilisateur WHERE uid = %s",
        (session["uid"],)
    )
    return db.fetchone()


def convertir_montant(montant_formulaire):
    """Convertit un montant reçu par formulaire en Decimal positif.

    Decimal est préférable à float pour l'argent parce qu'il évite les erreurs
    d'arrondi binaires, par exemple 0.1 + 0.2 qui ne tombe pas exactement sur
    0.3 avec des nombres flottants.
    """
    try:
        montant = Decimal(montant_formulaire).quantize(Decimal("0.01"))
    except (InvalidOperation, TypeError):
        return None

    if montant <= 0:
        return None

    return montant


def calculer_total_panier(panier):
    """Additionne les sous-totaux du panier avec une précision monétaire."""
    return sum(
        (Decimal(str(item["sous_total"])) for item in panier),
        Decimal("0.00")
    )


def fetch_panier_items(panier_id):
    """Charge les lignes du panier avec leur prix rabais inclus.

    Le prix final est calculé ici pour que l'affichage du panier et la création
    de commande utilisent exactement la même logique de prix.
    """
    query = """
        SELECT
            p.pid,
            p.nom,
            p.prix,
            COALESCE(p.rabais, 0) AS rabais,
            lp.quantite,
            ROUND(p.prix * (1 - COALESCE(p.rabais, 0)), 2) AS prix_final,
            ROUND(lp.quantite * p.prix * (1 - COALESCE(p.rabais, 0)), 2) AS sous_total
        FROM LignePanier lp
        JOIN Produit p ON lp.pid = p.pid
        WHERE lp.panierId = %s
        ORDER BY p.nom
    """
    db.execute(query, (panier_id,))
    return db.fetchall()


# -------------------------
# ROUTE 1 : Voir produits
# -------------------------
@app.route("/produits", methods=["GET"])
def get_produits():
    # Les produits sont spécialisés dans trois tables différentes. Les LEFT
    # JOIN permettent d'afficher tous les produits, peu importe leur type, tout
    # en récupérant les colonnes supplémentaires disponibles pour les vêtements,
    # les meubles et les livres.
    query = """
        SELECT
            p.pid,
            p.prix,
            COALESCE(p.rabais, 0) AS rabais,
            p.nom,
            ROUND(p.prix * (1 - COALESCE(p.rabais, 0)), 2) AS prix_final,
            CASE
                WHEN v.pid IS NOT NULL THEN 'Vêtement'
                WHEN m.pid IS NOT NULL THEN 'Meuble'
                WHEN l.pid IS NOT NULL THEN 'Livre'
                ELSE 'Produit'
            END AS type_produit,
            v.taille,
            v.sexe,
            v.couleur AS couleur_vetement,
            v.Marque AS marque,
            m.materiau,
            m.dimension,
            m.couleur AS couleur_meuble,
            m.poids,
            l.genre,
            l.auteur,
            l.dateParution,
            l.langue
        FROM Produit p
        LEFT JOIN Vetement v ON p.pid = v.pid
        LEFT JOIN Meuble m ON p.pid = m.pid
        LEFT JOIN Livre l ON p.pid = l.pid
        ORDER BY p.nom, p.pid
    """
    db.execute(query)
    produits = db.fetchall()
    return render_template("produits.html", produits=produits)


# -------------------------
# ROUTE 2 : Voir panier
# -------------------------
@app.route("/panier", methods=["GET"])
@login_required
def get_panier():
    panier_id = get_or_create_panier_id(session["uid"])
    panier = fetch_panier_items(panier_id)
    total = calculer_total_panier(panier)
    utilisateur = get_utilisateur_connecte()

    return render_template(
        "panier.html",
        panier=panier,
        panier_id=panier_id,
        total=total,
        solde=utilisateur["soldeCompte"]
    )


@app.route("/panier/<int:panier_id>", methods=["GET"])
@login_required
def get_panier_par_id(panier_id):
    # Cette ancienne route reste disponible pour ne pas casser les liens déjà
    # existants, mais elle vérifie maintenant que le panier appartient bien à
    # l'utilisateur connecté avant d'afficher son contenu.
    db.execute(
        "SELECT panierId FROM Panier WHERE panierId = %s AND uid = %s",
        (panier_id, session["uid"])
    )
    panier = db.fetchone()

    if not panier:
        flash("Ce panier n'est pas associé à votre compte.")
        return redirect(url_for("get_panier"))

    items = fetch_panier_items(panier_id)
    total = calculer_total_panier(items)
    utilisateur = get_utilisateur_connecte()

    return render_template(
        "panier.html",
        panier=items,
        panier_id=panier_id,
        total=total,
        solde=utilisateur["soldeCompte"]
    )


# -------------------------
# ROUTE 3 : Ajouter au panier
# -------------------------
@app.route("/panier/ajouter", methods=["POST"])
@login_required
def ajouter_panier():
    # La route accepte les formulaires HTML et le JSON. Le formulaire est le
    # chemin principal dans les templates, mais garder JSON permet de réutiliser
    # la route avec du JavaScript si l'interface évolue.
    data = request.get_json(silent=True) or request.form
    pid = data.get("pid")

    try:
        quantite = int(data.get("quantite", 1))
    except (TypeError, ValueError):
        quantite = 1

    if not pid:
        flash("Produit introuvable.")
        return redirect(url_for("get_produits"))

    if quantite < 1:
        flash("La quantité doit être positive.")
        return redirect(url_for("get_produits"))

    panier_id = get_or_create_panier_id(session["uid"])

    # Si le produit est déjà dans le panier, on augmente simplement la quantité.
    # Cela évite une erreur sur la clé primaire composée (panierId, pid).
    query = """
        INSERT INTO LignePanier (panierId, pid, quantite)
        VALUES (%s, %s, %s)
        ON DUPLICATE KEY UPDATE quantite = quantite + VALUES(quantite)
    """
    db.execute(query, (panier_id, pid, quantite))

    if request.is_json:
        return jsonify({"message": "Produit ajouté au panier"})

    flash("Produit ajouté au panier.")
    return redirect(url_for("get_panier"))


@app.route("/panier/vider", methods=["POST"])
@login_required
def vider_panier():
    panier_id = get_or_create_panier_id(session["uid"])
    db.execute("DELETE FROM LignePanier WHERE panierId = %s", (panier_id,))
    flash("Votre panier a été vidé.")
    return redirect(url_for("get_panier"))


# -------------------------
# ROUTE 4 : Passer une commande
# -------------------------
@app.route("/payer", methods=["POST"])
@login_required
def payer():
    panier_id = get_or_create_panier_id(session["uid"])
    panier = fetch_panier_items(panier_id)

    if not panier:
        flash("Votre panier est vide.")
        return redirect(url_for("get_panier"))

    total = calculer_total_panier(panier)

    try:
        # On regroupe la création de commande, la copie des lignes et le vidage
        # du panier dans une transaction. Si une étape échoue, la commande ne se
        # retrouve pas à moitié créée.
        db.connection.begin()

        # On verrouille la ligne de l'utilisateur pendant la commande. Ainsi, si
        # deux paiements arrivent presque en même temps, le deuxième attend que
        # le premier ait terminé avant de vérifier le solde restant.
        db.execute(
            """
            SELECT soldeCompte
            FROM Utilisateur
            WHERE uid = %s
            FOR UPDATE
            """,
            (session["uid"],)
        )
        utilisateur = db.fetchone()

        if not utilisateur or Decimal(str(utilisateur["soldeCompte"])) < total:
            db.connection.rollback()
            flash("Solde insuffisant pour passer cette commande.")
            return redirect(url_for("get_panier"))

        # La commande est d'abord créée avec total = 0 pour rester compatible
        # avec les déclencheurs SQL du projet qui valident / mettent à jour le
        # total autour des lignes de commande.
        db.execute(
            """
            INSERT INTO Commande (uid, total, dateCommande, statut)
            VALUES (%s, %s, NOW(), %s)
            """,
            (session["uid"], 0, "en cours")
        )

        db.execute("SELECT LAST_INSERT_ID() AS cid")
        commande = db.fetchone()
        commande_id = commande["cid"]

        # Chaque ligne garde le prix final au moment de la commande. Ainsi, une
        # modification future du prix ou du rabais dans Produit ne change pas
        # l'historique des commandes déjà passées.
        db.execute(
            """
            INSERT INTO LigneDeCommande (cid, pid, prixAuMoment, quantite)
            SELECT
                %s,
                lp.pid,
                ROUND(p.prix * (1 - COALESCE(p.rabais, 0)), 2),
                lp.quantite
            FROM LignePanier lp
            JOIN Produit p ON lp.pid = p.pid
            WHERE lp.panierId = %s
            """,
            (commande_id, panier_id)
        )

        db.execute(
            """
            UPDATE Commande
            SET total = %s, statut = %s
            WHERE cid = %s
            """,
            (total, "confirmée", commande_id)
        )

        # Les déclencheurs SQL existants retirent seulement le total initial de
        # la commande, qui est 0 ici. On débite donc explicitement le solde après
        # avoir calculé le vrai total et avant de vider le panier.
        db.execute(
            """
            UPDATE Utilisateur
            SET soldeCompte = soldeCompte - %s
            WHERE uid = %s
            """,
            (total, session["uid"])
        )

        db.execute("DELETE FROM LignePanier WHERE panierId = %s", (panier_id,))
        db.connection.commit()
    except Exception:
        db.connection.rollback()
        raise

    flash(f"Commande #{commande_id} créée avec succès.")
    return redirect(url_for("get_panier"))


@app.route("/payer/<int:panier_id>", methods=["POST"])
@login_required
def payer_ancien_lien(panier_id):
    # Compatibilité avec l'ancienne URL /payer/<panier_id>. La nouvelle logique
    # ne fait pas confiance à l'identifiant reçu et utilise le panier de session.
    return payer()


@app.route("/profil", methods=["GET"])
@login_required
def profil():
    utilisateur = get_utilisateur_connecte()
    return render_template("profil.html", utilisateur=utilisateur)


@app.route("/profil/ajouter-solde", methods=["POST"])
@login_required
def ajouter_solde():
    montant = convertir_montant(request.form.get("montant"))

    if montant is None:
        flash("Entrez un montant positif avec au plus deux décimales.")
        return redirect(url_for("profil"))

    # Le dépôt est volontairement simple pour le projet: on ajoute le montant
    # directement au solde du compte connecté, puis on réaffiche le profil.
    db.execute(
        """
        UPDATE Utilisateur
        SET soldeCompte = soldeCompte + %s
        WHERE uid = %s
        """,
        (montant, session["uid"])
    )

    flash(f"{montant:.2f} $ ont été ajoutés à votre solde.")
    return redirect(url_for("profil"))


@app.route("/")
def index():
    return render_template("index.html")

# -------------------------
# INSCRIPTION
# -------------------------
@app.route("/inscription", methods=["GET", "POST"])
def inscription():
    if request.method == "POST":
        courriel = request.form["courriel"].strip()
        mot_de_passe = request.form["mot_de_passe"].strip()

        if not courriel or not mot_de_passe:
            flash("Tous les champs sont obligatoires.")
            return render_template("inscription.html")

        # Vérifier si le courriel existe déjà
        query = "SELECT * FROM Utilisateur WHERE courriel = %s"
        db.execute(query, (courriel,))
        utilisateur_existant = db.fetchone()

        if utilisateur_existant:
            flash("Ce courriel est déjà utilisé.")
            return render_template("inscription.html")

        mot_de_passe_hash = generate_password_hash(mot_de_passe)

        query = """
            INSERT INTO Utilisateur (courriel, motDePasse, soldeCompte)
            VALUES (%s, %s, %s)
        """
        db.execute(query, (courriel, mot_de_passe_hash, 0))

        flash("Inscription réussie. Vous pouvez maintenant vous connecter.")
        return redirect(url_for("connexion"))

    return render_template("inscription.html")


# -------------------------
# CONNEXION
# -------------------------
@app.route("/connexion", methods=["GET", "POST"])
def connexion():
    if request.method == "POST":
        courriel = request.form["courriel"].strip()
        mot_de_passe = request.form["mot_de_passe"].strip()

        query = "SELECT * FROM Utilisateur WHERE courriel = %s"
        db.execute(query, (courriel,))
        utilisateur = db.fetchone()

        if utilisateur and check_password_hash(utilisateur["motDePasse"], mot_de_passe):
            session["uid"] = utilisateur["uid"]
            session["courriel"] = utilisateur["courriel"]

            flash("Connexion réussie.")
            return redirect(url_for("index"))

        flash("Courriel ou mot de passe invalide.")
        return render_template("connexion.html")

    return render_template("connexion.html")


# -------------------------
# DECONNEXION
# -------------------------
@app.route("/deconnexion")
def deconnexion():
    session.clear()
    flash("Vous êtes déconnecté.")
    return redirect(url_for("index"))


# -------------------------
# Lancer serveur
# -------------------------
if __name__ == "__main__":
    app.run(debug=True)
