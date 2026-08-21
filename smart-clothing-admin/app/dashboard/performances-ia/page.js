"use client";

import { useState, useEffect } from "react";

const FASTAPI_URL =
  process.env.NEXT_PUBLIC_FASTAPI_URL || "http://localhost:8000";

export default function PerformancesIAPage() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [resetting, setResetting] = useState(false);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${FASTAPI_URL}/api/admin/stats`);
      if (!res.ok) throw new Error(`Erreur serveur (${res.status})`);
      const data = await res.json();
      setStats(data);
    } catch {
      setError("Impossible de joindre le backend IA. Vérifiez que le serveur FastAPI est démarré.");
    } finally {
      setLoading(false);
    }
  };

  const handleReset = async () => {
    if (!confirm("Remettre toutes les métriques IA à zéro ? Cette action est irréversible.")) return;
    setResetting(true);
    try {
      await fetch(`${FASTAPI_URL}/api/admin/stats/reset`, { method: "DELETE" });
      await fetchStats();
    } catch {
      alert("Erreur lors de la réinitialisation.");
    } finally {
      setResetting(false);
    }
  };

  return (
    <div>
      {/* Action bar */}
      <div className="flex items-center justify-between mb-6">
        <span className="text-sm text-gray-500 font-medium">Supervision du moteur IA</span>
        <div className="flex gap-2">
          <button
            onClick={fetchStats}
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
          <button
            onClick={handleReset}
            disabled={resetting}
            className="flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-semibold transition disabled:opacity-50"
            style={{ background: "#fff1f2", color: "#e11d48" }}
            onMouseEnter={(e) => { if (!resetting) e.currentTarget.style.background = "#ffe4e6"; }}
            onMouseLeave={(e) => { e.currentTarget.style.background = "#fff1f2"; }}
          >
            {resetting ? "..." : "Réinitialiser"}
          </button>
        </div>
      </div>

      {/* États */}
      {loading && (
        <div className="text-center py-20 text-gray-400">
          <div className="w-10 h-10 border-2 border-purple-300 border-t-purple-600 rounded-full animate-spin mx-auto mb-4" />
          Chargement des métriques IA...
        </div>
      )}

      {error && (
        <div className="rounded-2xl p-6 text-center" style={{ background: "#fff1f2", border: "1px solid #fecdd3" }}>
          <p className="font-medium mb-3" style={{ color: "#e11d48" }}>{error}</p>
          <button
            onClick={fetchStats}
            className="px-6 py-2 rounded-xl text-sm font-semibold text-white transition"
            style={{ background: "linear-gradient(135deg,#7c3aed,#4f46e5)" }}
          >
            Réessayer
          </button>
        </div>
      )}

      {!loading && !error && stats && (
        <>
          {/* ── Bloc 1 : Analyses ── */}
          <SectionTitle title="Analyses de vêtements" />
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <StatCard title="Total analyses" value={stats.total_analyses} gradient="purple" sub="depuis le lancement" />
            <StatCard title="Aujourd'hui" value={stats.analyses_today} gradient="blue" sub="analyses ce jour" />
            <StatCard
              title="Confiance moy."
              value={`${((stats.avg_confidence || 0) * 100).toFixed(1)}%`}
              gradient="green"
              sub={`min ${((stats.min_confidence || 0) * 100).toFixed(0)}% · max ${((stats.max_confidence || 0) * 100).toFixed(0)}%`}
            />
            <StatCard title="Erreurs" value={stats.errors_count} gradient={stats.errors_count > 0 ? "red" : "gray"} sub="échecs d'analyse" />
          </div>

          {/* ── Bloc 2 : Moteur ── */}
          <SectionTitle title="Moteur de classification" />
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
            <EngineCard label="CNN — ONNX" count={stats.cnn_used} total={stats.cnn_used + stats.opencv_used} color="green" desc="Fashion-MNIST (confiance ≥ 60%)" />
            <EngineCard label="OpenCV" count={stats.opencv_used} total={stats.cnn_used + stats.opencv_used} color="orange" desc="Fallback / photo avec personne" />
            <div className="bg-white rounded-2xl p-5 flex flex-col justify-between" style={{ border: "1px solid #f0f0f5", boxShadow: "0 2px 8px rgba(0,0,0,0.04)" }}>
              <div className="flex items-center justify-between mb-3">
                <span className="text-gray-500 text-sm font-medium">Personnes détectées</span>
                <div className="w-9 h-9 rounded-xl" style={{ background: "linear-gradient(135deg,#667eea,#764ba2)" }} />
              </div>
              <p className="text-3xl font-bold text-gray-800 mb-1">{stats.person_detected}</p>
              <p className="text-xs text-gray-400">Recadrage vêtement automatique</p>
            </div>
          </div>

          {/* ── Bloc 3 : Distribution confiance ── */}
          <SectionTitle title="Distribution de la confiance" />
          <div className="bg-white rounded-2xl p-6 mb-8" style={{ border: "1px solid #f0f0f5", boxShadow: "0 2px 8px rgba(0,0,0,0.04)" }}>
            {stats.total_analyses === 0 ? (
              <p className="text-gray-400 text-sm text-center py-4">Aucune analyse enregistrée.</p>
            ) : (
              <div className="flex flex-col gap-4">
                <ConfBar label="Haute ≥ 80%" count={stats.confidence_high} total={stats.total_analyses} barColor="#10b981" badgeBg="#d1fae5" badgeText="#065f46" />
                <ConfBar label="Moyenne 60 – 79%" count={stats.confidence_medium} total={stats.total_analyses} barColor="#f59e0b" badgeBg="#fef3c7" badgeText="#92400e" />
                <ConfBar label="Basse < 60% (fallback)" count={stats.confidence_low} total={stats.total_analyses} barColor="#ef4444" badgeBg="#fee2e2" badgeText="#b91c1c" />
              </div>
            )}
          </div>

          {/* ── Bloc 4 : Catégories ── */}
          {Object.keys(stats.categories_distribution || {}).length > 0 && (
            <>
              <SectionTitle title="Catégories détectées" />
              <div className="bg-white rounded-2xl p-6 mb-8" style={{ border: "1px solid #f0f0f5", boxShadow: "0 2px 8px rgba(0,0,0,0.04)" }}>
                <DistributionBars data={stats.categories_distribution} total={stats.total_analyses} barColor="#7c3aed" valueColor="#7c3aed" />
              </div>
            </>
          )}

          {/* ── Bloc 5 : Suggestions ── */}
          <SectionTitle title="Suggestions de tenues" />
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
            <StatCard title="Total suggestions" value={stats.total_suggestions} gradient="indigo" sub="depuis le lancement" />
            <StatCard title="Aujourd'hui" value={stats.suggestions_today} gradient="teal" sub="suggestions ce jour" />
            <StatCard title="Météo aujourd'hui" value={stats.weather_suggestions_today} gradient="sky" sub="suggestions météo" />
          </div>

          {Object.keys(stats.occasions_distribution || {}).length > 0 && (
            <>
              <SectionTitle title="Occasions demandées" />
              <div className="bg-white rounded-2xl p-6 mb-8" style={{ border: "1px solid #f0f0f5", boxShadow: "0 2px 8px rgba(0,0,0,0.04)" }}>
                <DistributionBars data={stats.occasions_distribution} total={stats.total_suggestions} barColor="#14b8a6" valueColor="#0f766e" />
              </div>
            </>
          )}

          {/* ── Bloc 6 : Activité récente ── */}
          {(stats.recent_analyses || []).length > 0 && (
            <>
              <SectionTitle title="Activité récente" />
              <div className="bg-white rounded-2xl p-6 mb-8" style={{ border: "1px solid #f0f0f5", boxShadow: "0 2px 8px rgba(0,0,0,0.04)" }}>
                <div className="flex flex-col">
                  {stats.recent_analyses.map((item, i) => {
                    const conf = item.confidence || 0;
                    const isHigh = conf >= 0.8;
                    const isMed = conf >= 0.6;
                    const badge = isHigh
                      ? { bg: "#d1fae5", text: "#065f46" }
                      : isMed
                      ? { bg: "#fef3c7", text: "#92400e" }
                      : { bg: "#fee2e2", text: "#b91c1c" };
                    return (
                      <div
                        key={i}
                        className="flex items-center justify-between py-3"
                        style={{ borderBottom: i < stats.recent_analyses.length - 1 ? "1px solid #f9f9fb" : "none" }}
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 rounded-xl flex items-center justify-center" style={{ background: "#f5f0ff" }}>
                            <svg width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="#7c3aed" strokeWidth={2}>
                              <path strokeLinecap="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                            </svg>
                          </div>
                          <div>
                            <p className="text-sm font-medium text-gray-700">{item.categorie} · {item.couleur}</p>
                            <p className="text-xs text-gray-400">{item.moteur} · {item.time}</p>
                          </div>
                        </div>
                        <span className="text-xs px-2.5 py-1 rounded-full font-semibold" style={{ background: badge.bg, color: badge.text }}>
                          {(conf * 100).toFixed(0)}%
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>
            </>
          )}
        </>
      )}
    </div>
  );
}

/* ── Composants réutilisables ────────────────────────────────────────────── */

function SectionTitle({ title }) {
  return (
    <h2 className="text-sm font-semibold text-gray-500 mb-3 uppercase tracking-wider">
      {title}
    </h2>
  );
}

const statGradients = {
  purple:  "linear-gradient(135deg,#7c3aed,#4f46e5)",
  blue:    "linear-gradient(135deg,#4facfe,#00f2fe)",
  green:   "linear-gradient(135deg,#43e97b,#38f9d7)",
  pink:    "linear-gradient(135deg,#fa709a,#fee140)",
  indigo:  "linear-gradient(135deg,#667eea,#764ba2)",
  teal:    "linear-gradient(135deg,#11998e,#38ef7d)",
  sky:     "linear-gradient(135deg,#0ea5e9,#38bdf8)",
  red:     "linear-gradient(135deg,#ff416c,#ff4b2b)",
  gray:    "linear-gradient(135deg,#9ca3af,#6b7280)",
};

function StatCard({ title, value, gradient = "purple", sub }) {
  const bg = statGradients[gradient] || statGradients.purple;
  return (
    <div className="bg-white rounded-2xl p-5" style={{ border: "1px solid #f0f0f5", boxShadow: "0 2px 8px rgba(0,0,0,0.04)" }}>
      <div className="flex items-center justify-between mb-3">
        <span className="text-gray-500 text-sm font-medium">{title}</span>
        <div className="w-9 h-9 rounded-xl flex-shrink-0" style={{ background: bg }} />
      </div>
      <p className="text-3xl font-bold text-gray-800 mb-1">{value}</p>
      <p className="text-xs text-gray-400">{sub}</p>
    </div>
  );
}

function EngineCard({ label, count, total, color, desc }) {
  const pct = total > 0 ? Math.round((count / total) * 100) : 0;
  const isGreen = color === "green";
  return (
    <div className="bg-white rounded-2xl p-5" style={{ border: "1px solid #f0f0f5", boxShadow: "0 2px 8px rgba(0,0,0,0.04)" }}>
      <div className="flex items-center justify-between mb-2">
        <span className="text-sm font-semibold text-gray-700">{label}</span>
        <span
          className="text-xs font-bold px-2 py-1 rounded-full"
          style={isGreen
            ? { background: "#d1fae5", color: "#065f46" }
            : { background: "#fef3c7", color: "#92400e" }}
        >
          {pct}%
        </span>
      </div>
      <p className="text-3xl font-bold text-gray-800 mb-3">{count}</p>
      <div className="w-full rounded-full h-2 mb-2" style={{ background: "#f3f4f6" }}>
        <div
          className="h-2 rounded-full transition-all"
          style={{ width: `${pct}%`, background: isGreen ? "#10b981" : "#f59e0b" }}
        />
      </div>
      <p className="text-xs text-gray-400">{desc}</p>
    </div>
  );
}

function ConfBar({ label, count, total, barColor, badgeBg, badgeText }) {
  const pct = total > 0 ? (count / total) * 100 : 0;
  return (
    <div className="flex items-center gap-4">
      <span className="w-44 text-sm text-gray-500 shrink-0">{label}</span>
      <div className="flex-1 rounded-full h-2.5" style={{ background: "#f3f4f6" }}>
        <div
          className="h-2.5 rounded-full transition-all"
          style={{ width: `${pct}%`, background: barColor }}
        />
      </div>
      <span
        className="text-xs font-bold px-2 py-1 rounded-full min-w-[2.5rem] text-center"
        style={{ background: badgeBg, color: badgeText }}
      >
        {count}
      </span>
    </div>
  );
}

function DistributionBars({ data, total, barColor, valueColor }) {
  const sorted = Object.entries(data).sort((a, b) => b[1] - a[1]);
  const n = total > 0 ? total : 1;
  return (
    <div className="flex flex-col gap-3">
      {sorted.map(([label, count]) => {
        const pct = (count / n) * 100;
        return (
          <div key={label} className="flex items-center gap-4">
            <span className="w-32 text-sm text-gray-600 shrink-0">{label}</span>
            <div className="flex-1 rounded-full h-2.5" style={{ background: "#f3f4f6" }}>
              <div
                className="h-2.5 rounded-full transition-all"
                style={{ width: `${pct}%`, background: barColor }}
              />
            </div>
            <span className="text-xs font-bold min-w-[1.5rem] text-right" style={{ color: valueColor }}>
              {count}
            </span>
          </div>
        );
      })}
    </div>
  );
}
