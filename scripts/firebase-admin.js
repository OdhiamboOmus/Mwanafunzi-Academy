/**
 * Firebase Admin initialization module
 * Handles Firebase configuration and admin setup
 */

const admin = require('firebase-admin');

/**
 * Initialize Firebase Admin
 */
function initializeApp() {
  if (!admin.apps.length) {
    try {
      admin.initializeApp({
        credential: admin.credential.cert(require('../android/app/google-services.json')),
        storageBucket: 'mwanafunzi-academy.appspot.com'
      });
      console.log('✅ Firebase Admin initialized successfully');
    } catch (error) {
      console.error('❌ Firebase Admin initialization failed:', error.message);
      throw error;
    }
  }
  
  return admin;
}

/**
 * Get Firebase Admin instance
 */
function getAdmin() {
  return admin;
}

module.exports = {
  admin,
  initializeApp,
  getAdmin
};