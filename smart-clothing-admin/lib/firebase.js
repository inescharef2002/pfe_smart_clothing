import { initializeApp, getApps } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
  apiKey: "AIzaSyDN-MTr6dS2cb-mvXYgez7vyoEtJRBfjhw",
  authDomain: "smart-clothing-advisor-2026.firebaseapp.com",
  projectId: "smart-clothing-advisor-2026",
  storageBucket: "smart-clothing-advisor-2026.firebasestorage.app",
  messagingSenderId: "949137189579",
  appId: "1:949137189579:web:ce39a1f5b22a12509a494e",
};

const app =
  getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];

export const db = getFirestore(app);
export const auth = getAuth(app);
export const storage = getStorage(app);
