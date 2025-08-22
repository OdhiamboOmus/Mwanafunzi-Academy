# 📚 Mwanafunzi Academy - Simple Lesson Upload Guide

This guide will help you easily upload lessons to Firebase so students can access them in the app.

## 🚀 Quick Start

### Method 1: Using the Batch File (Easiest)
1. Double-click `upload_lesson.bat`
2. When prompted, enter the grade (e.g., 5, 6, 7, 8)
3. Enter the path to your lesson file (e.g., `sample_lesson.json`)
4. Press Enter and wait for upload to complete

### Method 2: Using Command Line
```bash
# Upload a lesson for grade 5
upload_lesson.bat 5 sample_lesson.json

# Upload a lesson for grade 6 with full path
upload_lesson.bat 6 "C:\lessons\math_lesson.json"
```

### Method 3: Using Node.js directly
```bash
node upload_lessons.js 5 sample_lesson.json
```

## 📝 Lesson File Format

Your lesson file must be a JSON file with this structure:

```json
{
  "lessonId": "unique_lesson_id",
  "title": "Lesson Title",
  "subject": "Mathematics",
  "topic": "Topic Name",
  "sections": [
    {
      "sectionId": "section_1",
      "type": "content",
      "title": "Section Title",
      "content": "Your lesson content here...",
      "order": 1
    },
    {
      "sectionId": "section_2",
      "type": "question",
      "question": "Your question here?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswer": 1,
      "explanation": "Explanation of the correct answer",
      "order": 2
    }
  ]
}
```

## 📋 Required Fields

### Lesson Level:
- `lessonId`: Unique identifier (e.g., "math_grade5_lesson1")
- `title`: Lesson title
- `subject`: Subject name (Mathematics, Science, English, etc.)
- `sections`: Array of lesson sections

### Content Sections:
- `sectionId`: Unique section identifier
- `type`: "content"
- `content`: The lesson content text
- `order`: Section order number

### Question Sections:
- `sectionId`: Unique section identifier  
- `type`: "question"
- `question`: The question text
- `options`: Array of exactly 4 answer options
- `correctAnswer`: Index of correct answer (0-3)
- `explanation`: Explanation of the correct answer
- `order`: Section order number

## ✅ What Happens After Upload

1. **Lesson Content**: Stored in Firebase Firestore under `/lessons/{lessonId}`
2. **Metadata**: Added to `/lessonsMeta/{grade}` for quick access
3. **Student Access**: Students can immediately see and access the lesson in the app
4. **Progress Tracking**: Student progress through sections is automatically tracked

## 🔧 Troubleshooting

### Common Issues:

**"Node.js not found"**
- Install Node.js from https://nodejs.org/
- Make sure it's added to your system PATH

**"File not found"**
- Check the file path is correct
- Use quotes around paths with spaces: `"C:\My Lessons\lesson.json"`

**"Invalid JSON"**
- Validate your JSON using an online JSON validator
- Check for missing commas, brackets, or quotes

**"Missing required field"**
- Ensure all required fields are present
- Check the lesson format example above

**"Upload failed"**
- Check your internet connection
- Verify the lesson file format is correct
- Make sure the lessonId is unique

## 📱 Verifying Upload

After successful upload, you can verify the lesson appears in the app:

1. Open the Mwanafunzi Academy app
2. Navigate to the lessons section
3. Select the appropriate grade
4. Look for your lesson in the list
5. Tap to open and verify content displays correctly

## 💡 Tips for Success

1. **Unique IDs**: Always use unique `lessonId` and `sectionId` values
2. **Order Numbers**: Use sequential order numbers (1, 2, 3, etc.)
3. **Content Length**: Keep content sections readable on mobile devices
4. **Questions**: Always provide clear explanations for correct answers
5. **Testing**: Test your lesson file with the sample before uploading many lessons

## 📞 Need Help?

If you encounter issues:
1. Check this guide first
2. Verify your lesson file format matches the example
3. Try uploading the provided `sample_lesson.json` first to test the system
4. Check the console output for specific error messages

---

**Happy Teaching! 🎓**