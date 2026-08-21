"use client";

import { useState, useEffect } from "react";
import {
  collection,
  getDocs,
  addDoc,
  deleteDoc,
  doc,
  updateDoc,
} from "firebase/firestore";
import { db } from "@/lib/firebase";

const CATEGORIES = [
  "Robes",
  "Pantalons",
  "Chemises",
  "Chaussures",
  "Accessoires",
  "Vestes",
];
const TAILLES_VETEMENTS = ["XS", "S", "M", "L", "XL", "XXL"];
const TAILLES_CHAUSSURES = [
  "36",
  "37",
  "38",
  "39",
  "40",
  "41",
  "42",
  "43",
  "44",
  "45",
];
const COULEURS = [
  { nom: "Noir", hex: "#000000" },
  { nom: "Blanc", hex: "#FFFFFF" },
  { nom: "Rouge", hex: "#EF4444" },
  { nom: "Bleu", hex: "#3B82F6" },
  { nom: "Vert", hex: "#22C55E" },
  { nom: "Jaune", hex: "#EAB308" },
  { nom: "Rose", hex: "#EC4899" },
  { nom: "Violet", hex: "#8B5CF6" },
  { nom: "Orange", hex: "#F97316" },
  { nom: "Gris", hex: "#6B7280" },
  { nom: "Marron", hex: "#92400E" },
  { nom: "Beige", hex: "#D4B896" },
];

const emptyForm = {
  nom: "",
  marque: "",
  prix: "",
  ancienPrix: "",
  promo: false,
  pourcentagePromo: "",
  categorie: "",
  description: "",
  imageUrl: "",
  imageUrl2: "",
  imageUrl3: "",
  stock: "",
  tailles: [],
  couleurs: [],
  nouveaute: false,
  disponible: true,
};

const CLOUDINARY_CLOUD_NAME = "defg4c0bd";
const CLOUDINARY_UPLOAD_PRESET = "smartclothingadvisor";

async function uploadImage(file) {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("upload_preset", CLOUDINARY_UPLOAD_PRESET);
  const res = await fetch(
    `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/image/upload`,
    { method: "POST", body: formData }
  );
  if (!res.ok) throw new Error("Erreur Cloudinary");
  const data = await res.json();
  return data.secure_url;
}

