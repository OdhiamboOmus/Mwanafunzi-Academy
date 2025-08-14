/**
 * Compression utilities for lesson content
 * Handles gzip compression and decompression
 */

const zlib = require('zlib');

/**
 * Compress lesson content using gzip
 * @param {Object} lessonData - Lesson data object
 * @returns {Promise<Buffer>} Compressed content
 */
function compressLessonContent(lessonData) {
  return new Promise((resolve, reject) => {
    const buffer = Buffer.from(JSON.stringify(lessonData));
    zlib.gzip(buffer, (err, compressed) => {
      if (err) {
        reject(new Error(`Gzip compression failed: ${err.message}`));
      } else {
        resolve(compressed);
      }
    });
  });
}

/**
 * Decompress gzip content
 * @param {Buffer} compressed - Compressed content
 * @returns {Promise<Object>} Decompressed lesson data
 */
function decompressLessonContent(compressed) {
  return new Promise((resolve, reject) => {
    zlib.gunzip(compressed, (err, decompressed) => {
      if (err) {
        reject(new Error(`Gzip decompression failed: ${err.message}`));
      } else {
        try {
          const lessonData = JSON.parse(decompressed.toString());
          resolve(lessonData);
        } catch (parseError) {
          reject(new Error(`JSON parsing failed: ${parseError.message}`));
        }
      }
    });
  });
}

/**
 * Calculate compression ratio
 * @param {Object} lessonData - Original lesson data
 * @param {Buffer} compressed - Compressed content
 * @returns {number} Compression ratio (0-1)
 */
function calculateCompressionRatio(lessonData, compressed) {
  const originalSize = Buffer.byteLength(JSON.stringify(lessonData));
  const compressedSize = compressed.length;
  return 1 - (compressedSize / originalSize);
}

module.exports = {
  compressLessonContent,
  decompressLessonContent,
  calculateCompressionRatio
};