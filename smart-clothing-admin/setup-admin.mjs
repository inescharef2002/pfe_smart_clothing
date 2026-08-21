// Script de création du compte administrateur
// Exécuter une seule fois : node setup-admin.mjs

import { initializeApp } from "firebase/app";
import {
  getAuth,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
} from "firebase/auth";
import { getFirestore, doc, setDoc, getDoc } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyDN-MTr6dS2cb-mvXYgez7vyoEtJRBfjhw",
  authDomain: "smart-clothing-advisor-2026.firebaseapp.com",
  projectId: "smart-clothing-advisor-2026",
  storageBucket: "smart-clothing-advisor-2026.firebasestorage.app",
  messagingSenderId: "949137189579",
  appId: "1:949137189579:web:ce39a1f5b22a12509a494e",
};

// ── Modifie ces deux valeurs ────────────────────────────────────────────────
const ADMIN_EMAIL    = "admin@smartclothing.com";
const ADMIN_PASSWORD = "Admin123!";
// ───────────────────────────────────────────────────────────────────────────

const app  = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db   = getFirestore(app);

async function setupAdmin() {
  let uid;

  // Étape 1 : créer ou récupérer le compte Firebase Auth
  try {
    const cred = await createUserWithEmailAndPassword(auth, ADMIN_EMAIL, ADMIN_PASSWORD);
    uid = cred.user.uid;
    console.log("✓ Compte créé dans Firebase Auth :", uid);
  } catch (err) {
    if (err.code === "auth/email-already-in-use") {
      // Compte existe → on se connecte pour récupérer l'UID
      const cred = await signInWithEmailAndPassword(auth, ADMIN_EMAIL, ADMIN_PASSWORD);
      uid = cred.user.uid;
      console.log("✓ Compte existant trouvé, UID :", uid);
    } else {
      console.error("✗ Erreur Auth :", err.message);
      process.exit(1);
    }
  }

  // Étape 2 : vérifier si le document Firestore existe déjà
  const snap = await getDoc(doc(db, "users", uid));
  if (snap.exists() && snap.data().role === "admin") {
    console.log("✓ Rôle admin déjà défini dans Firestore.");
    console.log("\n🎉 Tout est prêt ! Connectez-vous avec :");
    console.log("   Email    :", ADMIN_EMAIL);
    console.log("   Password :", ADMIN_PASSWORD);
    process.exit(0);
  }

  // Étape 3 : écrire le document avec role = "admin"
  await setDoc(doc(db, "users", uid), {
    email: ADMIN_EMAIL,
    nom:   "Administrateur",
    role:  "admin",
    createdAt: new Date().toISOString(),
  }, { merge: true });

  console.log("✓ Document Firestore créé avec role = admin");
  console.log("\n🎉 Admin configuré avec succès !");
  console.log("   Email    :", ADMIN_EMAIL);
  console.log("   Password :", ADMIN_PASSWORD);
  console.log("\n   Connectez-vous sur : http://192.168.1.10:3000/login");
  process.exit(0);
}

setupAdmin().catch((err) => {
  console.error("✗ Erreur inattendue :", err.message);
  process.exit(1);
});
