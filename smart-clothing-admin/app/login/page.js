"use client";

import { useState } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "@/lib/firebase";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPass, setShowPass] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const cred = await signInWithEmailAndPassword(auth, email, password);

      // ✅ Rafraîchit le token avant d'accéder à Firestore
      await cred.user.getIdToken(true);

      const snap = await getDoc(doc(db, "users", cred.user.uid));
      if (!snap.exists() || snap.data().role !== "admin") {
        await auth.signOut();
        setError(
          !snap.exists()
            ? "Compte introuvable dans Firestore."
            : 'Accès refusé : rôle actuel = "' + snap.data().role + '"',
        );
        setLoading(false);
        return;
      }
      router.push("/dashboard");
    } catch (err) {
      const msg = err?.code || err?.message || "inconnue";
      const authErrors = [
        "auth/user-not-found",
        "auth/wrong-password",
        "auth/invalid-credential",
        "auth/invalid-email",
      ];
      setError(
        authErrors.includes(err?.code)
          ? "Email ou mot de passe incorrect."
          : "Erreur : " + msg,
      );
      setLoading(false);
    }
  };

  return (
    <div
      className="min-h-screen flex"
      style={{
        background:
          "linear-gradient(135deg, #1a1f36 0%, #2d1b69 50%, #4c1d95 100%)",
      }}
    >
      <div className="hidden lg:flex flex-col justify-between w-1/2 p-12 relative overflow-hidden">
        <div
          className="absolute -top-20 -left-20 w-80 h-80 rounded-full"
          style={{ background: "rgba(124,58,237,0.15)" }}
        />
        <div
          className="absolute bottom-10 right-0 w-64 h-64 rounded-full"
          style={{ background: "rgba(79,70,229,0.12)" }}
        />
        <div
          className="absolute top-1/2 left-1/3 w-40 h-40 rounded-full"
          style={{ background: "rgba(255,255,255,0.04)" }}
        />

        <div className="flex items-center gap-3 relative">
          <div
            className="w-10 h-10 rounded-xl flex items-center justify-center"
            style={{
              background: "rgba(255,255,255,0.15)",
              border: "1px solid rgba(255,255,255,0.2)",
            }}
          >
            <svg
              width="20"
              height="20"
              fill="none"
              viewBox="0 0 24 24"
              stroke="white"
              strokeWidth={2}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"
              />
            </svg>
          </div>
          <span className="text-white font-bold text-lg">Smart Clothing</span>
        </div>

        <div className="relative">
          <h2 className="text-white text-4xl font-bold leading-tight mb-4">
            Panneau
            <br />
            d&apos;administration
          </h2>
          <p
            style={{ color: "#c4b5fd" }}
            className="text-base leading-relaxed mb-8"
          >
            Gérez vos utilisateurs, articles et commandes.
            <br />
            Surveillez les performances du moteur IA.
          </p>
          <div className="flex flex-col gap-3">
            {[
              { icon: "👥", text: "Gestion des utilisateurs" },
              { icon: "👗", text: "Catalogue articles" },
              { icon: "📦", text: "Suivi des commandes" },
              { icon: "🤖", text: "Performances IA" },
            ].map((item) => (
              <div key={item.text} className="flex items-center gap-3">
                <div
                  className="w-8 h-8 rounded-lg flex items-center justify-center text-sm"
                  style={{ background: "rgba(255,255,255,0.1)" }}
                >
                  {item.icon}
                </div>
                <span
                  className="text-sm"
                  style={{ color: "rgba(255,255,255,0.75)" }}
                >
                  {item.text}
                </span>
              </div>
            ))}
          </div>
        </div>

        <p
          className="text-xs relative"
          style={{ color: "rgba(255,255,255,0.3)" }}
        >
          © 2025 Smart Clothing Advisor
        </p>
      </div>

      <div className="flex-1 flex items-center justify-center p-6 lg:p-12">
        <div
          className="w-full max-w-md rounded-3xl p-8 lg:p-10"
          style={{
            background: "rgba(255,255,255,0.97)",
            boxShadow: "0 25px 60px rgba(0,0,0,0.35)",
          }}
        >
          <div className="flex lg:hidden items-center gap-2 mb-8">
            <div
              className="w-8 h-8 rounded-lg flex items-center justify-center"
              style={{ background: "linear-gradient(135deg,#7c3aed,#4f46e5)" }}
            >
              <svg
                width="16"
                height="16"
                fill="none"
                viewBox="0 0 24 24"
                stroke="white"
                strokeWidth={2}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"
                />
              </svg>
            </div>
            <span className="font-bold text-gray-800">Smart Clothing</span>
          </div>

          <h1 className="text-2xl font-bold text-gray-800 mb-1">
            Connexion Admin
          </h1>
          <p className="text-sm text-gray-400 mb-8">
            Entrez vos identifiants pour accéder au panneau.
          </p>

          <form onSubmit={handleLogin} className="flex flex-col gap-5">
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider block mb-2">
                Adresse email
              </label>
              <div className="relative">
                <div
                  className="absolute left-4 top-1/2 -translate-y-1/2"
                  style={{ color: "#7c3aed" }}
                >
                  <svg
                    width="17"
                    height="17"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    strokeWidth={2}
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"
                    />
                    <polyline points="22,6 12,13 2,6" />
                  </svg>
                </div>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@smartclothing.com"
                  required
                  className="w-full pl-11 pr-4 py-3 text-sm rounded-xl outline-none transition-all"
                  style={{
                    background: "#f5f0ff",
                    border: "1.5px solid #e9d5ff",
                    color: "#1a1a2e",
                  }}
                  onFocus={(e) =>
                    (e.target.style.border = "1.5px solid #7c3aed")
                  }
                  onBlur={(e) =>
                    (e.target.style.border = "1.5px solid #e9d5ff")
                  }
                />
              </div>
            </div>

            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider block mb-2">
                Mot de passe
              </label>
              <div className="relative">
                <div
                  className="absolute left-4 top-1/2 -translate-y-1/2"
                  style={{ color: "#7c3aed" }}
                >
                  <svg
                    width="17"
                    height="17"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    strokeWidth={2}
                  >
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                    <path strokeLinecap="round" d="M7 11V7a5 5 0 0 1 10 0v4" />
                  </svg>
                </div>
                <input
                  type={showPass ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  className="w-full pl-11 pr-11 py-3 text-sm rounded-xl outline-none transition-all"
                  style={{
                    background: "#f5f0ff",
                    border: "1.5px solid #e9d5ff",
                    color: "#1a1a2e",
                  }}
                  onFocus={(e) =>
                    (e.target.style.border = "1.5px solid #7c3aed")
                  }
                  onBlur={(e) =>
                    (e.target.style.border = "1.5px solid #e9d5ff")
                  }
                />
                <button
                  type="button"
                  onClick={() => setShowPass(!showPass)}
                  className="absolute right-4 top-1/2 -translate-y-1/2"
                  style={{ color: "#9ca3af" }}
                >
                  {showPass ? (
                    <svg
                      width="17"
                      height="17"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                      strokeWidth={2}
                    >
                      <path
                        strokeLinecap="round"
                        d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"
                      />
                      <path
                        strokeLinecap="round"
                        d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"
                      />
                      <line x1="1" y1="1" x2="23" y2="23" />
                    </svg>
                  ) : (
                    <svg
                      width="17"
                      height="17"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                      strokeWidth={2}
                    >
                      <path
                        strokeLinecap="round"
                        d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"
                      />
                      <circle cx="12" cy="12" r="3" />
                    </svg>
                  )}
                </button>
              </div>
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
                  width="15"
                  height="15"
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

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3.5 rounded-xl text-white font-semibold text-sm transition-all"
              style={{
                background: loading
                  ? "#9ca3af"
                  : "linear-gradient(135deg, #7c3aed, #4f46e5)",
                boxShadow: loading ? "none" : "0 8px 20px rgba(124,58,237,0.4)",
              }}
              onMouseEnter={(e) => {
                if (!loading) e.currentTarget.style.opacity = "0.9";
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.opacity = "1";
              }}
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  Connexion en cours…
                </span>
              ) : (
                "Se connecter"
              )}
            </button>
          </form>

          <p className="text-center text-xs text-gray-400 mt-6">
            Accès réservé aux administrateurs autorisés
          </p>
        </div>
      </div>
    </div>
  );
}
