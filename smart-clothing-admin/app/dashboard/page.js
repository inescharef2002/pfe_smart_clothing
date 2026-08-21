"use client";

import { useState, useEffect } from "react";
import { collection, getDocs } from "firebase/firestore";
import { db } from "@/lib/firebase";

export default function DashboardPage() {
  const [stats, setStats] = useState({ users: 0, articles: 0, commandes: 0, totalAnalyses: 0 });
  const [loading, setLoading] = useState(true);
  const [commandesRecentes, setCommandesRecentes] = useState([]);

  useEffect(() => { fetchStats(); }, []);

  const fetchStats = async () => {
    try {
      const [usersSnap, articlesSnap, commandesSnap] = await Promise.all([
        getDocs(collection(db, "users")),
        getDocs(collection(db, "articles")),
        getDocs(collection(db, "commandes")),
      ]);
      const commandesData = commandesSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
      let totalAnalyses = 0;
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_FASTAPI_URL || "http://localhost:8000"}/api/admin/stats`);
        if (res.ok) { const d = await res.json(); totalAnalyses = d.total_analyses || 0; }
      } catch { /* backend offline */ }
      setStats({ users: usersSnap.size, articles: articlesSnap.size, commandes: commandesSnap.size, totalAnalyses });
      setCommandesRecentes(
        commandesData
          .sort((a, b) => {
            const dA = a.createdAt?.toDate ? a.createdAt.toDate() : new Date(0);
            const dB = b.createdAt?.toDate ? b.createdAt.toDate() : new Date(0);
            return dB - dA;
          })
          .slice(0, 6)
      );
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const statCards = [
    {
      title: "Utilisateurs",
      value: stats.users,
      sub: "comptes enregistrés",
      gradient: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
      shadow: "rgba(102,126,234,0.35)",
      sparkline: [40, 55, 45, 65, 58, 72, 80],
      icon: (
        <svg width="22" height="22" fill="none" viewBox="0 0 24 24" stroke="white" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
          <circle cx="9" cy="7" r="4" />
          <path strokeLinecap="round" strokeLinejoin="round" d="M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" />
        </svg>
      ),
    },
    {
      title: "Articles",
      value: stats.articles,
      sub: "dans le catalogue",
      gradient: "linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)",
      shadow: "rgba(79,172,254,0.35)",
      sparkline: [30, 38, 50, 44, 60, 55, 70],
      icon: (
        <svg width="22" height="22" fill="none" viewBox="0 0 24 24" stroke="white" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
        </svg>
      ),
    },
    {
      title: "Commandes",
      value: stats.commandes,
      sub: "commandes totales",
      gradient: "linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)",
      shadow: "rgba(67,233,123,0.35)",
      sparkline: [20, 35, 28, 45, 40, 60, 55],
      icon: (
        <svg width="22" height="22" fill="none" viewBox="0 0 24 24" stroke="white" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" />
          <line x1="3" y1="6" x2="21" y2="6" />
          <path strokeLinecap="round" strokeLinejoin="round" d="M16 10a4 4 0 0 1-8 0" />
        </svg>
      ),
    },
    {
      title: "Analyses IA",
      value: stats.totalAnalyses,
      sub: "vêtements analysés",
      gradient: "linear-gradient(135deg, #fa709a 0%, #fee140 100%)",
      shadow: "rgba(250,112,154,0.35)",
      sparkline: [10, 25, 20, 40, 35, 55, 65],
      icon: (
        <svg width="22" height="22" fill="none" viewBox="0 0 24 24" stroke="white" strokeWidth={2}>
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
        </svg>
      ),
    },
  ];

  const statutConfig = {
    "En attente": { bg: "#fef3c7", text: "#d97706", dot: "#f59e0b" },
    Confirmée:    { bg: "#dbeafe", text: "#1d4ed8", dot: "#3b82f6" },
    Expédiée:     { bg: "#ede9fe", text: "#6d28d9", dot: "#7c3aed" },
    Livrée:       { bg: "#d1fae5", text: "#065f46", dot: "#10b981" },
    Annulée:      { bg: "#fee2e2", text: "#b91c1c", dot: "#ef4444" },
  };

  return (
    <div>
      {/* Welcome banner */}
      <div
        className="rounded-2xl p-6 mb-6 flex items-center justify-between"
        style={{
          background: "linear-gradient(135deg, #1a1f36 0%, #2d1b69 50%, #4c1d95 100%)",
          boxShadow: "0 8px 32px rgba(124,58,237,0.25)",
        }}
      >
        <div>
          <h1 className="text-white text-xl font-bold mb-1">Bonjour, Administrateur 👋</h1>
          <p style={{ color: "#c4b5fd" }} className="text-sm">
            Voici un aperçu en temps réel de votre application.
          </p>
        </div>
        <button
          onClick={fetchStats}
          className="hidden md:flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium text-white transition-all"
          style={{ background: "rgba(255,255,255,0.12)", border: "1px solid rgba(255,255,255,0.18)" }}
          onMouseEnter={(e) => (e.currentTarget.style.background = "rgba(255,255,255,0.2)")}
          onMouseLeave={(e) => (e.currentTarget.style.background = "rgba(255,255,255,0.12)")}
        >
          <svg width="14" height="14" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <polyline points="23 4 23 10 17 10" />
            <polyline points="1 20 1 14 7 14" />
            <path strokeLinecap="round" d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" />
          </svg>
          Actualiser
        </button>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5 mb-6">
        {loading
          ? [...Array(4)].map((_, i) => (
              <div key={i} className="bg-white rounded-2xl p-6 animate-pulse">
                <div className="h-3 bg-gray-100 rounded w-20 mb-3" />
                <div className="h-8 bg-gray-100 rounded w-14 mb-6" />
                <div className="h-2 bg-gray-100 rounded w-28" />
              </div>
            ))
          : statCards.map((card) => <StatCard key={card.title} {...card} />)}
      </div>

      {/* Bottom row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Recent orders */}
        <div
          className="lg:col-span-2 bg-white rounded-2xl overflow-hidden"
          style={{ border: "1px solid #f0f0f5", boxShadow: "0 2px 12px rgba(0,0,0,0.04)" }}
        >
          <div
            className="flex items-center justify-between px-6 py-4"
            style={{ borderBottom: "1px solid #f5f5fa" }}
          >
            <div className="flex items-center gap-2">
              <div className="w-2 h-5 rounded-full" style={{ background: "linear-gradient(180deg,#7c3aed,#4f46e5)" }} />
              <h2 className="text-sm font-semibold text-gray-700">Commandes récentes</h2>
            </div>
            <a
              href="/dashboard/commandes"
              className="text-xs font-semibold px-3 py-1.5 rounded-lg transition-colors"
              style={{ color: "#7c3aed", background: "#f5f0ff" }}
            >
              Voir tout →
            </a>
          </div>

          {loading ? (
            <div className="p-6 space-y-4">
              {[...Array(4)].map((_, i) => (
                <div key={i} className="flex items-center gap-4 animate-pulse">
                  <div className="w-9 h-9 rounded-xl bg-gray-100" />
                  <div className="flex-1">
                    <div className="h-3 bg-gray-100 rounded w-32 mb-2" />
                    <div className="h-2.5 bg-gray-100 rounded w-48" />
                  </div>
                  <div className="h-6 bg-gray-100 rounded-full w-20" />
                </div>
              ))}
            </div>
          ) : commandesRecentes.length === 0 ? (
            <div className="py-16 text-center">
              <div
                className="w-14 h-14 rounded-2xl flex items-center justify-center mx-auto mb-3"
                style={{ background: "#f5f0ff" }}
              >
                <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="#7c3aed" strokeWidth={2}>
                  <path strokeLinecap="round" d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" />
                  <line x1="3" y1="6" x2="21" y2="6" />
                </svg>
              </div>
              <p className="text-sm text-gray-400 font-medium">Aucune commande pour l&apos;instant</p>
            </div>
          ) : (
            <div>
              {commandesRecentes.map((c, idx) => {
                const cfg = statutConfig[c.statut] || { bg: "#f3f4f6", text: "#6b7280", dot: "#9ca3af" };
                return (
                  <div
                    key={c.id}
                    className="flex items-center gap-4 px-6 py-3.5 transition-colors"
                    style={{
                      borderBottom: idx < commandesRecentes.length - 1 ? "1px solid #f9f9fb" : "none",
                    }}
                    onMouseEnter={(e) => (e.currentTarget.style.background = "#fafafa")}
                    onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
                  >
                    <div
                      className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
                      style={{ background: "#f5f0ff" }}
                    >
                      <svg width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="#7c3aed" strokeWidth={2}>
                        <path strokeLinecap="round" d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" />
                        <line x1="3" y1="6" x2="21" y2="6" />
                      </svg>
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold text-gray-700">
                        #{c.id.slice(0, 8).toUpperCase()}
                      </p>
                      <p className="text-xs text-gray-400 truncate">{c.userEmail || "Client inconnu"}</p>
                    </div>
                    <span className="text-sm font-bold" style={{ color: "#7c3aed" }}>
                      {c.total || 0} DT
                    </span>
                    <span
                      className="flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full whitespace-nowrap"
                      style={{ background: cfg.bg, color: cfg.text }}
                    >
                      <span className="w-1.5 h-1.5 rounded-full" style={{ background: cfg.dot }} />
                      {c.statut || "En attente"}
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Right column */}
        <div className="flex flex-col gap-5">
          {/* Order status summary */}
          <div
            className="bg-white rounded-2xl p-5"
            style={{ border: "1px solid #f0f0f5", boxShadow: "0 2px 12px rgba(0,0,0,0.04)" }}
          >
            <div className="flex items-center gap-2 mb-4">
              <div className="w-2 h-5 rounded-full" style={{ background: "linear-gradient(180deg,#10b981,#34d399)" }} />
              <h3 className="text-sm font-semibold text-gray-700">Statuts commandes</h3>
            </div>
            {Object.entries(statutConfig).map(([label, cfg]) => {
              const count = commandesRecentes.filter(
                (c) => (c.statut || "En attente") === label
              ).length;
              return (
                <div key={label} className="flex items-center justify-between py-2">
                  <div className="flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full" style={{ background: cfg.dot }} />
                    <span className="text-xs text-gray-600">{label}</span>
                  </div>
                  <span
                    className="text-xs font-bold px-2 py-0.5 rounded-full"
                    style={{ background: cfg.bg, color: cfg.text }}
                  >
                    {count}
                  </span>
                </div>
              );
            })}
          </div>

          {/* System status */}
          <div
            className="rounded-2xl p-5"
            style={{ background: "linear-gradient(135deg, #1a1f36 0%, #2d1b69 100%)" }}
          >
            <div className="flex items-center justify-between mb-3">
              <p className="text-white text-sm font-semibold">Smart Clothing IA</p>
              <div className="flex items-center gap-1.5">
                <div className="w-2 h-2 rounded-full bg-green-400 animate-pulse" />
                <span className="text-green-300 text-xs">En ligne</span>
              </div>
            </div>
            <p style={{ color: "#a78bfa" }} className="text-xs mb-4">
              Moteur d&apos;analyse opérationnel
            </p>
            <div className="grid grid-cols-2 gap-2">
              {[
                { label: "Articles", val: stats.articles, icon: "👗" },
                { label: "Utilisateurs", val: stats.users, icon: "👥" },
                { label: "Commandes", val: stats.commandes, icon: "📦" },
                { label: "Analyses", val: stats.totalAnalyses, icon: "🤖" },
              ].map((item) => (
                <div
                  key={item.label}
                  className="rounded-xl px-3 py-2.5"
                  style={{ background: "rgba(255,255,255,0.07)" }}
                >
                  <div className="text-white text-base font-bold">{item.val}</div>
                  <div style={{ color: "#c4b5fd" }} className="text-xs mt-0.5">
                    {item.icon} {item.label}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ── Stat Card with SVG sparkline ──────────────────────────────────────────────
function StatCard({ title, value, sub, gradient, shadow, icon, sparkline }) {
  const max = Math.max(...sparkline);
  const min = Math.min(...sparkline);
  const range = max - min || 1;
  const W = 80, H = 36;
  const pts = sparkline
    .map((v, i) => {
      const x = (i / (sparkline.length - 1)) * W;
      const y = H - ((v - min) / range) * H * 0.75 - H * 0.1;
      return `${x.toFixed(1)},${y.toFixed(1)}`;
    })
    .join(" ");

  return (
    <div
      className="rounded-2xl p-5 text-white relative overflow-hidden cursor-default"
      style={{ background: gradient, boxShadow: `0 8px 24px ${shadow}` }}
    >
      {/* Decorative circles */}
      <div className="absolute -right-5 -top-5 w-24 h-24 rounded-full" style={{ background: "rgba(255,255,255,0.1)" }} />
      <div className="absolute right-3 top-10 w-14 h-14 rounded-full" style={{ background: "rgba(255,255,255,0.06)" }} />

      <div className="flex items-start justify-between mb-2 relative">
        <p className="text-xs font-semibold opacity-80 uppercase tracking-wider">{title}</p>
        <div className="w-9 h-9 rounded-xl flex items-center justify-center" style={{ background: "rgba(255,255,255,0.2)" }}>
          {icon}
        </div>
      </div>

      <p className="text-3xl font-bold relative mb-2">{value.toLocaleString()}</p>

      {/* Sparkline */}
      <svg width={W} height={H} viewBox={`0 0 ${W} ${H}`} className="opacity-60 mb-1">
        <polyline points={pts} fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      </svg>

      <p className="text-xs opacity-70 relative">{sub}</p>
    </div>
  );
}
