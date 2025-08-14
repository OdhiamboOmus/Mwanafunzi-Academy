/**
 * Enhanced batch upload script for section-based lesson content
 * Handles JSON validation, gzip compression, Firebase Storage upload, and metadata creation
 * Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.10, 7.11
 */

const fs = require('fs-extra');
const path = require('path');
const zlib = require('zlib');
const archiver = require('archiver');
const { admin, initializeApp } = require('./firebase-admin');
const Ajv = require('ajv');
const chalk = require('chalk');
const { Command } = require('commander');

// Initialize Firebase Admin
initializeApp();

// Constants
const CACHE_CONTROL_HEADER = 'public, max-age=2592000'; // 30 days
const SUPPORTED_MEDIA_TYPES = ['.webp', '.jpg', '.jpeg', '.png', '.mp3', '.wav'];
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

// Validation schemas
const lessonSchema = {
  type: 'object',
  required: ['lessonId', 'title', 'sections'],
  properties: {
    lessonId: { type: 'string', minLength: 1 },
    title: { type: 'string', minLength: 1 },
    grade: { type: 'string', minLength: 1 },
    subject: { type: 'string', minLength: 1 },
    sections: {
      type: 'array',
      minItems: 1,
      items: {
        type: 'object',
        required: ['sectionId', 'type', 'order'],
        properties: {
          sectionId: { type: 'string', minLength: 1 },
          type: { 
            type: 'string', 
            enum: ['content', 'question'],
            minLength: 1 
          },
          order: { type: 'number', minimum: 1 },
          title: { type: 'string', minLength: 1 },
          content: { type: 'string' },
          question: { type: 'string' },
          options: {
            type: 'array',
            minItems: 4,
            maxItems: 4,
            items: { type: 'string', minLength: 1 }
          },
          correctAnswer: { type: 'number', minimum: 0, maximum: 3 },
          explanation: { type: 'string', minLength: 1 },
          media: {
            type: 'array',
            items: { type: 'string' }
          }
        }
      }
    }
  }
};

const questionSchema = {
  type: 'object',
  required: ['sectionId', 'type', 'order', 'question', 'options', 'correctAnswer', 'explanation'],
  properties: {
    sectionId: { type: 'string', minLength: 1 },
    type: { type: 'string', enum: ['question'] },
    order: { type: 'number', minimum: 1 },
    question: { type: 'string', minLength: 1 },
    options: {
      type: 'array',
      minItems: 4,
      maxItems: 4,
      items: { type: 'string', minLength: 1 }
    },
    correctAnswer: { type: 'number', minimum: 0, maximum: 3 },
    explanation: { type: 'string', minLength: 1 }
  }
};

