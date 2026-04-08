from flask import Flask, jsonify, request, render_template
from database import Database

app = Flask(__name__)
db = Database()

# -------------------------
# ACCUEIL
# -------------------------
@app.route("/")
def index():
    return render_template('base.html')
# -------------------------
# ROUTE 1 : Voir produits
# -------------------------
@app.route("/produits", methods=["GET"])
def get_produits():
    db.execute("SELECT * FROM Produit")
    produits = db.fetchall()
    return jsonify(produits)


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
    return jsonify(panier)


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


# -------------------------
# Lancer serveur
# -------------------------
if __name__ == "__main__":
    app.run(debug=True)