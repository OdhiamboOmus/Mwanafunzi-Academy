/**
 * Simple Lesson Uploader for Mwanafunzi Academy
 * Uses Firebase REST API with API key authentication - Duolingo style approach
 * No external dependencies, minimal and reliable
 */

const fs = require('fs');
const https = require('https');

// Firebase configuration from google-services.json
const FIREBASE_CONFIG = {
  projectId: 'mwanafunzi-academy',
  apiKey: 'AIzaSyB6G0oQLnPOzyrTh33_QFWSKg91BXQpOac',
  authDomain: 'mwanafunzi-academy.firebaseapp.com',
  databaseURL: 'https://mwanafunzi-academy-default-rtdb.firebaseio.com',
  storageBucket: 'mwanafunzi-academy.firebasestorage.app',
  messagingSenderId: '891072146319',
  appId: '1:891072146319:android:1921b1c9b52efeedbd79fa'
};

// API endpoints
const FIRESTORE_URL = `https://firestore.googleapis.com/v1/projects/${FIREBASE_CONFIG.projectId}/databases/(default)/documents`;

/**
 * Simple lesson validation - Duolingo style straightforward approach
 */
function validateLesson(lessonData) {
  console.log('🔍 Validating lesson structure...');
  
  // Check required fields
  const requiredFields = ['lessonId', 'title', 'subject', 'sections'];
  for (const field of requiredFields) {
    if (!lessonData[field]) {
      throw new Error(`❌ Missing required field: ${field}`);
    }
  }
  
  // Validate sections
  if (!Array.isArray(lessonData.sections) || lessonData.sections.length === 0) {
    throw new Error('❌ Sections must be a non-empty array');
  }
  
  // Validate each section
  lessonData.sections.forEach((section, index) => {
    const sectionNum = index + 1;
    
    // Check required section fields
    if (!section.sectionId) {
      throw new Error(`❌ Section ${sectionNum} missing sectionId`);
    }
    
    if (!section.type || !['content', 'question'].includes(section.type)) {
      throw new Error(`❌ Section ${sectionNum} has invalid type. Must be 'content' or 'question'`);
    }
    
    if (typeof section.order !== 'number' || section.order < 1) {
      throw new Error(`❌ Section ${sectionNum} has invalid order number`);
    }
    
    // Validate content sections
    if (section.type === 'content') {
      if (!section.content || typeof section.content !== 'string') {
        throw new Error(`❌ Content section ${sectionNum} missing or invalid content`);
      }
    }
    
    // Validate question sections
    if (section.type === 'question') {
      if (!section.question || typeof section.question !== 'string') {
        throw new Error(`❌ Question section ${sectionNum} missing question text`);
      }
      
      if (!Array.isArray(section.options) || section.options.length !== 4) {
        throw new Error(`❌ Question section ${sectionNum} must have exactly 4 options`);
      }
      
      if (typeof section.correctAnswer !== 'number' || 
          section.correctAnswer < 0 || 
          section.correctAnswer >= 4) {
        throw new Error(`❌ Question section ${sectionNum} correctAnswer must be 0-3`);
      }
      
      if (!section.explanation || typeof section.explanation !== 'string') {
        throw new Error(`❌ Question section ${sectionNum} missing explanation`);
      }
    }
  });
  
  console.log('✅ Lesson validation passed');
  return lessonData;
}

/**
 * Convert data to Firestore format
 */
function toFirestoreValue(value) {
  if (value === null) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'number') return { integerValue: value.toString() };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (Array.isArray(value)) {
    return {
      arrayValue: {
        values: value.map(item => toFirestoreValue(item))
      }
    };
  }
  if (typeof value === 'object') {
    const fields = {};
    for (const [key, val] of Object.entries(value)) {
      fields[key] = toFirestoreValue(val);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(value) };
}

/**
 * Make HTTP request to Firebase API
 */
