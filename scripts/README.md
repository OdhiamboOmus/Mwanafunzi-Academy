# Mwanafunzi Academy Lesson Uploader

A Node.js script for batch uploading section-based lesson content to Firebase Storage with comprehensive validation, compression, and metadata management.

## Features

- ✅ **JSON Validation**: Validates lesson structure including sections and embedded questions
- 🗜️ **Gzip Compression**: Compresses lesson content for efficient storage and transfer
- 📤 **Firebase Storage Upload**: Uploads to Firebase Storage with 30-day cache headers
- 🎯 **Section Validation**: Validates section structure with sectionId, type, and required fields
- 🖼️ **Media Handling**: Uploads and compresses media files (images, audio)
- 📊 **Metadata Creation**: Creates lessonsMeta documents with totalSections and hasQuestions fields
- 📝 **Error Logging**: Comprehensive error logging and summary reporting
- 🔗 **Relative Paths**: Supports relative image paths in lesson content
- ❓ **Question Validation**: Validates embedded questions with 4 options, correct answer, and explanation

## Requirements

- Node.js 16+ 
- Firebase project with Storage and Firestore enabled
- Service account credentials with appropriate permissions

## Installation

1. Install dependencies:
```bash
cd scripts
npm install
```

2. Configure Firebase:
   - Ensure `google-services.json` is in the project root
   - Update the storage bucket in `firebase-admin.js` if needed

## Usage

### Command Line Interface

```bash
node lesson-uploader.js -d /path/to/lessons -g 5
```

### Options

- `-d, --directory <path>`: Directory containing lesson JSON files (required)
- `-g, --grade <grade>`: Grade level (e.g., 5, 6, 7) (required)
- `-v, --verbose`: Enable verbose logging
- `-h, --help`: Show help information

### Example

```bash
# Upload all lessons for grade 5
node lesson-uploader.js -d ./lessons/grade5 -g 5

# Upload with verbose logging
node lesson-uploader.js -d ./lessons/grade6 -g 6 -v
```

## Lesson JSON Structure

### Required Format

```json
{
  "lessonId": "math_grade5_lesson1",
  "title": "Introduction to Fractions",
  "grade": "5",
  "subject": "Mathematics",
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
      "explanation": "1/2 means one part out of two equal parts.",
      "order": 2
    }
  ]
}
```

### Section Types

#### Content Section
```json
{
  "sectionId": "section_1",
  "type": "content",
  "title": "Section Title",
  "content": "Content text here...",
  "order": 1,
  "media": ["image1.webp"]
}
```

#### Question Section
```json
{
  "sectionId": "section_2",
  "type": "question", 
  "question": "What is 2 + 2?",
  "options": ["3", "4", "5", "6"],
  "correctAnswer": 1,
  "explanation": "2 + 2 equals 4.",
  "order": 2
}
```

## Media File Organization

### Directory Structure
```
lessons/
├── grade5/
│   ├── math_grade5_lesson1.json
│   └── media/
│       └── math_grade5_lesson1/
│           ├── image1.webp
│           └── audio1.mp3
└── grade6/
    ├── math_grade6_lesson1.json
    └── media/
        └── math_grade6_lesson1/
            └── diagram.png
```

### Supported Media Types
- Images: `.webp`, `.jpg`, `.jpeg`, `.png`
- Audio: `.mp3`, `.wav`
- Max file size: 10MB per file

## Output

### Console Output
The script provides detailed console output including:
- Progress tracking for each lesson
- Validation results
- Upload status
- Error messages with details
- Final summary report

### Summary Report
```
📊 Upload Summary Report
==================================================
✅ Successful uploads: 10/10 (100.0%)
 Failed uploads: 0
📚 Total lessons processed: 10
📖 Total sections: 45
💾 Total bytes processed: 2.5 MB
⏱️  Total time: 45s

🎯 Upload process completed!
```

## Error Handling

The script includes comprehensive error handling for:
- Invalid JSON structure
- Missing required fields
- Incorrect question format
- File upload failures
- Firebase connection issues
- Media file validation

## Firebase Storage Structure

### Uploaded Files
- **Lessons**: `lessons/{grade}/{lessonId}.json.gz`
- **Media**: `media/{grade}/{lessonId}/{filename}`

### Cache Headers
All uploaded files include 30-day cache headers:
```
Cache-Control: public, max-age=2592000
```

### Firestore Documents
- **lessonsMeta/{grade}**: Contains metadata for all lessons in the grade
- Each lesson includes: id, title, grade, subject, sizeBytes, contentPath, version, totalSections, hasQuestions

## Development

### Running Tests
```bash
npm test
```

### Code Structure
- `lesson-uploader.js`: Main upload script
- `firebase-admin.js`: Firebase initialization
- `package.json`: Dependencies and scripts
- `README.md`: Documentation

### Adding New Validation Rules
Update the validation schemas in `lesson-uploader.js`:
- `lessonSchema`: Main lesson structure validation
- `questionSchema`: Question-specific validation

## Troubleshooting

### Common Issues

1. **Firebase Authentication Error**
   - Ensure service account has proper permissions
   - Check Firebase project configuration

2. **File Upload Failures**
   - Verify file paths and permissions
   - Check file size limits
   - Ensure network connectivity

3. **Validation Errors**
   - Check JSON syntax
   - Verify required fields
   - Ensure question format compliance

### Debug Mode
Use verbose logging for detailed troubleshooting:
```bash
node lesson-uploader.js -d ./lessons -g 5 -v
```

## License

MIT License - see LICENSE file for details.