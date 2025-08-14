/**
 * Test script for lesson JSON validation
 * Validates lesson structure without Firebase upload
 */

const fs = require('fs-extra');
const path = require('path');
const Ajv = require('ajv');
const chalk = require('chalk');

// Import validation schemas from main script
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

class LessonValidator {
  constructor() {
    this.ajv = new Ajv({ allErrors: true });
    this.lessonValidator = this.ajv.compile(lessonSchema);
    this.questionValidator = this.ajv.compile(questionSchema);
    this.results = {
      valid: [],
      invalid: [],
      total: 0
    };
  }

  /**
   * Validate all JSON files in directory
   */
  async validateDirectory(directory) {
    try {
      console.log(chalk.blue('🔍 Starting lesson validation...'));
      
      if (!await fs.pathExists(directory)) {
        throw new Error(`Directory not found: ${directory}`);
      }

      const files = await fs.readdir(directory);
      const jsonFiles = files.filter(file => file.endsWith('.json'));
      
      this.results.total = jsonFiles.length;
      console.log(chalk.green(`📄 Found ${jsonFiles.length} JSON files to validate`));

      for (const file of jsonFiles) {
        await this.validateFile(path.join(directory, file));
      }

      this.generateReport();

    } catch (error) {
      console.error(chalk.red('❌ Validation failed:'), error.message);
      throw error;
    }
  }

  /**
   * Validate individual lesson file
   */
  async validateFile(filePath) {
    try {
      const fileName = path.basename(filePath);
      console.log(chalk.yellow(`📄 Validating: ${fileName}`));

      const content = await fs.readJson(filePath);
      
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

      this.results.valid.push({
        file: fileName,
        sections: content.sections.length,
        hasQuestions: content.sections.some(s => s.type === 'question'),
        status: 'valid'
      });

      console.log(chalk.green(`✅ Valid: ${fileName}`));

    } catch (error) {
      console.error(chalk.red(`❌ Invalid: ${path.basename(filePath)}`), error.message);
      
      this.results.invalid.push({
        file: path.basename(filePath),
        error: error.message,
        status: 'invalid'
      });
    }
  }

  /**
   * Generate validation report
   */
  generateReport() {
    const validCount = this.results.valid.length;
    const invalidCount = this.results.invalid.length;
    const validityRate = (validCount / this.results.total * 100).toFixed(1);

    console.log(chalk.blue('\n📊 Validation Report'));
    console.log(chalk.blue('='.repeat(50)));
    console.log(chalk.green(`✅ Valid files: ${validCount}/${this.results.total} (${validityRate}%)`));
    console.log(chalk.red(`❌ Invalid files: ${invalidCount}`));
    
    if (this.results.valid.length > 0) {
      console.log(chalk.blue('\n📚 Valid Lessons:'));
      this.results.valid.forEach(lesson => {
        const questions = lesson.hasQuestions ? ' (with questions)' : '';
        console.log(chalk.green(`  - ${lesson.file}: ${lesson.sections} sections${questions}`));
      });
    }

    if (this.results.invalid.length > 0) {
      console.log(chalk.red('\n❌ Invalid Lessons:'));
      this.results.invalid.forEach(lesson => {
        console.log(chalk.red(`  - ${lesson.file}: ${lesson.error}`));
      });
    }

    console.log(chalk.blue('\n🎯 Validation completed!'));
  }
}

// Command line interface
const { Command } = require('commander');

const program = new Command();

program
  .name('lesson-validator')
  .description('Validate lesson JSON structure')
  .version('1.0.0')
  .requiredOption('-d, --directory <path>', 'Directory containing lesson JSON files')
  .action(async (options) => {
    const validator = new LessonValidator();
    
    try {
      await validator.validateDirectory(options.directory);
      process.exit(0);
    } catch (error) {
      console.error(chalk.red('❌ Validation failed:'), error.message);
      process.exit(1);
    }
  });

program.parse();