function makeRequest(url, options, data = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            resolve(JSON.parse(body));
          } catch (e) {
            resolve({ success: true, rawResponse: body });
          }
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        }
      });
    });
    
    req.on('error', reject);
    
    if (data) {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

/**
 * Upload lesson to Firestore
 */
async function uploadLesson(grade, lessonData) {
  try {
    console.log('🚀 Starting lesson upload...');
    console.log(`📚 Grade: ${grade}`);
    console.log(`📄 Lesson: ${lessonData.title}`);
    console.log(`🆔 ID: ${lessonData.lessonId}`);
    
    // Prepare lesson document
    const lessonDoc = {
      fields: {
        lessonId: { stringValue: lessonData.lessonId },
        title: { stringValue: lessonData.title },
        subject: { stringValue: lessonData.subject },
        topic: { stringValue: lessonData.topic || lessonData.title },
        grade: { stringValue: grade },
        sections: toFirestoreValue(lessonData.sections),
        totalSections: { integerValue: lessonData.sections.length.toString() },
        hasQuestions: { booleanValue: lessonData.sections.some(s => s.type === 'question') },
        createdAt: { timestampValue: new Date().toISOString() },
        lastUpdated: { timestampValue: new Date().toISOString() },
        version: { integerValue: '1' }
      }
    };
    
    // Upload lesson content
    console.log('📤 Uploading lesson content...');
    const lessonUrl = `${FIRESTORE_URL}/lessons/${lessonData.lessonId}`;
    
    const lessonResponse = await makeRequest(lessonUrl, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json'
      }
    }, lessonDoc);
    
    console.log('✅ Lesson content uploaded successfully');
    
    // Update lessons metadata
    console.log('📝 Updating lessons metadata...');
    const metaUrl = `${FIRESTORE_URL}/lessonsMeta/${grade}`;
    
    // Get existing metadata
    let existingLessons = [];
    try {
      const metaResponse = await makeRequest(metaUrl, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      if (metaResponse.fields && metaResponse.fields.lessons && metaResponse.fields.lessons.arrayValue) {
        existingLessons = metaResponse.fields.lessons.arrayValue.values || [];
      }
    } catch (error) {
      console.log('📝 Creating new metadata document...');
    }
    
    // Prepare lesson metadata
    const lessonMeta = {
      mapValue: {
        fields: {
          id: { stringValue: lessonData.lessonId },
          title: { stringValue: lessonData.title },
          subject: { stringValue: lessonData.subject },
          topic: { stringValue: lessonData.topic || lessonData.title },
          totalSections: { integerValue: lessonData.sections.length.toString() },
          hasQuestions: { booleanValue: lessonData.sections.some(s => s.type === 'question') },
          lastUpdated: { timestampValue: new Date().toISOString() }
        }
      }
    };
    
    // Remove existing lesson with same ID
    existingLessons = existingLessons.filter(lesson => {
      const lessonId = lesson.mapValue?.fields?.id?.stringValue;
      return lessonId !== lessonData.lessonId;
    });
    
    // Add the new lesson
    existingLessons.push(lessonMeta);
    
    // Update metadata document
    const metaDoc = {
      fields: {
        grade: { stringValue: grade },
        lessons: {
          arrayValue: {
            values: existingLessons
          }
        },
        lastUpdated: { timestampValue: new Date().toISOString() }
      }
    };
    
    await makeRequest(metaUrl, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json'
      }
    }, metaDoc);
    
    console.log('✅ Metadata updated successfully');
    console.log('🎉 Upload completed! Lesson is now available to students.');
    
    return {
      success: true,
      lessonId: lessonData.lessonId,
      title: lessonData.title,
      grade: grade,
      sections: lessonData.sections.length,
      hasQuestions: lessonData.sections.some(s => s.type === 'question')
    };
    
  } catch (error) {
    console.error('❌ Upload failed:', error.message);
    throw error;
  }
}

/**
 * Main upload function
 */
async function main() {
  const args = process.argv.slice(2);
  
  if (args.length < 2) {
    console.log('📚 Mwanafunzi Academy - Simple Lesson Uploader');
    console.log('='.repeat(50));
    console.log('');
    console.log('🎯 Usage: node simple_lesson_uploader.js <grade> <lesson-file>');
    console.log('');
    console.log('📝 Arguments:');
    console.log('   grade        - Grade level (e.g., 5, 6, 7, 8)');
    console.log('   lesson-file  - Path to lesson JSON file');
    console.log('');
    console.log('💡 Examples:');
    console.log('   node simple_lesson_uploader.js 5 lesson.json');
    console.log('   node simple_lesson_uploader.js 6 ./lessons/math_lesson.json');
    console.log('   node simple_lesson_uploader.js 7 "C:\\lessons\\science.json"');
    console.log('');
    console.log('📋 Lesson file format:');
    console.log(JSON.stringify({
      "lessonId": "math_grade5_lesson1",
      "title": "Introduction to Fractions",
      "subject": "Mathematics",
      "topic": "Fractions",
      "sections": [
        {
          "sectionId": "section_1",
          "type": "content",
          "title": "What are fractions?",
          "content": "A fraction represents part of a whole...",
          "order": 1
        },
        {
          "sectionId": "section_2", 
          "type": "question",
          "question": "Which fraction represents half?",
          "options": ["1/4", "1/2", "3/4", "2/3"],
          "correctAnswer": 1,
          "explanation": "1/2 means one part out of two...",
          "order": 2
        }
      ]
    }, null, 2));
    process.exit(1);
  }
  
  const [grade, lessonFile] = args;
  
  try {
    // Check if file exists
    if (!fs.existsSync(lessonFile)) {
      throw new Error(`❌ Lesson file not found: ${lessonFile}`);
    }
    
    // Read and parse lesson file
    console.log('📖 Reading lesson file...');
    const fileContent = fs.readFileSync(lessonFile, 'utf8');
    const lessonData = JSON.parse(fileContent);
    
    // Validate lesson structure
    const validatedLesson = validateLesson(lessonData);
    
    // Upload to Firebase
    const result = await uploadLesson(grade, validatedLesson);
    
    // Display summary
    console.log('');
    console.log('📊 Upload Summary');
    console.log('='.repeat(30));
    console.log(`✅ Lesson ID: ${result.lessonId}`);
    console.log(`📚 Title: ${result.title}`);
    console.log(`🎓 Grade: ${result.grade}`);
    console.log(`📖 Sections: ${result.sections}`);
    console.log(`❓ Has Questions: ${result.hasQuestions ? 'Yes' : 'No'}`);
    console.log('='.repeat(30));
    console.log('');
    console.log('🎯 Lesson is now available to students in the app!');
    console.log('📱 Students can access it from the lessons section.');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.log('');
    console.log('💡 Troubleshooting Tips:');
    console.log('- Make sure the lesson file exists and is valid JSON');
    console.log('- Check that all required fields are present');
    console.log('- Ensure you have internet connection');
    console.log('- Verify the grade number is correct');
    console.log('- Check Firebase project configuration');
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { uploadLesson, validateLesson };