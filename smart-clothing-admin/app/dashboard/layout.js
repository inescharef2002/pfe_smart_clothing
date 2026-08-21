"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { onAuthStateChanged } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "@/lib/firebase";
import Sidebar from "@/components/Sidebar";
import TopBar from "@/components/TopBar";

export default function DashboardLayout({ children }) {
  const router = useRouter();
  const [checking, setChecking] = useState(true);
  const [authorized, setAuthorized] = useState(false);
  const [authError, setAuthError] = useState("");

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (user) => {
      if (!user) {
        setChecking(false);
        router.replace("/login");
        return;
      }
      try {
        const snap = await getDoc(doc(db, "users", user.uid));
        if (snap.exists() && snap.data().role === "admin") {
          setAuthorized(true);
        } else {
          await auth.signOut();
          setAuthError(
            !snap.exists()
              ? "Compte introuvable dans Firestore (UID: " + user.uid + ")"
              : "Rôle insuffisant — actuel : \"" + snap.data().role + "\""
          );
        }
      } catch (err) {
        console.error("Layout auth error:", err);
        setAuthError("Erreur Firestore : " + (err?.code || err?.message || "inconnue"));
      } finally {
        setChecking(false);
      }
    });
    return () => unsub();
  }, [router]);

  if (checking) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ background: "#f0f2f7" }}>
        <div className="flex flex-col items-center gap-4">
          <div
            className="w-12 h-12 rounded-2xl flex items-center justify-center"
            style={{ background: "linear-gradient(135deg, #7c3aed, #4f46e5)" }}
          >
            <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="white" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
            </svg>
          </div>
          <div className="w-8 h-8 border-3 border-purple-600 border-t-transparent rounded-full animate-spin" style={{ borderWidth: 3 }} />
          <p className="text-sm text-gray-400 font-medium">Vérification en cours…</p>
        </div>
      </div>
    );
  }

  if (authError) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ background: "#f0f2f7" }}>
        <div className="bg-white rounded-2xl p-8 max-w-md w-full mx-4 text-center" style={{ border: "1px solid #f0f0f5", boxShadow: "0 8px 32px rgba(0,0,0,0.08)" }}>
          <div className="w-12 h-12 rounded-2xl flex items-center justify-center mx-auto mb-4" style={{ background: "#fee2e2" }}>
            <svg width="22" height="22" fill="none" viewBox="0 0 24 24" stroke="#dc2626" strokeWidth={2}>
              <circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
          </div>
          <h2 className="text-base font-semibold text-gray-800 mb-2">Erreur d&apos;authentification</h2>
          <p className="text-sm text-red-600 mb-6 font-mono break-all">{authError}</p>
          <button
            onClick={() => { auth.signOut(); router.replace("/login"); }}
            className="px-6 py-2.5 rounded-xl text-sm font-semibold text-white"
            style={{ background: "linear-gradient(135deg,#7c3aed,#4f46e5)" }}
          >
            Retour à la connexion
          </button>
        </div>
      </div>
    );
  }

  if (!authorized) return null;

  return (
    <div className="flex min-h-screen" style={{ background: "#f0f2f7" }}>
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <TopBar />
        <main className="flex-1 p-6 overflow-auto">{children}</main>
      </div>
    </div>
  );
}