export default function ArticlesPage() {
  const [articles, setArticles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editArticle, setEditArticle] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [activeTab, setActiveTab] = useState("infos");
  const [uploading, setUploading] = useState({ img1: false, img2: false, img3: false });

  useEffect(() => {
    fetchArticles();
  }, []);

  const fetchArticles = async () => {
    setLoading(true);
    try {
      const snapshot = await getDocs(collection(db, "articles"));
      const data = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }));
      setArticles(data);
    } catch (e) {
      console.error(e);
    }
    setLoading(false);
  };

  // Calcul prix promo automatique
  const getPrixPromo = () => {
    if (!form.promo || !form.prix || !form.pourcentagePromo) return null;
    const prix = parseFloat(form.prix);
    const pct = parseFloat(form.pourcentagePromo);
    if (isNaN(prix) || isNaN(pct)) return null;
    return (prix - (prix * pct) / 100).toFixed(2);
  };

  const toggleTaille = (t) => {
    setForm((f) => ({
      ...f,
      tailles: f.tailles.includes(t)
        ? f.tailles.filter((x) => x !== t)
        : [...f.tailles, t],
    }));
  };

  const toggleCouleur = (c) => {
    setForm((f) => ({
      ...f,
      couleurs: f.couleurs.some((x) => x.nom === c.nom)
        ? f.couleurs.filter((x) => x.nom !== c.nom)
        : [...f.couleurs, c],
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const prixPromo = getPrixPromo();
      const data = {
        nom: form.nom,
        marque: form.marque,
        prix: parseFloat(form.prix),
        ancienPrix:
          form.promo && prixPromo
            ? parseFloat(form.prix)
            : form.ancienPrix
              ? parseFloat(form.ancienPrix)
              : null,
        prixPromo: prixPromo ? parseFloat(prixPromo) : null,
        promo: form.promo,
        pourcentagePromo:
          form.promo && form.pourcentagePromo
            ? parseFloat(form.pourcentagePromo)
            : null,
        categorie: form.categorie,
        description: form.description,
        imageUrl: form.imageUrl,
        imageUrl2: form.imageUrl2 || "",
        imageUrl3: form.imageUrl3 || "",
        stock: parseInt(form.stock) || 0,
        tailles: form.tailles,
        couleurs: form.couleurs,
        nouveaute: form.nouveaute,
        disponible: form.disponible,
        updatedAt: new Date(),
      };

      if (editArticle) {
        await updateDoc(doc(db, "articles", editArticle.id), data);
      } else {
        await addDoc(collection(db, "articles"), {
          ...data,
          createdAt: new Date(),
        });
      }

      setForm(emptyForm);
      setShowForm(false);
      setEditArticle(null);
      setActiveTab("infos");
      fetchArticles();
    } catch (e) {
      console.error(e);
    }
  };

  const handleEdit = (article) => {
    setEditArticle(article);
    setForm({
      nom: article.nom || "",
      marque: article.marque || "",
      prix: article.ancienPrix || article.prix || "",
      ancienPrix: article.ancienPrix || "",
      promo: article.promo || false,
      pourcentagePromo: article.pourcentagePromo || "",
      categorie: article.categorie || "",
      description: article.description || "",
      imageUrl: article.imageUrl || "",
      imageUrl2: article.imageUrl2 || "",
      imageUrl3: article.imageUrl3 || "",
      stock: article.stock || "",
      tailles: article.tailles || [],
      couleurs: article.couleurs || [],
      nouveaute: article.nouveaute || false,
      disponible: article.disponible !== false,
    });
    setShowForm(true);
    setActiveTab("infos");
  };

  const handleDelete = async (id) => {
    if (!confirm("Supprimer cet article ?")) return;
    await deleteDoc(doc(db, "articles", id));
    fetchArticles();
  };

  const handleCancel = () => {
    setShowForm(false);
    setEditArticle(null);
    setForm(emptyForm);
    setActiveTab("infos");
  };

  const taillesToShow =
    form.categorie === "Chaussures" ? TAILLES_CHAUSSURES : TAILLES_VETEMENTS;

  const prixPromoCalc = getPrixPromo();

  return (
    <div>
      {/* Info bar */}
      <div className="flex items-center justify-between mb-5">
        <span className="text-sm text-gray-500 font-medium">
          {articles.length} article(s) au total
        </span>
        <div className="flex items-center gap-2">
          <button
            onClick={fetchArticles}
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
          {!showForm && (
            <button
              onClick={() => setShowForm(true)}
              className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold text-white transition"
              style={{ background: "linear-gradient(135deg,#7c3aed,#4f46e5)", boxShadow: "0 4px 12px rgba(124,58,237,0.3)" }}
              onMouseEnter={(e) => (e.currentTarget.style.opacity = "0.9")}
              onMouseLeave={(e) => (e.currentTarget.style.opacity = "1")}
            >
              <svg width="14" height="14" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                <line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" />
              </svg>
              Ajouter un article
            </button>
          )}
        </div>
      </div>

      {/* Formulaire */}
      {showForm && (
        <div className="bg-white rounded-2xl mb-8 overflow-hidden" style={{ border: "1px solid #f0f0f5", boxShadow: "0 4px 16px rgba(0,0,0,0.06)" }}>
          {/* Titre formulaire */}
          <div className="px-6 py-4 flex items-center justify-between" style={{ borderBottom: "1px solid #f0f0f5" }}>
            <h2 className="text-base font-semibold text-gray-700">
              {editArticle ? "Modifier l'article" : "Nouvel article"}
            </h2>
            <button
              onClick={handleCancel}
              className="w-7 h-7 rounded-lg flex items-center justify-center transition"
              style={{ background: "#f5f5f8", color: "#9ca3af" }}
              onMouseEnter={(e) => { e.currentTarget.style.background = "#fee2e2"; e.currentTarget.style.color = "#ef4444"; }}
              onMouseLeave={(e) => { e.currentTarget.style.background = "#f5f5f8"; e.currentTarget.style.color = "#9ca3af"; }}
            >
              <svg width="12" height="12" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
              </svg>
            </button>
          </div>

          {/* Onglets */}
          <div className="flex" style={{ borderBottom: "1px solid #f0f0f5" }}>
            {[
              { id: "infos", label: "Infos" },
              { id: "prix", label: "Prix & Promo" },
              { id: "stock", label: "Stock & Variantes" },
              { id: "images", label: "Images" },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className="px-5 py-3 text-sm font-medium transition"
                style={activeTab === tab.id
                  ? { borderBottom: "2px solid #7c3aed", color: "#7c3aed", marginBottom: "-1px" }
                  : { borderBottom: "2px solid transparent", color: "#9ca3af" }}
              >
                {tab.label}
              </button>
            ))}
          </div>

          <form onSubmit={handleSubmit}>
            <div className="p-6">
              {/* ─── Onglet Infos ─── */}
              {activeTab === "infos" && (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1.5 block">
                      Nom de l'article *
                    </label>
                    <input
                      type="text"
                      value={form.nom}
                      onChange={(e) => setForm({ ...form, nom: e.target.value })}
                      placeholder="Ex: Robe d'été fleurie"
                      required
                      className="w-full rounded-xl px-4 py-2.5 text-sm outline-none transition-all"
                      style={{ background: "#f5f0ff", border: "1.5px solid #e9d5ff", color: "#1a1a2e" }}
                      onFocus={(e) => (e.target.style.border = "1.5px solid #7c3aed")}
                      onBlur={(e) => (e.target.style.border = "1.5px solid #e9d5ff")}
                    />
                  </div>

                  <div>
                    <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1.5 block">
                      Marque
                    </label>
                    <input
                      type="text"
                      value={form.marque}
                      onChange={(e) => setForm({ ...form, marque: e.target.value })}
                      placeholder="Ex: Zara, H&M..."
                      className="w-full rounded-xl px-4 py-2.5 text-sm outline-none transition-all"
                      style={{ background: "#f5f0ff", border: "1.5px solid #e9d5ff", color: "#1a1a2e" }}
                      onFocus={(e) => (e.target.style.border = "1.5px solid #7c3aed")}
                      onBlur={(e) => (e.target.style.border = "1.5px solid #e9d5ff")}
                    />
                  </div>

                  <div>
                    <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1.5 block">
                      Catégorie *
                    </label>
                    <select
                      value={form.categorie}
                      onChange={(e) => setForm({ ...form, categorie: e.target.value, tailles: [] })}
                      required
                      className="w-full rounded-xl px-4 py-2.5 text-sm outline-none transition-all cursor-pointer"
                      style={{ background: "#f5f0ff", border: "1.5px solid #e9d5ff", color: "#1a1a2e" }}
                      onFocus={(e) => (e.target.style.border = "1.5px solid #7c3aed")}
                      onBlur={(e) => (e.target.style.border = "1.5px solid #e9d5ff")}
                    >
                      <option value="">Choisir une catégorie</option>
                      {CATEGORIES.map((cat) => (
                        <option key={cat} value={cat}>{cat}</option>
                      ))}
                    </select>
                  </div>

                  <div className="flex gap-4 items-center">
                    <label className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={form.nouveaute}
                        onChange={(e) => setForm({ ...form, nouveaute: e.target.checked })}
                        className="w-4 h-4 accent-purple-600"
                      />
                      <span className="text-sm text-gray-600">Nouveauté</span>
                    </label>
                    <label className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={form.disponible}
                        onChange={(e) => setForm({ ...form, disponible: e.target.checked })}
                        className="w-4 h-4 accent-purple-600"
                      />
                      <span className="text-sm text-gray-600">Disponible</span>
                    </label>
                  </div>

                  <div className="md:col-span-2">
                    <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1.5 block">
                      Description
                    </label>
                    <textarea
                      value={form.description}
                      onChange={(e) => setForm({ ...form, description: e.target.value })}
                      placeholder="Description détaillée de l'article..."
                      rows={4}
                      className="w-full rounded-xl px-4 py-2.5 text-sm outline-none transition-all resize-none"
                      style={{ background: "#f5f0ff", border: "1.5px solid #e9d5ff", color: "#1a1a2e" }}
                      onFocus={(e) => (e.target.style.border = "1.5px solid #7c3aed")}
                      onBlur={(e) => (e.target.style.border = "1.5px solid #e9d5ff")}
                    />
                  </div>
                </div>
              )}

              {/* ─── Onglet Prix & Promo ─── */}
              {activeTab === "prix" && (
                <div className="space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1.5 block">
                        Prix original (DT) *
                      </label>
                      <input
                        type="number"
                        value={form.prix}
                        onChange={(e) => setForm({ ...form, prix: e.target.value })}
                        placeholder="Ex: 89.99"
                        required
                        min="0"
                        step="0.01"
                        className="w-full rounded-xl px-4 py-2.5 text-sm outline-none transition-all"
                        style={{ background: "#f5f0ff", border: "1.5px solid #e9d5ff", color: "#1a1a2e" }}
                        onFocus={(e) => (e.target.style.border = "1.5px solid #7c3aed")}
                        onBlur={(e) => (e.target.style.border = "1.5px solid #e9d5ff")}
                      />
                    </div>
                  </div>

                  {/* Section Promo */}
                  <div className="border border-orange-200 rounded-2xl p-5 bg-orange-50">
                    <div className="flex items-center gap-3 mb-4">
                      <label className="flex items-center gap-2 cursor-pointer">
                        <input
                          type="checkbox"
                          checked={form.promo}
                          onChange={(e) =>
                            setForm({
                              ...form,
                              promo: e.target.checked,
                              pourcentagePromo: "",
                            })
                          }
                          className="w-4 h-4 accent-orange-500"
                        />
                        <span className="font-semibold text-orange-700">
                          🏷️ Activer une promotion
                        </span>
                      </label>
                    </div>

                    {form.promo && (
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                          <label className="text-xs font-semibold text-orange-600 uppercase tracking-wider mb-1.5 block">
                            Réduction (%)
                          </label>
                          <input
                            type="number"
                            value={form.pourcentagePromo}
                            onChange={(e) => setForm({ ...form, pourcentagePromo: e.target.value })}
                            placeholder="Ex: 30"
                            min="1"
                            max="99"
                            className="w-full rounded-xl px-4 py-2.5 text-sm outline-none"
                            style={{ background: "#fff7ed", border: "1.5px solid #fed7aa", color: "#1a1a2e" }}
                          />
                        </div>

                        {prixPromoCalc && (
                          <div className="flex flex-col justify-end">
                            <div className="bg-white rounded-xl p-3 border border-orange-200">
                              <p className="text-xs text-gray-500 mb-1">
                                Prix après réduction
                              </p>
                              <div className="flex items-center gap-2">
                                <span className="text-xl font-bold text-orange-600">
                                  {prixPromoCalc} DT
                                </span>
                                <span className="text-sm text-gray-400 line-through">
                                  {form.prix} DT
                                </span>
                                <span className="bg-orange-500 text-white text-xs px-2 py-0.5 rounded-full">
                                  -{form.pourcentagePromo}%
                                </span>
                              </div>
                            </div>
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* ─── Onglet Stock & Variantes ─── */}
              {activeTab === "stock" && (
                <div className="space-y-6">
                  {/* Stock */}
                  <div className="max-w-xs">
                    <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1.5 block">
                      Quantité en stock *
                    </label>
                    <input
                      type="number"
                      value={form.stock}
                      onChange={(e) => setForm({ ...form, stock: e.target.value })}
                      placeholder="Ex: 50"
                      min="0"
                      required
                      className="w-full rounded-xl px-4 py-2.5 text-sm outline-none transition-all"
                      style={{ background: "#f5f0ff", border: "1.5px solid #e9d5ff", color: "#1a1a2e" }}
                      onFocus={(e) => (e.target.style.border = "1.5px solid #7c3aed")}
                      onBlur={(e) => (e.target.style.border = "1.5px solid #e9d5ff")}
                    />
                  </div>

                  {/* Tailles */}
                  <div>
                    <label className="text-sm font-medium text-gray-700 mb-3 block">
                      Tailles disponibles
                      {form.categorie && (
                        <span className="text-xs text-gray-400 ml-2">
                          (
                          {form.categorie === "Chaussures"
                            ? "pointures"
                            : "tailles vêtements"}
                          )
                        </span>
                      )}
                    </label>
                    {!form.categorie ? (
                      <p className="text-sm text-gray-400 italic">
                        Sélectionnez d'abord une catégorie dans l'onglet Infos
                      </p>
                    ) : (
                      <div className="flex flex-wrap gap-2">
                        {taillesToShow.map((t) => (
                          <button
                            key={t}
                            type="button"
                            onClick={() => toggleTaille(t)}
                            className="px-4 py-2 rounded-xl text-sm font-medium transition"
                            style={form.tailles.includes(t)
                              ? { background: "linear-gradient(135deg,#7c3aed,#4f46e5)", color: "white", border: "1.5px solid transparent" }
                              : { background: "white", color: "#6b7280", border: "1.5px solid #e9d5ff" }}
                          >
                            {t}
                          </button>
                        ))}
                      </div>
                    )}
                    {form.tailles.length > 0 && (
                      <p className="text-xs text-purple-600 mt-2">
                        ✓ {form.tailles.length} taille(s) sélectionnée(s) :{" "}
                        {form.tailles.join(", ")}
                      </p>
                    )}
                  </div>

                  {/* Couleurs */}
                  <div>
                    <label className="text-sm font-medium text-gray-700 mb-3 block">
                      Couleurs disponibles
                    </label>
                    <div className="flex flex-wrap gap-3">
                      {COULEURS.map((c) => {
                        const isSelected = form.couleurs.some(
                          (x) => x.nom === c.nom,
                        );
                        return (
                          <button
                            key={c.nom}
                            type="button"
                            onClick={() => toggleCouleur(c)}
                            className="flex items-center gap-2 px-3 py-2 rounded-xl text-sm transition"
                            style={isSelected
                              ? { border: "1.5px solid #7c3aed", background: "#f5f0ff" }
                              : { border: "1.5px solid #e9d5ff", background: "white" }}
                          >
                            <span
                              className="w-5 h-5 rounded-full border border-gray-300 flex-shrink-0"
                              style={{ backgroundColor: c.hex }}
                            />
                            <span style={{ color: isSelected ? "#7c3aed" : "#6b7280", fontWeight: isSelected ? 600 : 400 }}>
                              {c.nom}
                            </span>
                            {isSelected && (
                              <svg width="12" height="12" fill="none" viewBox="0 0 24 24" stroke="#7c3aed" strokeWidth={3}>
                                <polyline points="20 6 9 17 4 12" />
                              </svg>
                            )}
                          </button>
                        );
                      })}
                    </div>
                    {form.couleurs.length > 0 && (
                      <div className="flex items-center gap-2 mt-2">
                        <span className="text-xs text-purple-600">
                          ✓ {form.couleurs.length} couleur(s) :
                        </span>
                        {form.couleurs.map((c) => (
                          <span
                            key={c.nom}
                            className="w-4 h-4 rounded-full border border-gray-300"
                            style={{ backgroundColor: c.hex }}
                            title={c.nom}
                          />
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* ─── Onglet Images ─── */}
              {activeTab === "images" && (
                <div className="space-y-5">
                  {[
                    { key: "imageUrl",  label: "Image principale *", required: true,  uploadKey: "img1" },
                    { key: "imageUrl2", label: "Image 2 (optionnelle)", required: false, uploadKey: "img2" },
                    { key: "imageUrl3", label: "Image 3 (optionnelle)", required: false, uploadKey: "img3" },
                  ].map(({ key, label, required, uploadKey }) => (
                    <div key={key}>
                      <label className="text-sm font-medium text-gray-700 mb-2 block">{label}</label>
                      <div className="flex gap-3 items-start">
                        {/* Upload fichier */}
                        <label className={`flex-1 flex flex-col items-center justify-center h-28 border-2 border-dashed rounded-xl cursor-pointer transition
                          ${uploading[uploadKey] ? "border-purple-300 bg-purple-50" : "border-gray-200 hover:border-purple-400 hover:bg-purple-50"}`}>
                          <input
                            type="file"
                            accept="image/*"
                            className="hidden"
                            onChange={async (e) => {
                              const file = e.target.files?.[0];
                              if (!file) return;
                              setUploading((u) => ({ ...u, [uploadKey]: true }));
                              try {
                                const url = await uploadImage(file);
                                setForm((f) => ({ ...f, [key]: url }));
                              } catch (err) {
                                alert("Erreur upload : " + err.message);
                              } finally {
                                setUploading((u) => ({ ...u, [uploadKey]: false }));
                              }
                            }}
                          />
                          {uploading[uploadKey] ? (
                            <div className="text-purple-600 text-sm font-medium animate-pulse">Envoi en cours...</div>
                          ) : (
                            <>
                              <span className="text-2xl mb-1">📁</span>
                              <span className="text-xs text-gray-500">Cliquer pour uploader</span>
                            </>
                          )}
                        </label>

                        {/* Aperçu */}
                        {form[key] ? (
                          <div className="relative">
                            <img
                              src={form[key]}
                              alt="preview"
                              className="h-28 w-28 rounded-xl object-cover border border-gray-200"
                            />
                            <button
                              type="button"
                              onClick={() => setForm((f) => ({ ...f, [key]: "" }))}
                              className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-5 h-5 text-xs flex items-center justify-center"
                            >✕</button>
                          </div>
                        ) : (
                          <div className="h-28 w-28 rounded-xl border border-dashed border-gray-200 flex items-center justify-center text-gray-300 text-3xl">🖼️</div>
                        )}
                      </div>
                      {required && !form[key] && (
                        <p className="text-xs text-orange-500 mt-1">⚠️ Image principale requise</p>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Boutons */}
            <div className="px-6 py-4 flex items-center justify-between" style={{ borderTop: "1px solid #f0f0f5" }}>
              <div className="flex gap-2">
                {["infos", "prix", "stock", "images"].map(
                  (tab, i, arr) =>
                    activeTab === tab &&
                    i < arr.length - 1 && (
                      <button
                        key="next"
                        type="button"
                        onClick={() => setActiveTab(arr[i + 1])}
                        className="px-5 py-2 rounded-xl text-sm font-medium transition"
                        style={{ background: "#f5f0ff", color: "#7c3aed" }}
                      >
                        Suivant →
                      </button>
                    ),
                )}
              </div>
              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={handleCancel}
                  className="px-5 py-2 rounded-xl text-sm font-medium transition"
                  style={{ background: "#f5f5f8", color: "#6b7280", border: "1.5px solid #f0f0f5" }}
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  className="px-6 py-2 rounded-xl text-sm font-semibold text-white transition"
                  style={{ background: "linear-gradient(135deg,#7c3aed,#4f46e5)", boxShadow: "0 4px 12px rgba(124,58,237,0.3)" }}
                  onMouseEnter={(e) => (e.currentTarget.style.opacity = "0.9")}
                  onMouseLeave={(e) => (e.currentTarget.style.opacity = "1")}
                >
                  {editArticle ? "Modifier" : "Ajouter l'article"}
                </button>
              </div>
            </div>
          </form>
        </div>
      )}

      {/* Liste des articles */}
      {loading ? (
        <div className="text-center py-12 text-gray-400">Chargement...</div>
      ) : articles.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center" style={{ border: "1px solid #f0f0f5", boxShadow: "0 2px 8px rgba(0,0,0,0.04)" }}>
          <div className="w-14 h-14 rounded-2xl flex items-center justify-center mx-auto mb-3" style={{ background: "#f5f0ff" }}>
            <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="#7c3aed" strokeWidth={2}>
              <path strokeLinecap="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
            </svg>
          </div>
          <p className="text-gray-400 text-sm font-medium">Aucun article pour l'instant.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {articles.map((article) => (
            <div
              key={article.id}
              className="bg-white rounded-2xl overflow-hidden transition"
              style={{ border: "1px solid #f0f0f5", boxShadow: "0 2px 8px rgba(0,0,0,0.04)" }}
              onMouseEnter={(e) => (e.currentTarget.style.boxShadow = "0 8px 24px rgba(124,58,237,0.1)")}
              onMouseLeave={(e) => (e.currentTarget.style.boxShadow = "0 2px 8px rgba(0,0,0,0.04)")}
            >
              {/* Image */}
              <div className="relative h-44" style={{ background: "#f5f0ff" }}>
                {article.imageUrl ? (
                  <img
                    src={article.imageUrl}
                    alt={article.nom}
                    className="h-full w-full object-cover"
                  />
                ) : (
                  <div className="h-full flex items-center justify-center">
                    <svg width="40" height="40" fill="none" viewBox="0 0 24 24" stroke="#c4b5fd" strokeWidth={1.5}>
                      <path strokeLinecap="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                    </svg>
                  </div>
                )}

                {/* Badges */}
                <div className="absolute top-2 left-2 flex flex-col gap-1">
                  {article.promo && article.pourcentagePromo && (
                    <span className="text-white text-xs font-bold px-2 py-0.5 rounded-full" style={{ background: "#ef4444" }}>
                      -{article.pourcentagePromo}%
                    </span>
                  )}
                  {article.nouveaute && (
                    <span className="text-white text-xs font-bold px-2 py-0.5 rounded-full" style={{ background: "#10b981" }}>
                      NEW
                    </span>
                  )}
                  {!article.disponible && (
                    <span className="text-white text-xs font-bold px-2 py-0.5 rounded-full" style={{ background: "#9ca3af" }}>
                      Indisponible
                    </span>
                  )}
                </div>
              </div>

              {/* Infos */}
              <div className="p-4">
                <h3 className="font-semibold text-gray-800 text-sm leading-tight mb-0.5">
                  {article.nom}
                </h3>

                {article.marque && (
                  <p className="text-xs text-gray-400 mb-2">{article.marque}</p>
                )}

                <span className="inline-block text-xs px-2 py-0.5 rounded-full mb-2 font-medium" style={{ background: "#f5f0ff", color: "#7c3aed" }}>
                  {article.categorie}
                </span>

                {/* Prix */}
                <div className="flex items-center gap-2 mb-2">
                  {article.promo && article.prixPromo ? (
                    <>
                      <span className="font-bold text-sm" style={{ color: "#ef4444" }}>
                        {article.prixPromo} DT
                      </span>
                      <span className="text-xs text-gray-400 line-through">
                        {article.prix} DT
                      </span>
                    </>
                  ) : (
                    <span className="font-bold text-sm" style={{ color: "#7c3aed" }}>
                      {article.prix} DT
                    </span>
                  )}
                </div>

                {/* Stock */}
                <div className="mb-2">
                  <span
                    className="text-xs font-medium"
                    style={{
                      color: article.stock > 10 ? "#059669"
                        : article.stock > 0 ? "#d97706"
                        : "#dc2626"
                    }}
                  >
                    {article.stock > 0 ? `Stock: ${article.stock}` : "Rupture de stock"}
                  </span>
                </div>

                {/* Tailles */}
                {article.tailles && article.tailles.length > 0 && (
                  <div className="flex flex-wrap gap-1 mb-2">
                    {article.tailles.map((t) => (
                      <span
                        key={t}
                        className="text-xs px-1.5 py-0.5 rounded"
                        style={{ background: "#f5f0ff", color: "#7c3aed", border: "1px solid #e9d5ff" }}
                      >
                        {t}
                      </span>
                    ))}
                  </div>
                )}

                {/* Couleurs */}
                {article.couleurs && article.couleurs.length > 0 && (
                  <div className="flex gap-1 mb-3">
                    {article.couleurs.map((c) => (
                      <span
                        key={c.nom}
                        className="w-4 h-4 rounded-full border border-gray-200"
                        style={{ backgroundColor: c.hex }}
                        title={c.nom}
                      />
                    ))}
                  </div>
                )}

                {/* Actions */}
                <div className="flex gap-2">
                  <button
                    onClick={() => handleEdit(article)}
                    className="flex-1 py-1.5 rounded-xl text-xs font-medium transition"
                    style={{ background: "#f5f0ff", color: "#7c3aed", border: "1.5px solid #e9d5ff" }}
                    onMouseEnter={(e) => (e.currentTarget.style.background = "#ede9fe")}
                    onMouseLeave={(e) => (e.currentTarget.style.background = "#f5f0ff")}
                  >
                    Modifier
                  </button>
                  <button
                    onClick={() => handleDelete(article.id)}
                    className="flex-1 py-1.5 rounded-xl text-xs font-medium transition"
                    style={{ background: "#fff1f2", color: "#e11d48", border: "1.5px solid #fecdd3" }}
                    onMouseEnter={(e) => (e.currentTarget.style.background = "#ffe4e6")}
                    onMouseLeave={(e) => (e.currentTarget.style.background = "#fff1f2")}
                  >
                    Supprimer
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
