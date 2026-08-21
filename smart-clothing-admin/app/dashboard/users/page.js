"use client";

import { useState, useEffect } from "react";
import {
  collection,
  getDocs,
  updateDoc,
  deleteDoc,
  doc,
  setDoc,
} from "firebase/firestore";
import { createUserWithEmailAndPassword, getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { initializeApp, getApps } from "firebase/app";
import { db } from "@/lib/firebase";

const firebaseConfig = {
  apiKey: "AIzaSyDN-MTr6dS2cb-mvXYgez7vyoEtJRBfjhw",
  authDomain: "smart-clothing-advisor-2026.firebaseapp.com",
  projectId: "smart-clothing-advisor-2026",
  storageBucket: "smart-clothing-advisor-2026.firebasestorage.app",
  messagingSenderId: "949137189579",
  appId: "1:949137189579:web:ce39a1f5b22a12509a494e",
};

function getSecondaryApp() {
  const existing = getApps().find((a) => a.name === "secondary");
  return existing ?? initializeApp(firebaseConfig, "secondary");
}

function AddUserModal({ onClose, onSuccess }) {
  const [form, setForm] = useState({
    nom: "",
    email: "",
    password: "",
    role: "user",
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    if (form.password.length < 6) {
      setError("Le mot de passe doit contenir au moins 6 caractères.");
      return;
    }
    setLoading(true);
    try {
      // Créer le compte via l'app secondaire (ne déconnecte pas l'admin)
      const secondaryApp = getSecondaryApp();
      const secondaryAuth = getAuth(secondaryApp);
      const secondaryDb = getFirestore(secondaryApp);

      const cred = await createUserWithEmailAndPassword(
        secondaryAuth,
        form.email,
        form.password,
      );

      // ✅ Écrire dans Firestore via l'app secondaire (token du nouvel user)
      // Cela respecte la règle : request.auth.uid == userId
      await setDoc(doc(secondaryDb, "users", cred.user.uid), {
        nom: form.nom,
        email: form.email,
        role: form.role,
        bloque: false,
        createdAt: new Date().toISOString(),
      });

      // Déconnecter l'app secondaire après l'écriture
      await secondaryAuth.signOut();

      onSuccess();
      onClose();
    } catch (err) {
      const messages = {
        "auth/email-already-in-use": "Cet email est déjà utilisé.",
        "auth/invalid-email": "Email invalide.",
        "auth/weak-password": "Mot de passe trop faible.",
      };
      setError(messages[err.code] || "Erreur : " + err.message);
    }
    setLoading(false);
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      style={{ background: "rgba(0,0,0,0.45)", backdropFilter: "blur(4px)" }}
    >
      <div
        className="w-full max-w-md rounded-3xl p-8 relative"
        style={{
          background: "#fff",
          boxShadow: "0 24px 60px rgba(0,0,0,0.18)",
        }}
      >
        <button
          onClick={onClose}
          className="absolute top-5 right-5 w-8 h-8 rounded-full flex items-center justify-center transition"
          style={{ background: "#f5f0ff", color: "#7c3aed" }}
        >
          <svg
            width="14"
            height="14"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2.5}
          >
            <line x1="18" y1="6" x2="6" y2="18" />
            <line x1="6" y1="6" x2="18" y2="18" />
          </svg>
        </button>

        <div className="flex items-center gap-3 mb-6">
          <div
            className="w-10 h-10 rounded-xl flex items-center justify-center"
            style={{ background: "linear-gradient(135deg,#7c3aed,#4f46e5)" }}
          >
            <svg
              width="18"
              height="18"
              fill="none"
              viewBox="0 0 24 24"
              stroke="white"
              strokeWidth={2}
            >
              <path
                strokeLinecap="round"
                d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"
              />
              <circle cx="9" cy="7" r="4" />
              <line x1="19" y1="8" x2="19" y2="14" strokeLinecap="round" />
              <line x1="22" y1="11" x2="16" y2="11" strokeLinecap="round" />
            </svg>
          </div>
          <div>
            <h2 className="text-lg font-bold text-gray-800">
              Ajouter un utilisateur
            </h2>
            <p className="text-xs text-gray-400">Créer un nouveau compte</p>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider block mb-1.5">
              Nom complet
            </label>
            <input
              type="text"
              required
              placeholder="Prénom Nom"
              value={form.nom}
              onChange={(e) => setForm({ ...form, nom: e.target.value })}
              className="w-full px-4 py-2.5 text-sm rounded-xl outline-none"
              style={{
                background: "#f8f5ff",
                border: "1.5px solid #e9d5ff",
                color: "#1a1a2e",
              }}
              onFocus={(e) => (e.target.style.border = "1.5px solid #7c3aed")}
              onBlur={(e) => (e.target.style.border = "1.5px solid #e9d5ff")}
            />
          </div>

          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider block mb-1.5">
              Adresse email
            </label>
            <input
              type="email"
              required
              placeholder="exemple@email.com"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
              className="w-full px-4 py-2.5 text-sm rounded-xl outline-none"
              style={{
                background: "#f8f5ff",
                border: "1.5px solid #e9d5ff",
                color: "#1a1a2e",
              }}
              onFocus={(e) => (e.target.style.border = "1.5px solid #7c3aed")}
              onBlur={(e) => (e.target.style.border = "1.5px solid #e9d5ff")}
            />
          </div>

          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider block mb-1.5">
              Mot de passe
            </label>
            <input
              type="password"
              required
              placeholder="Minimum 6 caractères"
              value={form.password}
              onChange={(e) => setForm({ ...form, password: e.target.value })}
              className="w-full px-4 py-2.5 text-sm rounded-xl outline-none"
              style={{
                background: "#f8f5ff",
                border: "1.5px solid #e9d5ff",
                color: "#1a1a2e",
              }}
              onFocus={(e) => (e.target.style.border = "1.5px solid #7c3aed")}
              onBlur={(e) => (e.target.style.border = "1.5px solid #e9d5ff")}
            />
          </div>

          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider block mb-1.5">
              Rôle
            </label>
            <select
              value={form.role}
              onChange={(e) => setForm({ ...form, role: e.target.value })}
              className="w-full px-4 py-2.5 text-sm rounded-xl outline-none cursor-pointer"
              style={{
                background: "#f8f5ff",
                border: "1.5px solid #e9d5ff",
                color: "#1a1a2e",
              }}
            >
              <option value="user">👤 Utilisateur</option>
              <option value="admin">🛡️ Administrateur</option>
            </select>
          </div>

          {error && (
            <div
              className="flex items-center gap-2 text-sm px-4 py-3 rounded-xl"
              style={{
                background: "#fee2e2",
                color: "#b91c1c",
                border: "1px solid #fecaca",
              }}
            >
              <svg
                width="14"
                height="14"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={2}
              >
                <circle cx="12" cy="12" r="10" />
                <line x1="12" y1="8" x2="12" y2="12" />
                <line x1="12" y1="16" x2="12.01" y2="16" />
              </svg>
              {error}
            </div>
          )}

          <div className="flex gap-3 mt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2.5 rounded-xl text-sm font-semibold transition"
              style={{ background: "#f5f0ff", color: "#7c3aed" }}
            >
              Annuler
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-white transition"
              style={{
                background: loading
                  ? "#9ca3af"
                  : "linear-gradient(135deg,#7c3aed,#4f46e5)",
                boxShadow: loading
                  ? "none"
                  : "0 6px 16px rgba(124,58,237,0.35)",
              }}
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  Création...
                </span>
              ) : (
                "Créer le compte"
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [showModal, setShowModal] = useState(false);
  const [toast, setToast] = useState("");

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const snapshot = await getDocs(collection(db, "users"));
      const data = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }));
      setUsers(data);
    } catch (err) {
      console.error("Erreur chargement users:", err);
    }
    setLoading(false);
  };

  const showToast = (msg) => {
    setToast(msg);
    setTimeout(() => setToast(""), 3000);
  };

  const toggleBlock = async (user) => {
    const action = user.bloque ? "débloquer" : "bloquer";
    if (!confirm(`Voulez-vous ${action} ${user.nom || user.email} ?`)) return;
    await updateDoc(doc(db, "users", user.id), { bloque: !user.bloque });
    fetchUsers();
    showToast(
      `Utilisateur ${action === "bloquer" ? "bloqué" : "débloqué"} avec succès.`,
    );
  };

  const handleDelete = async (user) => {
    if (!confirm(`Supprimer définitivement ${user.nom || user.email} ?`))
      return;
    await deleteDoc(doc(db, "users", user.id));
    fetchUsers();
    showToast("Utilisateur supprimé.");
  };

  const filteredUsers = users.filter(
    (u) =>
      (u.nom || "").toLowerCase().includes(search.toLowerCase()) ||
      (u.email || "").toLowerCase().includes(search.toLowerCase()),
  );

  return (
    <div>
      {showModal && (
        <AddUserModal
          onClose={() => setShowModal(false)}
          onSuccess={() => {
            fetchUsers();
            showToast("✅ Utilisateur créé avec succès !");
          }}
        />
      )}

      {toast && (
        <div
          className="fixed top-5 right-5 z-50 px-5 py-3 rounded-2xl text-sm font-semibold text-white"
          style={{
            background: "linear-gradient(135deg,#7c3aed,#4f46e5)",
            boxShadow: "0 8px 24px rgba(124,58,237,0.35)",
          }}
        >
          {toast}
        </div>
      )}

      <div className="flex items-center justify-between mb-5">
        <span className="text-sm text-gray-500 font-medium">
          {users.length} utilisateur(s) au total
        </span>
        <div className="flex items-center gap-3">
          <button
            onClick={fetchUsers}
            className="flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-semibold transition"
            style={{ background: "#f5f0ff", color: "#7c3aed" }}
            onMouseEnter={(e) => (e.currentTarget.style.background = "#ede9fe")}
            onMouseLeave={(e) => (e.currentTarget.style.background = "#f5f0ff")}
          >
            <svg
              width="12"
              height="12"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2.5}
            >
              <polyline points="23 4 23 10 17 10" />
              <polyline points="1 20 1 14 7 14" />
              <path
                strokeLinecap="round"
                d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"
              />
            </svg>
            Actualiser
          </button>
          <button
            onClick={() => setShowModal(true)}
            className="flex items-center gap-2 px-4 py-1.5 rounded-xl text-xs font-semibold text-white transition"
            style={{
              background: "linear-gradient(135deg,#7c3aed,#4f46e5)",
              boxShadow: "0 4px 12px rgba(124,58,237,0.35)",
            }}
            onMouseEnter={(e) => (e.currentTarget.style.opacity = "0.9")}
            onMouseLeave={(e) => (e.currentTarget.style.opacity = "1")}
          >
            <svg
              width="12"
              height="12"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2.5}
            >
              <line x1="12" y1="5" x2="12" y2="19" strokeLinecap="round" />
              <line x1="5" y1="12" x2="19" y2="12" strokeLinecap="round" />
            </svg>
            Ajouter un utilisateur
          </button>
        </div>
      </div>

      <div
        className="rounded-2xl px-4 py-3 mb-5 flex items-center gap-3"
        style={{
          background: "#fff",
          border: "1.5px solid #f0f0f5",
          boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
        }}
      >
        <svg
          width="16"
          height="16"
          fill="none"
          viewBox="0 0 24 24"
          stroke="#9ca3af"
          strokeWidth={2}
        >
          <circle cx="11" cy="11" r="8" />
          <line x1="21" y1="21" x2="16.65" y2="16.65" />
        </svg>
        <input
          type="text"
          placeholder="Rechercher par nom ou email..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="flex-1 text-sm focus:outline-none text-gray-700 bg-transparent"
        />
        {search && (
          <button
            onClick={() => setSearch("")}
            className="text-gray-300 hover:text-gray-500"
          >
            <svg
              width="14"
              height="14"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <line x1="18" y1="6" x2="6" y2="18" />
              <line x1="6" y1="6" x2="18" y2="18" />
            </svg>
          </button>
        )}
      </div>

      {loading ? (
        <div
          className="bg-white rounded-2xl p-8"
          style={{ border: "1px solid #f0f0f5" }}
        >
          {[...Array(5)].map((_, i) => (
            <div key={i} className="flex items-center gap-4 py-3 animate-pulse">
              <div className="w-9 h-9 rounded-full bg-gray-100" />
              <div className="flex-1">
                <div className="h-3 bg-gray-100 rounded w-32 mb-2" />
                <div className="h-2.5 bg-gray-100 rounded w-48" />
              </div>
              <div className="h-5 bg-gray-100 rounded-full w-16" />
            </div>
          ))}
        </div>
      ) : filteredUsers.length === 0 ? (
        <div
          className="bg-white rounded-2xl p-12 text-center"
          style={{ border: "1px solid #f0f0f5" }}
        >
          <div
            className="w-14 h-14 rounded-2xl flex items-center justify-center mx-auto mb-3"
            style={{ background: "#f5f0ff" }}
          >
            <svg
              width="24"
              height="24"
              fill="none"
              viewBox="0 0 24 24"
              stroke="#7c3aed"
              strokeWidth={2}
            >
              <path
                strokeLinecap="round"
                d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"
              />
              <circle cx="9" cy="7" r="4" />
            </svg>
          </div>
          <p className="text-gray-400 text-sm font-medium">
            Aucun utilisateur trouvé.
          </p>
          <button
            onClick={() => setShowModal(true)}
            className="mt-4 px-5 py-2 rounded-xl text-sm font-semibold text-white"
            style={{ background: "linear-gradient(135deg,#7c3aed,#4f46e5)" }}
          >
            + Ajouter le premier utilisateur
          </button>
        </div>
      ) : (
        <div
          className="bg-white rounded-2xl overflow-hidden"
          style={{
            border: "1px solid #f0f0f5",
            boxShadow: "0 2px 12px rgba(0,0,0,0.04)",
          }}
        >
          <table className="w-full">
            <thead>
              <tr
                style={{
                  borderBottom: "1px solid #f5f5fa",
                  background: "#fafafa",
                }}
              >
                <th className="text-left px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-gray-400">
                  Utilisateur
                </th>
                <th className="text-left px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-gray-400">
                  Rôle
                </th>
                <th className="text-left px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-gray-400">
                  Mensurations
                </th>
                <th className="text-left px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-gray-400">
                  Statut
                </th>
                <th className="text-left px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-gray-400">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.map((user) => (
                <tr
                  key={user.id}
                  className="transition-colors"
                  style={{ borderBottom: "1px solid #f9f9fb" }}
                  onMouseEnter={(e) =>
                    (e.currentTarget.style.background = "#fafafa")
                  }
                  onMouseLeave={(e) =>
                    (e.currentTarget.style.background = "transparent")
                  }
                >
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div
                        className="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-sm"
                        style={{
                          background: "linear-gradient(135deg,#7c3aed,#4f46e5)",
                          color: "white",
                        }}
                      >
                        {(user.nom || user.email || "?")[0].toUpperCase()}
                      </div>
                      <div>
                        <p className="text-sm font-medium text-gray-800">
                          {user.nom || "—"}
                        </p>
                        <p className="text-xs text-gray-400">{user.email}</p>
                      </div>
                    </div>
                  </td>

                  <td className="px-6 py-4">
                    <span
                      className="inline-flex items-center gap-1.5 text-xs px-2.5 py-1 rounded-full font-semibold"
                      style={
                        user.role === "admin"
                          ? { background: "#f5f0ff", color: "#7c3aed" }
                          : { background: "#f3f4f6", color: "#6b7280" }
                      }
                    >
                      <span
                        className="w-1.5 h-1.5 rounded-full"
                        style={{
                          background:
                            user.role === "admin" ? "#7c3aed" : "#9ca3af",
                        }}
                      />
                      {user.role === "admin" ? "Admin" : "Utilisateur"}
                    </span>
                  </td>

                  <td className="px-6 py-4">
                    <div className="text-xs text-gray-500">
                      {user.taille ? (
                        <span>
                          {user.taille} cm · {user.poids} kg
                        </span>
                      ) : (
                        <span className="text-gray-300">Non renseigné</span>
                      )}
                    </div>
                  </td>

                  <td className="px-6 py-4">
                    <span
                      className="inline-flex items-center gap-1.5 text-xs px-2.5 py-1 rounded-full font-semibold"
                      style={
                        user.bloque
                          ? { background: "#fee2e2", color: "#b91c1c" }
                          : { background: "#d1fae5", color: "#065f46" }
                      }
                    >
                      <span
                        className="w-1.5 h-1.5 rounded-full"
                        style={{
                          background: user.bloque ? "#ef4444" : "#10b981",
                        }}
                      />
                      {user.bloque ? "Bloqué" : "Actif"}
                    </span>
                  </td>

                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      {user.role !== "admin" ? (
                        <>
                          <button
                            onClick={() => toggleBlock(user)}
                            className={`text-xs px-3 py-1.5 rounded-lg font-medium transition ${
                              user.bloque
                                ? "bg-green-50 text-green-600 hover:bg-green-100"
                                : "bg-orange-50 text-orange-600 hover:bg-orange-100"
                            }`}
                          >
                            {user.bloque ? "✅ Débloquer" : "🚫 Bloquer"}
                          </button>
                          <button
                            onClick={() => handleDelete(user)}
                            className="text-xs px-3 py-1.5 rounded-lg font-medium bg-red-50 text-red-500 hover:bg-red-100 transition"
                          >
                            🗑️ Supprimer
                          </button>
                        </>
                      ) : (
                        <span className="text-xs text-gray-300">Protégé</span>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
