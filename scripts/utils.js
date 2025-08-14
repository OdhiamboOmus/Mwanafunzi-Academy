/**
 * Utility functions for lesson processing
 * Helper functions for formatting, file operations, and reporting
 */

const fs = require('fs-extra');
const path = require('path');

/**
 * Get all JSON lesson files from directory
 * @param {string} directory - Directory to search
 * @returns {Promise<string[]>} Array of file paths
 */
async function getLessonFiles(directory) {
  const files = await fs.readdir(directory);
  return files
    .filter(file => file.endsWith('.json'))
    .map(file => path.join(directory, file));
}

/**
 * Format bytes to human readable format
 * @param {number} bytes - Number of bytes
 * @returns {string} Formatted size string
 */
function formatBytes(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

/**
 * Format duration to human readable format
 * @param {number} ms - Duration in milliseconds
 * @returns {string} Formatted duration string
 */
function formatDuration(ms) {
  const seconds = Math.floor(ms / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  
  if (hours > 0) {
    return `${hours}h ${minutes % 60}m ${seconds % 60}s`;
  } else if (minutes > 0) {
    return `${minutes}m ${seconds % 60}s`;
  } else {
    return `${seconds}s`;
  }
}

/**
 * Generate summary report
 * @param {Object} results - Processing results
 */
function generateSummaryReport(results) {
  const duration = Date.now() - results.startTime;
  const successRate = (results.success.length / results.totalLessons * 100).toFixed(1);
  
  console.log('\n📊 Upload Summary Report');
  console.log('='.repeat(50));
  console.log(`✅ Successful uploads: ${results.success.length}/${results.totalLessons} (${successRate}%)`);
  console.log(`❌ Failed uploads: ${results.errors.length}`);
  console.log(`📚 Total lessons processed: ${results.totalLessons}`);
  console.log(`📖 Total sections: ${results.totalSections}`);
  console.log(`💾 Total bytes processed: ${formatBytes(results.totalBytes)}`);
  console.log(`⏱️  Total time: ${formatDuration(duration)}`);
  
  if (results.errors.length > 0) {
    console.log('\n❌ Error Details:');
    results.errors.forEach(error => {
      console.log(`  - ${error.lessonId}: ${error.error}`);
    });
  }
  
  console.log('\n🎯 Upload process completed!');
}

/**
 * Calculate lesson statistics
 * @param {Object} lessonData - Lesson data
 * @returns {Object} Statistics object
 */
function calculateLessonStats(lessonData) {
  const totalSections = lessonData.sections.length;
  const hasQuestions = lessonData.sections.some(section => section.type === 'question');
  const totalBytes = JSON.stringify(lessonData).length;
  
  return {
    totalSections,
    hasQuestions,
    totalBytes
  };
}

/**
 * Read and parse lesson JSON file
 * @param {string} lessonFile - Path to lesson file
 * @returns {Promise<Object>} Lesson data
 */
async function readLessonFile(lessonFile) {
  try {
    return await fs.readJson(lessonFile);
  } catch (error) {
    if (error instanceof SyntaxError) {
      throw new Error(`Invalid JSON in file ${lessonFile}: ${error.message}`);
    }
    throw error;
  }
}

module.exports = {
  getLessonFiles,
  formatBytes,
  formatDuration,
  generateSummaryReport,
  calculateLessonStats,
  readLessonFile
};