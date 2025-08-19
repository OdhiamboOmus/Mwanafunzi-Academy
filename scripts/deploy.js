#!/usr/bin/env node

/**
 * Simple deployment script for Teacher Verification System
 * Run: node scripts/deploy.js
 */

const { execSync } = require('child_process');
const fs = require('fs');

console.log('🚀 Deploying Teacher Verification System...');

try {
  // Check if Firebase CLI is installed
  try {
    execSync('firebase --version', { stdio: 'pipe' });
    console.log('✅ Firebase CLI is installed');
  } catch (error) {
    console.error('❌ Firebase CLI is not installed');
    console.error('Install with: npm install -g firebase-tools');
    console.error('Note: This is only for development, does NOT affect APK size');
    process.exit(1);
  }

  // Check if we're in the project root
  if (!fs.existsSync('functions/package.json') || !fs.existsSync('pubspec.yaml')) {
    console.error('❌ Error: Not in project root directory');
    console.error('Please run this script from the project root directory');
    process.exit(1);
  }

  console.log('\n📦 Installing dependencies...');
  execSync('npm install', { stdio: 'inherit', cwd: 'functions' });
  execSync('flutter pub get', { stdio: 'inherit' });
  console.log('✅ Dependencies installed');

  console.log('\n☁️ Deploying Cloud Functions...');
  execSync('firebase deploy --only functions', { stdio: 'inherit' });
  console.log('✅ Cloud Functions deployed');

  console.log('\n📋 Deploying Firestore Indexes...');
  execSync('firebase firestore:indexes:create --file functions/firestore.indexes.json', { stdio: 'inherit' });
  console.log('✅ Firestore Indexes deployed');

  console.log('\n🔒 Deploying Firestore Security Rules...');
  execSync('firebase deploy --only firestore:rules', { stdio: 'inherit' });
  console.log('✅ Firestore Security Rules deployed');

  console.log('\n🏗️ Building Flutter App...');
  execSync('flutter build apk --release', { stdio: 'inherit' });
  console.log('✅ Flutter App built successfully');

  console.log('\n🎉 Deployment completed successfully!');
  console.log('📱 APK location: build/app/outputs/flutter-apk/app-release.apk');
  console.log('📊 Check Firebase console for function logs and monitoring');

} catch (error) {
  console.error('\n❌ Deployment failed:', error.message);
  console.error('\n🔧 Troubleshooting:');
  console.error('1. Run: firebase login');
  console.error('2. Run: firebase projects:list');
  console.error('3. Check your Firebase project permissions');
  process.exit(1);
}