"use client";

import { useState, useEffect } from "react";
import {
  collection,
  getDocs,
  updateDoc,
  doc,
  orderBy,
  query,
} from "firebase/firestore";
import { db } from "@/lib/firebase";

const STATUTS = [
  "Tous",
  "En attente",
  "Confirmée",
  "Expédiée",
  "Livrée",
  "Annulée",
];

export default function CommandesPage() {
  const [commandes, setCommandes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filtre, setFiltre] = useState("Tous");
  const [commandeExpanded, setCommandeExpanded] = useState(null);

  useEffect(() => {
    fetchCommandes();
  }, []);

  const fetchCommandes = async () => {
    setLoading(true);
    try {
      const q = query(
        collection(db, "commandes"),
        orderBy("createdAt", "desc"),
      );
      const snapshot = await getDocs(q);
      const data = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }));
      setCommandes(data);
    } catch (error) {
      setCommandes([]);
    }
    setLoading(false);
  };

  const updateStatut = async (id, newStatut) => {
    await updateDoc(doc(db, "commandes", id), { statut: newStatut });
    fetchCommandes();
  };

  const filtered =
    filtre === "Tous"
      ? commandes
      : commandes.filter((c) => c.statut === filtre);

  const statutInlineColors = {
    "En attente": { bg: "#fef3c7", text: "#d97706", dot: "#f59e0b" },
    Confirmée:    { bg: "#dbeafe", text: "#1d4ed8", dot: "#3b82f6" },
    Expédiée:     { bg: "#ede9fe", text: "#6d28d9", dot: "#7c3aed" },
    Livrée:       { bg: "#d1fae5", text: "#065f46", dot: "#10b981" },
    Annulée:      { bg: "#fee2e2", text: "#b91c1c", dot: "#ef4444" },
  };

  return (
    <div>
      {/* Info + filter row */}
      <div className="flex items-center justify-between mb-4">
        <span className="text-sm text-gray-500 font-medium">{commandes.length} commande(s) au total</span>
        <button
          onClick={fetchCommandes}
          className="flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-semibold transition-colors"
          style={{ background: "#f5f0ff", color: "#7c3aed" }}
          onMouseEnter={(e) => (e.currentTarget.style.background = "#ede9fe")}
          onMouseLeave={(e) => (e.currentTarget.style.background = "#f5f0ff")}
        >
          <svg width="12" height="12" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
            <polyline points="23 4 23 10 17 10" /><polyline points="1 20 1 14 7 14" />
            <path strokeLinecap="round" d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" />
          </svg>
          Actualiser
        </button>
      </div>

      <div className="flex gap-2 flex-wrap mb-5">
        {STATUTS.map((s) => {
          const isActive = filtre === s;
          return (
            <button
              key={s}
              onClick={() => setFiltre(s)}
              className="px-4 py-2 rounded-xl text-xs font-semibold transition-all"
              style={isActive
                ? { background: "linear-gradient(135deg,#7c3aed,#4f46e5)", color: "white", boxShadow: "0 4px 12px rgba(124,58,237,0.3)" }
                : { background: "white", color: "#6b7280", border: "1.5px solid #f0f0f5" }
              }
              onMouseEnter={(e) => { if (!isActive) e.currentTarget.style.borderColor = "#c4b5fd"; }}
              onMouseLeave={(e) => { if (!isActive) e.currentTarget.style.borderColor = "#f0f0f5"; }}
            >
              {s}
              {s !== "Tous" && (
                <span className="ml-1.5 opacity-70">
                  ({commandes.filter((c) => c.statut === s).length})
                </span>
              )}
            </button>
          );
        })}
      </div>

      {loading ? (
        <div className="text-center py-12 text-gray-400">Chargement...</div>
      ) : filtered.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center shadow-sm border border-gray-100">
          <p className="text-4xl mb-4">📦</p>
          <p className="text-gray-500">
            Aucune commande {filtre !== "Tous" ? `"${filtre}"` : ""}.
          </p>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          {filtered.map((commande) => {
            const cfg = statutInlineColors[commande.statut] || { bg: "#f3f4f6", text: "#6b7280", dot: "#9ca3af" };
            return (
            <div
              key={commande.id}
              className="bg-white rounded-2xl overflow-hidden"
              style={{ border: "1px solid #f0f0f5", boxShadow: "0 2px 8px rgba(0,0,0,0.04)" }}
            >
              <div className="p-5">
                <div className="flex items-center justify-between flex-wrap gap-4">
                  {/* Infos commande */}
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{ background: "#f5f0ff" }}>
                      <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="#7c3aed" strokeWidth={2}>
                        <path strokeLinecap="round" d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" />
                        <line x1="3" y1="6" x2="21" y2="6" />
                      </svg>
                    </div>
                    <div>
                      <p className="font-semibold text-gray-800 text-sm">
                        Commande #{commande.id.slice(0, 8).toUpperCase()}
                      </p>
                      <p className="text-xs text-gray-400 mt-0.5">
                        {commande.userEmail || "Client inconnu"} ·{" "}
                        {commande.createdAt?.toDate
                          ? commande.createdAt.toDate().toLocaleDateString("fr-FR")
                          : "Date inconnue"}
                      </p>
                    </div>
                  </div>

                  {/* Total */}
                  <span className="font-bold text-lg" style={{ color: "#7c3aed" }}>
                    {commande.total || 0} DT
                  </span>

                  {/* Statut + actions */}
                  <div className="flex items-center gap-3">
                    <span
                      className="inline-flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-full font-semibold"
                      style={{ background: cfg.bg, color: cfg.text }}
                    >
                      <span className="w-1.5 h-1.5 rounded-full" style={{ background: cfg.dot }} />
                      {commande.statut || "En attente"}
                    </span>

                    <select
                      value={commande.statut || "En attente"}
                      onChange={(e) => updateStatut(commande.id, e.target.value)}
                      className="text-xs rounded-xl px-3 py-1.5 cursor-pointer outline-none"
                      style={{ border: "1.5px solid #e9d5ff", color: "#7c3aed", background: "#faf5ff" }}
                    >
                      {STATUTS.filter((s) => s !== "Tous").map((s) => (
                        <option key={s} value={s}>
                          {s}
                        </option>
                      ))}
                    </select>

                    <button
                      onClick={() =>
                        setCommandeExpanded(
                          commandeExpanded === commande.id ? null : commande.id,
                        )
                      }
                      className="text-gray-400 hover:text-purple-600 transition"
                    >
                      {commandeExpanded === commande.id ? "▲" : "▼"}
                    </button>
                  </div>
                </div>

                {/* Informations client détaillées */}
                {(commande.userName ||
                  commande.adresse ||
                  commande.telephone) && (
                  <div className="mt-4 p-3 bg-blue-50 rounded-xl">
                    <h4 className="text-xs font-semibold text-blue-800 mb-2">
                      📋 Informations client
                    </h4>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-2 text-xs">
                      {commande.userName && (
                        <div>
                          <span className="text-gray-500">Nom :</span>{" "}
                          <span className="font-medium text-gray-700">
                            {commande.userName}
                          </span>
                        </div>
                      )}
                      {commande.adresse && (
                        <div>
                          <span className="text-gray-500">Adresse :</span>{" "}
                          <span className="font-medium text-gray-700">
                            {commande.adresse}
                          </span>
                        </div>
                      )}
                      {commande.telephone && (
                        <div>
                          <span className="text-gray-500">Téléphone :</span>{" "}
                          <span className="font-medium text-gray-700">
                            {commande.telephone}
                          </span>
                        </div>
                      )}
                    </div>
                  </div>
                )}
              </div>

              {/* Section expandue avec détails des articles */}
              {commandeExpanded === commande.id && (
                <div className="border-t border-gray-100 bg-gray-50 p-5">
                  <h4 className="text-sm font-semibold text-gray-700 mb-3">
                    🛍️ Détails des articles
                  </h4>

                  {commande.articles && commande.articles.length > 0 ? (
                    <div className="space-y-3">
                      {commande.articles.map((article, i) => (
                        <div
                          key={i}
                          className="bg-white rounded-xl p-3 shadow-sm"
                        >
                          <div className="flex justify-between items-start">
                            <div className="flex-1">
                              <p className="font-medium text-gray-800 text-sm">
                                {article.nom}
                              </p>
                              <div className="flex flex-wrap gap-3 mt-1 text-xs text-gray-500">
                                {article.taille && (
                                  <span className="bg-purple-100 text-purple-700 px-2 py-0.5 rounded">
                                    Taille: {article.taille}
                                  </span>
                                )}
                                {article.couleur && (
                                  <span className="bg-pink-100 text-pink-700 px-2 py-0.5 rounded">
                                    Couleur: {article.couleur}
                                  </span>
                                )}
                                {article.marque && (
                                  <span>Marque: {article.marque}</span>
                                )}
                              </div>
                            </div>
                            <div className="text-right">
                              <p className="text-purple-700 font-bold">
                                {(
                                  (article.prix || 0) *
                                  (article.quantity || article.quantite || 1)
                                ).toFixed(2)}{" "}
                                DT
                              </p>
                              <p className="text-xs text-gray-400">
                                {article.prix} DT ×{" "}
                                {article.quantity || article.quantite || 1}
                              </p>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-gray-400 text-sm">
                      Aucun article détaillé
                    </p>
                  )}
                </div>
              )}
            </div>
          );
          })}
        </div>
      )}
    </div>
  );
}
