"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { signOut } from "firebase/auth";
import { auth } from "@/lib/firebase";

const menuItems = [
  {
    href: "/dashboard",
    label: "Dashboard",
    icon: (
      <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <rect x="3" y="3" width="7" height="7" rx="1.5" />
        <rect x="14" y="3" width="7" height="7" rx="1.5" />
        <rect x="3" y="14" width="7" height="7" rx="1.5" />
        <rect x="14" y="14" width="7" height="7" rx="1.5" />
      </svg>
    ),
  },
  {
    href: "/dashboard/articles",
    label: "Articles",
    icon: (
      <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
      </svg>
    ),
  },
  {
    href: "/dashboard/users",
    label: "Utilisateurs",
    icon: (
      <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
        <circle cx="9" cy="7" r="4" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M23 21v-2a4 4 0 0 0-3-3.87" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M16 3.13a4 4 0 0 1 0 7.75" />
      </svg>
    ),
  },
  {
    href: "/dashboard/commandes",
    label: "Commandes",
    icon: (
      <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" />
        <line x1="3" y1="6" x2="21" y2="6" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M16 10a4 4 0 0 1-8 0" />
      </svg>
    ),
  },
  {
    href: "/dashboard/performances-ia",
    label: "Performances IA",
    icon: (
      <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <polygon strokeLinecap="round" strokeLinejoin="round" points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
      </svg>
    ),
  },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  const handleLogout = async () => {
    await signOut(auth);
    router.push("/login");
  };

  return (
    <aside
      className="w-64 min-h-screen flex flex-col"
      style={{
        background: "linear-gradient(180deg, #1a1f36 0%, #1e2447 100%)",
        boxShadow: "4px 0 24px rgba(0,0,0,0.18)",
      }}
    >
      {/* Logo */}
      <div className="px-6 py-6 flex items-center gap-3" style={{ borderBottom: "1px solid rgba(255,255,255,0.07)" }}>
        <div
          className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0"
          style={{ background: "linear-gradient(135deg, #7c3aed, #4f46e5)" }}
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
          </svg>
        </div>
        <div>
          <div className="text-white font-bold text-base leading-tight">Smart Clothing</div>
          <div className="text-xs font-medium" style={{ color: "#a78bfa" }}>Administration</div>
        </div>
      </div>

      {/* Section label */}
      <div className="px-6 pt-6 pb-2">
        <span className="text-xs font-semibold uppercase tracking-widest" style={{ color: "rgba(255,255,255,0.3)" }}>
          Menu principal
        </span>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 pb-4 flex flex-col gap-1">
        {menuItems.map((item) => {
          const isActive =
            item.href === "/dashboard"
              ? pathname === "/dashboard"
              : pathname.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-150 group"
              style={
                isActive
                  ? {
                      background: "linear-gradient(90deg, rgba(124,58,237,0.9), rgba(79,70,229,0.7))",
                      color: "#ffffff",
                      boxShadow: "0 4px 15px rgba(124,58,237,0.35)",
                    }
                  : { color: "rgba(255,255,255,0.55)" }
              }
              onMouseEnter={(e) => {
                if (!isActive) e.currentTarget.style.background = "rgba(255,255,255,0.07)";
                if (!isActive) e.currentTarget.style.color = "rgba(255,255,255,0.9)";
              }}
              onMouseLeave={(e) => {
                if (!isActive) e.currentTarget.style.background = "transparent";
                if (!isActive) e.currentTarget.style.color = "rgba(255,255,255,0.55)";
              }}
            >
              <span className={isActive ? "text-white" : ""} style={{ opacity: isActive ? 1 : 0.7 }}>
                {item.icon}
              </span>
              {item.label}
              {isActive && (
                <span className="ml-auto w-1.5 h-1.5 rounded-full bg-white opacity-80" />
              )}
            </Link>
          );
        })}
      </nav>

      {/* User / Logout */}
      <div className="p-4" style={{ borderTop: "1px solid rgba(255,255,255,0.07)" }}>
        <button
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-150"
          style={{ color: "rgba(255,255,255,0.45)" }}
          onMouseEnter={(e) => {
            e.currentTarget.style.background = "rgba(239,68,68,0.15)";
            e.currentTarget.style.color = "#f87171";
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.background = "transparent";
            e.currentTarget.style.color = "rgba(255,255,255,0.45)";
          }}
        >
          <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 0 1-3 3H6a3 3 0 0 1-3-3V7a3 3 0 0 1 3-3h4a3 3 0 0 1 3 3v1" />
          </svg>
          Déconnexion
        </button>
      </div>
    </aside>
  );
}
