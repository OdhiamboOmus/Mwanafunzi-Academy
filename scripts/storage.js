/**
 * Firebase Storage utilities for lesson content upload
 * Handles file uploads with proper cache headers and metadata
 */

const { admin, initializeApp } = require('./firebase-admin');

// Constants
const CACHE_CONTROL_HEADER = 'public, max-age=2592000'; // 30 days
const SUPPORTED_MEDIA_TYPES = ['.webp', '.jpg', '.jpeg', '.png', '.mp3', '.wav'];
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

/**
 * Upload content to Firebase Storage
 * @param {Buffer} content - File content
 * @param {string} path - Storage path
 * @param {Object} metadata - Additional metadata
 * @returns {Promise<boolean>} Upload success
 */
async function uploadToStorage(content, path, metadata = {}) {
  try {
    const bucket = admin.storage().bucket();
    const file = bucket.file(path);
    
    await file.save(content, {
      metadata: {
        ...metadata,
        contentType: 'application/json',
        customMetadata: {
          uploadedBy: 'lesson-uploader-script',
          uploadDate: new Date().toISOString()
        }
      }
    });

    console.log(`📤 Uploaded to: ${path}`);
    return true;
  } catch (error) {
    throw new Error(`Storage upload failed for ${path}: ${error.message}`);
  }
}

/**
 * Upload media files for a lesson
 * @param {string} mediaDir - Directory containing media files
 * @param {string} grade - Grade level
 * @param {string} lessonId - Lesson ID
 * @returns {Promise<void>}
 */
async function uploadMediaFiles(mediaDir, grade, lessonId) {
  try {
    const fs = require('fs-extra');
    const path = require('path');
    
    const mediaFiles = await fs.readdir(mediaDir);
    
    for (const mediaFile of mediaFiles) {
      const mediaPath = path.join(mediaDir, mediaFile);
      const fileExt = path.extname(mediaFile).toLowerCase();
      
      if (!SUPPORTED_MEDIA_TYPES.includes(fileExt)) {
        console.warn(`⚠️ Skipping unsupported media file: ${mediaFile}`);
        continue;
      }

      // Check file size
      const stats = await fs.stat(mediaPath);
      if (stats.size > MAX_FILE_SIZE) {
        console.warn(`⚠️ Skipping large media file: ${mediaFile} (${stats.size} bytes)`);
        continue;
      }

      const storagePath = `media/${grade}/${lessonId}/${mediaFile}`;
      const content = await fs.readFile(mediaPath);
      
      const contentType = getContentType(fileExt);
      await uploadToStorage(content, storagePath, {
        'Cache-Control': CACHE_CONTROL_HEADER,
        'Content-Type': contentType
      });
    }
  } catch (error) {
    console.warn(`⚠️ Media upload warning: ${error.message}`);
    // Continue with lesson processing even if media upload fails
  }
}

/**
 * Get content type for file extension
 * @param {string} ext - File extension
 * @returns {string} Content type
 */
function getContentType(ext) {
  const contentTypes = {
    '.webp': 'image/webp',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.mp3': 'audio/mpeg',
    '.wav': 'audio/wav'
  };
  return contentTypes[ext] || 'application/octet-stream';
}

/**
 * Create or update lessonsMeta document in Firestore
 * @param {string} grade - Grade level
 * @param {Object} lessonMeta - Lesson metadata
 * @returns {Promise<void>}
 */
async function createLessonsMetaDocument(grade, lessonMeta) {
  try {
    const db = admin.firestore();
    const docRef = db.collection('lessonsMeta').doc(grade);
    
    // Get existing document or create new one
    const doc = await docRef.get();
    const existingData = doc.exists ? doc.data() : { lessons: [], lastUpdated: new Date().toISOString() };
    
    // Check if lesson already exists
    const existingLessonIndex = existingData.lessons.findIndex(l => l.id === lessonMeta.id);
    
    if (existingLessonIndex >= 0) {
      // Update existing lesson
      existingData.lessons[existingLessonIndex] = lessonMeta;
    } else {
      // Add new lesson
      existingData.lessons.push(lessonMeta);
    }
    
    // Update lastUpdated timestamp
    existingData.lastUpdated = new Date().toISOString();
    
    await docRef.set(existingData);
    console.log(`📝 Updated lessonsMeta for grade: ${grade}`);
    
  } catch (error) {
    throw new Error(`Failed to create lessonsMeta document: ${error.message}`);
  }
}

module.exports = {
  uploadToStorage,
  uploadMediaFiles,
  createLessonsMetaDocument,
  getContentType,
  CACHE_CONTROL_HEADER,
  SUPPORTED_MEDIA_TYPES,
  MAX_FILE_SIZE
};