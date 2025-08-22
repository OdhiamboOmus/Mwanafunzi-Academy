/**
 * Simple Quiz Uploader for Mwanafunzi Academy
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
 * Simple quiz validation - Duolingo style straightforward approach
 */
function validateQuiz(quizData) {
  console.log('🔍 Validating quiz structure...');
  
  // Check required fields
  const requiredFields = ['quizId', 'title', 'subject', 'topic', 'questions'];
  for (const field of requiredFields) {
    if (!quizData[field]) {
      throw new Error(`❌ Missing required field: ${field}`);
    }
  }
  
  // Validate questions
  if (!Array.isArray(quizData.questions) || quizData.questions.length === 0) {
    throw new Error('❌ Questions must be a non-empty array');
  }
  
  // Validate each question
  quizData.questions.forEach((question, index) => {
    const questionNum = index + 1;
    
    // Check required question fields
    if (!question.id) {
      throw new Error(`❌ Question ${questionNum} missing id`);
    }
    
    if (!question.question || typeof question.question !== 'string') {
      throw new Error(`❌ Question ${questionNum} missing question text`);
    }
    
    if (!Array.isArray(question.options) || question.options.length !== 4) {
      throw new Error(`❌ Question ${questionNum} must have exactly 4 options`);
    }
    
    if (typeof question.correctAnswerIndex !== 'number' || 
        question.correctAnswerIndex < 0 || 
        question.correctAnswerIndex >= 4) {
      throw new Error(`❌ Question ${questionNum} correctAnswerIndex must be 0-3`);
    }
    
    if (!question.explanation || typeof question.explanation !== 'string') {
      throw new Error(`❌ Question ${questionNum} missing explanation`);
    }
  });
  
  console.log('✅ Quiz validation passed');
  return quizData;
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
 * Upload quiz to Firestore
 */
async function uploadQuiz(grade, quizData) {
  try {
    console.log('🚀 Starting quiz upload...');
    console.log(`📚 Grade: ${grade}`);
    console.log(`📄 Quiz: ${quizData.title}`);
    console.log(`🆔 ID: ${quizData.quizId}`);
    
    // Prepare quiz document
    const quizDoc = {
      fields: {
        quizId: { stringValue: quizData.quizId },
        title: { stringValue: quizData.title },
        subject: { stringValue: quizData.subject },
        topic: { stringValue: quizData.topic },
        grade: { stringValue: grade },
        description: { stringValue: quizData.description || '' },
        questions: toFirestoreValue(quizData.questions),
        totalQuestions: { integerValue: quizData.questions.length.toString() },
        createdAt: { timestampValue: new Date().toISOString() },
        lastUpdated: { timestampValue: new Date().toISOString() },
        version: { integerValue: '1' }
      }
    };
    
    // Upload quiz content
    console.log('📤 Uploading quiz content...');
    const quizUrl = `${FIRESTORE_URL}/quizzes/${quizData.quizId}`;
    
    const quizResponse = await makeRequest(quizUrl, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json'
      }
    }, quizDoc);
    
    console.log('✅ Quiz content uploaded successfully');
    
    // Update quiz metadata
    console.log('📝 Updating quiz metadata...');
    const metaUrl = `${FIRESTORE_URL}/quizMeta/${grade}`;
    
    // Get existing metadata
    let existingQuizzes = [];
    try {
      const metaResponse = await makeRequest(metaUrl, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      if (metaResponse.fields && metaResponse.fields.quizzes && metaResponse.fields.quizzes.arrayValue) {
        existingQuizzes = metaResponse.fields.quizzes.arrayValue.values || [];
      }
    } catch (error) {
      console.log('📝 Creating new metadata document...');
    }
    
    // Prepare quiz metadata
    const quizMeta = {
      mapValue: {
        fields: {
          id: { stringValue: quizData.quizId },
          title: { stringValue: quizData.title },
          subject: { stringValue: quizData.subject },
          topic: { stringValue: quizData.topic },
          totalQuestions: { integerValue: quizData.questions.length.toString() },
          lastUpdated: { timestampValue: new Date().toISOString() }
        }
      }
    };
    
    // Remove existing quiz with same ID
    existingQuizzes = existingQuizzes.filter(quiz => {
      const quizId = quiz.mapValue?.fields?.id?.stringValue;
      return quizId !== quizData.quizId;
    });
    
    // Add the new quiz
    existingQuizzes.push(quizMeta);
    
    // Update metadata document
    const metaDoc = {
      fields: {
        grade: { stringValue: grade },
        quizzes: {
          arrayValue: {
            values: existingQuizzes
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
    console.log('🎉 Upload completed! Quiz is now available to students.');
    
    return {
      success: true,
      quizId: quizData.quizId,
      title: quizData.title,
      grade: grade,
      questions: quizData.questions.length,
      subject: quizData.subject
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
    console.log('📚 Mwanafunzi Academy - Simple Quiz Uploader');
    console.log('='.repeat(50));
    console.log('');
    console.log('🎯 Usage: node simple_quiz_uploader.js <grade> <quiz-file>');
    console.log('');
    console.log('📝 Arguments:');
    console.log('   grade        - Grade level (e.g., 5, 6, 7, 8)');
    console.log('   quiz-file    - Path to quiz JSON file');
    console.log('');
    console.log('💡 Examples:');
    console.log('   node simple_quiz_uploader.js 5 quiz.json');
    console.log('   node simple_quiz_uploader.js 6 ./quizzes/math_quiz.json');
    console.log('   node simple_quiz_uploader.js 7 "C:\\quizzes\\science.json"');
    console.log('');
    console.log('📋 Quiz file format:');
    console.log(JSON.stringify({
      "quizId": "math_grade5_quiz1",
      "title": "Fractions Quiz",
      "subject": "Mathematics",
      "topic": "Fractions",
      "description": "Test your understanding of fractions",
      "questions": [
        {
          "id": "q1",
          "question": "What is 1/2 + 1/4?",
          "options": ["1/6", "3/4", "2/6", "1/4"],
          "correctAnswerIndex": 1,
          "explanation": "To add fractions with the same denominator..."
        }
      ]
    }, null, 2));
    process.exit(1);
  }
  
  const [grade, quizFile] = args;
  
  try {
    // Check if file exists
    if (!fs.existsSync(quizFile)) {
      throw new Error(`❌ Quiz file not found: ${quizFile}`);
    }
    
    // Read and parse quiz file
    console.log('📖 Reading quiz file...');
    const fileContent = fs.readFileSync(quizFile, 'utf8');
    const quizData = JSON.parse(fileContent);
    
    // Validate quiz structure
    const validatedQuiz = validateQuiz(quizData);
    
    // Upload to Firebase
    const result = await uploadQuiz(grade, validatedQuiz);
    
    // Display summary
    console.log('');
    console.log('📊 Upload Summary');
    console.log('='.repeat(30));
    console.log(`✅ Quiz ID: ${result.quizId}`);
    console.log(`📚 Title: ${result.title}`);
    console.log(`🎓 Grade: ${result.grade}`);
    console.log(`📖 Questions: ${result.questions}`);
    console.log(`📚 Subject: ${result.subject}`);
    console.log('='.repeat(30));
    console.log('');
    console.log('🎯 Quiz is now available to students in the app!');
    console.log('📱 Students can access it from the quiz section.');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.log('');
    console.log('💡 Troubleshooting Tips:');
    console.log('- Make sure the quiz file exists and is valid JSON');
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

module.exports = { uploadQuiz, validateQuiz };