class LessonUploader {
  constructor() {
    this.ajv = new Ajv({ allErrors: true });
    this.lessonValidator = this.ajv.compile(lessonSchema);
    this.questionValidator = this.ajv.compile(questionSchema);
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
      const lessonFiles = await this.getLessonFiles(lessonsDir);
      this.results.totalLessons = lessonFiles.length;

      console.log(chalk.green(`📚 Found ${lessonFiles.length} lesson files to process`));

      // Process each lesson
      for (const lessonFile of lessonFiles) {
        await this.processLesson(lessonFile, grade);
      }

      // Generate summary report
      this.generateSummaryReport();

    } catch (error) {
      console.error(chalk.red('❌ Upload process failed:'), error.message);
      throw error;
    }
  }

  /**
   * Get all JSON lesson files from directory
   */
  async getLessonFiles(directory) {
    const files = await fs.readdir(directory);
    return files
      .filter(file => file.endsWith('.json'))
      .map(file => path.join(directory, file));
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
      const totalSections = lessonData.sections.length;
      const hasQuestions = lessonData.sections.some(section => section.type === 'question');
      const totalBytes = JSON.stringify(lessonData).length;

      this.results.totalSections += totalSections;
      this.results.totalBytes += totalBytes;

      // Compress lesson content
      const compressedContent = await this.compressLessonContent(lessonData);
      
      // Upload to Firebase Storage
      const storagePath = `lessons/${grade}/${lessonId}.json.gz`;
      await this.uploadToStorage(compressedContent, storagePath, {
        'Cache-Control': CACHE_CONTROL_HEADER,
        'Content-Encoding': 'gzip'
      });

      // Upload media files if any
      const mediaDir = path.join(path.dirname(lessonFile), 'media', lessonId);
      if (await fs.pathExists(mediaDir)) {
        await this.uploadMediaFiles(mediaDir, grade, lessonId);
      }

      // Create/update lessonsMeta document
      await this.createLessonsMetaDocument(grade, {
        id: lessonId,
        title: lessonData.title,
        grade: grade,
        subject: lessonData.subject || 'General',
        sizeBytes: compressedContent.length,
        contentPath: storagePath,
        version: '1.0.0',
        totalSections: totalSections,
        hasQuestions: hasQuestions,
        lastUpdated: new Date().toISOString()
      });

      this.results.success.push({
        lessonId,
        sections: totalSections,
        hasQuestions,
        bytes: totalBytes,
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
      const content = await fs.readJson(lessonFile);
      
      // Validate main lesson structure
      const lessonValid = this.lessonValidator(content);
      if (!lessonValid) {
        throw new Error(`Lesson validation failed: ${this.ajv.errorsText(this.lessonValidator.errors)}`);
      }

      // Validate each section
      for (const section of content.sections) {
        if (section.type === 'question') {
          const questionValid = this.questionValidator(section);
          if (!questionValid) {
            throw new Error(`Question validation failed for section ${section.sectionId}: ${this.ajv.errorsText(this.questionValidator.errors)}`);
          }
          
          // Additional validation for questions
          if (section.options.length !== 4) {
            throw new Error(`Question in section ${section.sectionId} must have exactly 4 options`);
          }
          
          if (section.correctAnswer < 0 || section.correctAnswer >= 4) {
            throw new Error(`Question in section ${section.sectionId} has invalid correctAnswer index`);
          }
        }
      }

      return content;
    } catch (error) {
      if (error instanceof SyntaxError) {
        throw new Error(`Invalid JSON in file ${lessonFile}: ${error.message}`);
      }
      throw error;
    }
  }

  /**
   * Compress lesson content using gzip
   */
  async compressLessonContent(lessonData) {
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
   * Upload file to Firebase Storage
   */
  async uploadToStorage(content, path, metadata = {}) {
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

      console.log(chalk.blue(`📤 Uploaded to: ${path}`));
      return true;
    } catch (error) {
      throw new Error(`Storage upload failed for ${path}: ${error.message}`);
    }
  }

  /**
   * Upload media files for a lesson
   */
  async uploadMediaFiles(mediaDir, grade, lessonId) {
    try {
      const mediaFiles = await fs.readdir(mediaDir);
      
      for (const mediaFile of mediaFiles) {
        const mediaPath = path.join(mediaDir, mediaFile);
        const fileExt = path.extname(mediaFile).toLowerCase();
        
        if (!SUPPORTED_MEDIA_TYPES.includes(fileExt)) {
          console.warn(chalk.yellow(`⚠️ Skipping unsupported media file: ${mediaFile}`));
          continue;
        }

        // Check file size
        const stats = await fs.stat(mediaPath);
        if (stats.size > MAX_FILE_SIZE) {
          console.warn(chalk.yellow(`⚠️ Skipping large media file: ${mediaFile} (${stats.size} bytes)`));
          continue;
        }

        const storagePath = `media/${grade}/${lessonId}/${mediaFile}`;
        const content = await fs.readFile(mediaPath);
        
        const contentType = this.getContentType(fileExt);
        await this.uploadToStorage(content, storagePath, {
          'Cache-Control': CACHE_CONTROL_HEADER,
          'Content-Type': contentType
        });
      }
    } catch (error) {
      console.warn(chalk.yellow(`⚠️ Media upload warning: ${error.message}`));
      // Continue with lesson processing even if media upload fails
    }
  }

  /**
   * Get content type for file extension
   */
  getContentType(ext) {
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
   */
  async createLessonsMetaDocument(grade, lessonMeta) {
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
      console.log(chalk.blue(`📝 Updated lessonsMeta for grade: ${grade}`));
      
    } catch (error) {
      throw new Error(`Failed to create lessonsMeta document: ${error.message}`);
    }
  }

  /**
   * Generate summary report
   */
  generateSummaryReport() {
    const duration = Date.now() - this.results.startTime;
    const successRate = (this.results.success.length / this.results.totalLessons * 100).toFixed(1);
    
    console.log(chalk.blue('\n📊 Upload Summary Report'));
    console.log(chalk.blue('='.repeat(50)));
    console.log(chalk.green(`✅ Successful uploads: ${this.results.success.length}/${this.results.totalLessons} (${successRate}%)`));
    console.log(chalk.red(` Failed uploads: ${this.results.errors.length}`));
    console.log(chalk.blue(`📚 Total lessons processed: ${this.results.totalLessons}`));
    console.log(chalk.blue(`📖 Total sections: ${this.results.totalSections}`));
    console.log(chalk.blue(`💾 Total bytes processed: ${this.formatBytes(this.results.totalBytes)}`));
    console.log(chalk.blue(`⏱️  Total time: ${this.formatDuration(duration)}`));
    
    if (this.results.errors.length > 0) {
      console.log(chalk.red('\n❌ Error Details:'));
      this.results.errors.forEach(error => {
        console.log(chalk.red(`  - ${error.lessonId}: ${error.error}`));
      });
    }
    
    console.log(chalk.blue('\n🎯 Upload process completed!'));
  }

  /**
   * Format bytes to human readable format
   */
  formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  /**
   * Format duration to human readable format
   */
  formatDuration(ms) {
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