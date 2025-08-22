# Mwanafunzi Academy - Content Upload Scripts

Simple scripts to upload lessons and quizzes to Firebase for student access. No complex setup required!

## 📚 Lesson Uploader

### Features
- ✅ Simple REST API approach (no Firebase Admin SDK needed)
- ✅ Validates lesson JSON structure
- ✅ Uploads to Firebase Firestore
- ✅ Updates lesson metadata
- ✅ Works with existing student-side app
- ✅ No external dependencies (Node.js built-in modules only)

### Usage

#### Method 1: Command Line
```bash
node simple_lesson_uploader.js <grade> <lesson-file>
```

#### Method 2: Batch File
```bash
upload_lesson.bat
```

**Examples:**
```bash
# Upload lesson for grade 5
node simple_lesson_uploader.js 5 sample-lessons/grade5/sample-lesson.json

# Upload with full path
node simple_lesson_uploader.js 6 "C:\lessons\math_lesson.json"
```

### Lesson File Format
```json
{
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
}
```

## 📝 Quiz Uploader

### Features
- ✅ Simple REST API approach (no Firebase Admin SDK needed)
- ✅ Validates quiz JSON structure
- ✅ Uploads to Firebase Firestore
- ✅ Updates quiz metadata
- ✅ Works with existing student-side app
- ✅ No external dependencies (Node.js built-in modules only)

### Usage

#### Method 1: Command Line
```bash
node simple_quiz_uploader.js <grade> <quiz-file>
```

#### Method 2: Batch File
```bash
upload_quiz.bat
```

**Examples:**
```bash
# Upload quiz for grade 5
node simple_quiz_uploader.js 5 sample-quizzes/grade5/math_sample_quiz.json

# Upload with full path
node simple_quiz_uploader.js 7 "C:\quizzes\science_quiz.json"
```

### Quiz File Format
```json
{
  "quizId": "math_grade5_quiz1",
  "title": "Fractions Quiz",
  "subject": "Mathematics",
  "grade": "5",
  "questions": [
    {
      "questionId": "q1",
      "question": "What is 1/2 + 1/4?",
      "options": ["1/6", "2/4", "3/4", "1/2"],
      "correctAnswer": 2,
      "explanation": "1/2 = 2/4, so 2/4 + 1/4 = 3/4",
      "difficulty": "easy"
    },
    {
      "questionId": "q2", 
      "question": "Which fraction is equivalent to 0.75?",
      "options": ["1/2", "2/3", "3/4", "4/5"],
      "correctAnswer": 2,
      "explanation": "0.75 = 3/4",
      "difficulty": "medium"
    }
  ]
}
```

## 📁 File Structure

```
scripts/
├── simple_lesson_uploader.js    # Main lesson upload script
├── simple_quiz_uploader.js      # Main quiz upload script
├── upload_lesson.bat            # Lesson batch script
├── upload_quiz.bat              # Quiz batch script
├── sample-lessons/              # Sample lesson files
│   └── grade5/
│       └── sample-lesson.json
├── sample-quizzes/              # Sample quiz files
│   └── grade5/
│       └── math_sample_quiz.json
├── README.md                    # This file
└── FILE_STRUCTURE.md           # File structure documentation
```

## 🔧 Setup Instructions

### Firebase Security Rules

Make sure your Firestore security rules allow the uploads:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Lessons collection - allow uploads
    match /lessons/{lessonId} {
      allow read, write: if true;
    }
    
    // Lessons metadata collection
    match /lessonsMeta/{grade} {
      allow read, write: if true;
    }
    
    // Quizzes collection - allow uploads
    match /quizzes/{quizId} {
      allow read, write: if true;
    }
    
    // Quiz metadata collection
    match /quizMeta/{grade} {
      allow read, write: if true;
    }
  }
}
```

## 📊 What Happens When You Upload

### Lessons
1. **Lesson Content**: Uploads to `lessons/{lessonId}`
2. **Metadata**: Updates `lessonsMeta/{grade}` with lesson information
3. **Student Access**: Lessons become immediately available to students

### Quizzes
1. **Quiz Content**: Uploads to `quizzes/{quizId}`
2. **Metadata**: Updates `quizMeta/{grade}` with quiz information
3. **Student Access**: Quizzes become immediately available to students

## 🚀 Quick Start Guide

1. **Choose your content type**: Lesson or Quiz
2. **Prepare your JSON file**: Use the sample files as templates
3. **Run the uploader**: Use command line or batch file
4. **Verify in app**: Check that students can see the content

## 🔍 Troubleshooting

### Common Issues

1. **Permission Denied**: Check Firebase security rules
2. **File Not Found**: Verify the file path is correct
3. **Invalid JSON**: Use the sample files as templates
4. **Missing Fields**: Check required fields in your JSON

### Getting Help

- Check the sample file structure
- Verify your Firebase configuration
- Ensure your security rules are properly configured

## ✅ Benefits

- **Simple**: No complex Firebase setup
- **Fast**: Direct REST API calls
- **Reliable**: Built-in validation and error handling
- **Compatible**: Works with existing student app
- **Flexible**: Supports multiple grades and content types
- **No Dependencies**: Uses only Node.js built-in modules

## 📞 Notes

- Content is immediately available to students after upload
- No need to restart the app or clear cache
- Supports both content and question sections in lessons
- Validates JSON structure before upload
- Works with API key authentication for secure production use

---

**Happy Teaching! 🎓**