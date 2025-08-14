/**
 * Enhanced batch upload script for section-based lesson content
 * Split version with modular architecture following 150 lines per file guideline
 * Handles JSON validation, gzip compression, Firebase Storage upload, and metadata creation
 * Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.10, 7.11
 */

const fs = require('fs-extra');
const path = require('path');
const chalk = require('chalk');
const { Command } = require('commander');

// Import modular components
const { LessonValidator } = require('./validators');
const { compressLessonContent } = require('./compression');
const { uploadToStorage, uploadMediaFiles, createLessonsMetaDocument } = require('./storage');
const { getLessonFiles, generateSummaryReport, calculateLessonStats, readLessonFile } = require('./utils');

// Initialize Firebase Admin
const { initializeApp } = require('./firebase-admin');
initializeApp();

/**
 * Main Lesson Uploader class
 */
class LessonUploader {
  constructor() {
    this.validator = new LessonValidator();
    this.results = {
      success: [],
      errors: [],
      totalLessons: 0,
      totalSections: 0,
      totalBytes: 0,
      startTime: Date.now()
    };
  }

  /**
   * Main upload process
   */
  async uploadLessons(lessonsDir, grade) {
    try {
      console.log(chalk.blue('🚀 Starting lesson upload process...'));
      
      // Validate input directory
      if (!await fs.pathExists(lessonsDir)) {
        throw new Error(`Lessons directory not found: ${lessonsDir}`);
      }

      // Get all lesson files
      const lessonFiles = await getLessonFiles(lessonsDir);
      this.results.totalLessons = lessonFiles.length;

      console.log(chalk.green(`📚 Found ${lessonFiles.length} lesson files to process`));

      // Process each lesson
      for (const lessonFile of lessonFiles) {
        await this.processLesson(lessonFile, grade);
      }

      // Generate summary report
      generateSummaryReport(this.results);

    } catch (error) {
      console.error(chalk.red('❌ Upload process failed:'), error.message);
      throw error;
    }
  }

  /**
   * Process individual lesson file
   */
  async processLesson(lessonFile, grade) {
    const lessonId = path.basename(lessonFile, '.json');
    
    try {
      console.log(chalk.yellow(`📄 Processing lesson: ${lessonId}`));

      // Read and validate lesson JSON
      const lessonData = await this.readAndValidateLesson(lessonFile);
      
      // Calculate statistics
      const stats = calculateLessonStats(lessonData);
      this.results.totalSections += stats.totalSections;
      this.results.totalBytes += stats.totalBytes;

      // Compress lesson content
      const compressedContent = await compressLessonContent(lessonData);
      
      // Upload to Firebase Storage
      const storagePath = `lessons/${grade}/${lessonId}.json.gz`;
      await uploadToStorage(compressedContent, storagePath, {
        'Cache-Control': 'public, max-age=2592000',
        'Content-Encoding': 'gzip'
      });

      // Upload media files if any
      const mediaDir = path.join(path.dirname(lessonFile), 'media', lessonId);
      if (await fs.pathExists(mediaDir)) {
        await uploadMediaFiles(mediaDir, grade, lessonId);
      }

      // Create/update lessonsMeta document
      await createLessonsMetaDocument(grade, {
        id: lessonId,
        title: lessonData.title,
        grade: grade,
        subject: lessonData.subject || 'General',
        sizeBytes: compressedContent.length,
        contentPath: storagePath,
        version: '1.0.0',
        totalSections: stats.totalSections,
        hasQuestions: stats.hasQuestions,
        lastUpdated: new Date().toISOString()
      });

      this.results.success.push({
        lessonId,
        sections: stats.totalSections,
        hasQuestions: stats.hasQuestions,
        bytes: stats.totalBytes,
        status: 'completed'
      });

      console.log(chalk.green(`✅ Successfully processed lesson: ${lessonId}`));

    } catch (error) {
      console.error(chalk.red(`❌ Failed to process lesson ${lessonId}:`), error.message);
      
      this.results.errors.push({
        lessonId,
        error: error.message,
        stack: error.stack
      });
    }
  }

  /**
   * Read and validate lesson JSON structure
   */
  async readAndValidateLesson(lessonFile) {
    try {
      const content = await readLessonFile(lessonFile);
      this.validator.validateLesson(content);
      return content;
    } catch (error) {
      throw error;
    }
  }
}

// Command line interface
const program = new Command();

program
  .name('lesson-uploader')
  .description('Batch upload script for section-based lesson content')
  .version('1.0.0')
  .requiredOption('-d, --directory <path>', 'Directory containing lesson JSON files')
  .requiredOption('-g, --grade <grade>', 'Grade level (e.g., 5, 6, 7)')
  .option('-v, --verbose', 'Enable verbose logging')
  .action(async (options) => {
    const uploader = new LessonUploader();
    
    try {
      await uploader.uploadLessons(options.directory, options.grade);
      process.exit(0);
    } catch (error) {
      console.error(chalk.red('❌ Upload failed:'), error.message);
      process.exit(1);
    }
  });

program.parse();