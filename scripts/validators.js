/**
 * JSON validation schemas and utilities for lesson content
 * Handles validation of lesson structure, sections, and questions
 */

const Ajv = require('ajv');

// Lesson validation schema
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

// Question validation schema
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

/**
 * Lesson validation class
 */
class LessonValidator {
  constructor() {
    this.ajv = new Ajv({ allErrors: true });
    this.lessonValidator = this.ajv.compile(lessonSchema);
    this.questionValidator = this.ajv.compile(questionSchema);
  }

  /**
   * Validate lesson JSON structure
   */
  validateLesson(lessonData) {
    // Validate main lesson structure
    const lessonValid = this.lessonValidator(lessonData);
    if (!lessonValid) {
      throw new Error(`Lesson validation failed: ${this.ajv.errorsText(this.lessonValidator.errors)}`);
    }

    // Validate each section
    for (const section of lessonData.sections) {
      if (section.type === 'question') {
        this.validateQuestion(section);
      }
    }

    return true;
  }

  /**
   * Validate question structure
   */
  validateQuestion(questionData) {
    const questionValid = this.questionValidator(questionData);
    if (!questionValid) {
      throw new Error(`Question validation failed: ${this.ajv.errorsText(this.questionValidator.errors)}`);
    }
    
    // Additional validation for questions
    if (questionData.options.length !== 4) {
      throw new Error(`Question must have exactly 4 options`);
    }
    
    if (questionData.correctAnswer < 0 || questionData.correctAnswer >= 4) {
      throw new Error(`Question has invalid correctAnswer index`);
    }
  }
}

module.exports = {
  LessonValidator,
  lessonSchema,
  questionSchema
};