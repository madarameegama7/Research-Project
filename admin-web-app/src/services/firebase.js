import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
    apiKey: "AIzaSyBLSX37aIwj8wu8LhEfRo1nsXmnkTarGys",
    authDomain: "black-pepper-2.firebaseapp.com",
    projectId: "black-pepper-2",
    storageBucket: "black-pepper-2.firebasestorage.app",
    messagingSenderId: "643482796193",
    appId: "1:643482796193:web:f719be8ad2680cd35f30e0"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase Authentication and get a reference to the service
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
