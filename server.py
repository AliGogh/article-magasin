from flask import Flask, render_template, jsonify, request, redirect, url_for, session, flash
from werkzeug.security import generate_password_hash, check_password_hash
from database import Database

app = Flask(__name__)
app.secret_key = "cle_secrete_projet"
db = Database()

# -------------------------
# ACCUEIL
# -------------------------
# -------------------------
# ROUTE 1 : Voir produits
# -------------------------
@app.route("/produits", methods=["GET"])
def get_produits():
    db.execute("SELECT * FROM Produit")
    produits = db.fetchall()
    return render_template("produits.html", produits=produits)


# -------------------------
# ROUTE 2 : Voir panier
# -------------------------
@app.route("/panier/<int:panier_id>", methods=["GET"])
def get_panier(panier_id):
    query = """
        SELECT p.nom, lp.quantite, p.prix
        FROM LignePanier lp
        JOIN Produit p ON lp.pid = p.pid
        WHERE lp.panierId = %s
    """
    db.execute(query, (panier_id,))
    panier = db.fetchall()
    return render_template("panier.html", panier=panier, panier_id=panier_id)


# -------------------------
# ROUTE 3 : Ajouter au panier
# -------------------------
@app.route("/panier/ajouter", methods=["POST"])
def ajouter_panier():
    data = request.json
    panier_id = data["panierId"]
    pid = data["pid"]
    quantite = data.get("quantite", 1)

    query = """
        INSERT INTO LignePanier (panierId, pid, quantite)
        VALUES (%s, %s, %s)
    """
    db.execute(query, (panier_id, pid, quantite))

    return jsonify({"message": "Produit ajouté au panier"})


# -------------------------
# ROUTE 4 : Payer (procédure)
# -------------------------
@app.route("/payer/<int:panier_id>", methods=["POST"])
def payer(panier_id):
    db.call_procedure("creer_commande", (panier_id,))
    return jsonify({"message": "Commande créée avec succès"})

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