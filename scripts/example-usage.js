/**
 * Example usage script for the lesson uploader
 * Demonstrates how to programmatically use the LessonUploader class
 */

const LessonUploader = require('./lesson-uploader');
const path = require('path');

async function exampleUsage() {
  console.log('🚀 Example Lesson Uploader Usage');
  console.log('='.repeat(50));

  // Create uploader instance
  const uploader = new LessonUploader();

  try {
    // Example 1: Validate a single lesson file
    console.log('\n📄 Example 1: Validating single lesson file');
    const lessonFile = path.join(__dirname, 'sample-lessons/grade5/math_grade5_lesson1.json');
    
    try {
      const lessonData = await uploader.readAndValidateLesson(lessonFile);
      console.log('✅ Lesson validation successful');
      console.log(`   - Lesson ID: ${lessonData.lessonId}`);
      console.log(`   - Title: ${lessonData.title}`);
      console.log(`   - Sections: ${lessonData.sections.length}`);
      console.log(`   - Has questions: ${lessonData.sections.some(s => s.type === 'question')}`);
    } catch (error) {
      console.error('❌ Lesson validation failed:', error.message);
    }

    // Example 2: Compress lesson content
    console.log('\n🗜️ Example 2: Compressing lesson content');
    try {
      const lessonData = await uploader.readAndValidateLesson(lessonFile);
      const compressed = await uploader.compressLessonContent(lessonData);
      console.log('✅ Compression successful');
      console.log(`   - Original size: ${Buffer.byteLength(JSON.stringify(lessonData))} bytes`);
      console.log(`   - Compressed size: ${compressed.length} bytes`);
      console.log(`   - Compression ratio: ${((1 - compressed.length / Buffer.byteLength(JSON.stringify(lessonData))) * 100).toFixed(1)}%`);
    } catch (error) {
      console.error('❌ Compression failed:', error.message);
    }

    // Example 3: Process directory of lessons (commented out to avoid actual upload)
    console.log('\n📚 Example 3: Processing lesson directory (simulation)');
    const lessonsDir = path.join(__dirname, 'sample-lessons/grade5');
    
    // This would normally upload to Firebase, but we'll simulate it
    console.log('📁 Directory:', lessonsDir);
    console.log('🎯 Grade: 5');
    console.log('⚠️  Note: Actual upload to Firebase Storage is disabled in this example');
    
    // Get lesson files
    const lessonFiles = await uploader.getLessonFiles(lessonsDir);
    console.log(`📄 Found ${lessonFiles.length} lesson files`);
    
    for (const file of lessonFiles) {
      const fileName = path.basename(file, '.json');
      console.log(`   - ${fileName}`);
    }

    console.log('\n🎯 To run actual upload, use:');
    console.log('   node lesson-uploader.js -d scripts/sample-lessons/grade5 -g 5');

  } catch (error) {
    console.error('❌ Example usage failed:', error.message);
  }
}

// Run the example
if (require.main === module) {
  exampleUsage().catch(console.error);
}

module.exports = { exampleUsage };