import "./globals.css";

export const metadata = {
  title: "Smart Clothing Admin",
  description: "Dashboard Administrateur",
};

export default function RootLayout({ children }) {
  return (
    <html lang="fr">
      <body>{children}</body>
    </html>
  );
}
