"use client";

import { usePathname } from "next/navigation";
import { auth } from "@/lib/firebase";
import { useEffect, useState } from "react";

const pageTitles = {
  "/dashboard": { title: "Dashboard", subtitle: "Vue d'ensemble de l'application" },
  "/dashboard/articles": { title: "Articles", subtitle: "Gérer le catalogue marketplace" },
  "/dashboard/users": { title: "Utilisateurs", subtitle: "Gérer les comptes utilisateurs" },
  "/dashboard/commandes": { title: "Commandes", subtitle: "Suivre et gérer les commandes" },
  "/dashboard/performances-ia": { title: "Performances IA", subtitle: "Métriques du moteur d'analyse" },
};

export default function TopBar() {
  const pathname = usePathname();
  const info = pageTitles[pathname] || { title: "Dashboard", subtitle: "" };
  const [userEmail, setUserEmail] = useState("");
  const [time, setTime] = useState("");

  useEffect(() => {
    const user = auth.currentUser;
    if (user) setUserEmail(user.email || "Admin");

    const tick = () => {
      const now = new Date();
      setTime(now.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" }));
    };
    tick();
    const id = setInterval(tick, 60000);
    return () => clearInterval(id);
  }, []);

  const initials = userEmail
    ? userEmail.slice(0, 2).toUpperCase()
    : "AD";

  return (
    <header
      className="flex items-center justify-between px-8 py-4"
      style={{
        background: "#ffffff",
        borderBottom: "1px solid #f0f0f5",
        boxShadow: "0 2px 12px rgba(0,0,0,0.04)",
      }}
    >
      {/* Left: page title */}
      <div>
        <h2 className="text-xl font-bold text-gray-800">{info.title}</h2>
        <p className="text-xs text-gray-400 mt-0.5">{info.subtitle}</p>
      </div>

      {/* Right: actions */}
      <div className="flex items-center gap-4">
        {/* Clock */}
        <div className="hidden md:flex items-center gap-2 text-xs text-gray-400">
          <svg width="14" height="14" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <circle cx="12" cy="12" r="10" />
            <polyline points="12 6 12 12 16 14" />
          </svg>
          {time}
        </div>

        {/* Notification bell */}
        <button
          className="relative w-9 h-9 rounded-xl flex items-center justify-center transition-colors"
          style={{ background: "#f5f0ff", color: "#7c3aed" }}
          onMouseEnter={(e) => (e.currentTarget.style.background = "#ede9fe")}
          onMouseLeave={(e) => (e.currentTarget.style.background = "#f5f0ff")}
        >
          <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
            <path strokeLinecap="round" strokeLinejoin="round" d="M13.73 21a2 2 0 0 1-3.46 0" />
          </svg>
          <span
            className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full"
            style={{ background: "#7c3aed" }}
          />
        </button>

        {/* Avatar + name */}
        <div className="flex items-center gap-3">
          <div
            className="w-9 h-9 rounded-xl flex items-center justify-center text-sm font-bold text-white"
            style={{ background: "linear-gradient(135deg, #7c3aed, #4f46e5)" }}
          >
            {initials}
          </div>
          <div className="hidden md:block">
            <div className="text-sm font-semibold text-gray-700 leading-tight">
              {userEmail.split("@")[0] || "Admin"}
            </div>
            <div className="text-xs text-gray-400">Administrateur</div>
          </div>
        </div>
      </div>
    </header>
  );
}
