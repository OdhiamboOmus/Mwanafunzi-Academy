# 🚀 Deployment Guide for Teacher Verification System

This guide provides step-by-step instructions for deploying the teacher verification system to Firebase.

## Prerequisites

1. **Node.js**: Version 14 or higher
2. **Flutter**: Latest stable version
3. **Firebase CLI**: Install with `npm install -g firebase-tools`
4. **Google Account**: With Firebase project access

## Firebase Project Setup

### 1. Create Firebase Project
```bash
# If you don't have a Firebase project yet
firebase projects:create teacher-verification-system
firebase use teacher-verification-system
```

### 2. Initialize Firebase
```bash
# Initialize Firebase in your project directory
firebase init
```
Select the following options:
- Hosting: Configure and deploy Firebase Hosting sites
- Functions: Configure Cloud Functions for Firebase
- Firestore: Configure Firestore security rules and indexes
- Emulators: Set up local emulators

### 3. Configure Firebase Settings
Update `firebase.json` with your project configuration.

## Deployment Steps

### 1. Deploy Cloud Functions
```bash
# Install dependencies
cd functions
npm install
cd ..

# Deploy Cloud Functions
firebase deploy --only functions
```

### 2. Deploy Firestore Indexes
```bash
# Method 1: Using the deployment script
node scripts/deploy_firestore_indexes.js

# Method 2: Using Firebase CLI directly
firebase firestore:indexes:create --file functions/firestore.indexes.json
```

### 3. Deploy Firestore Security Rules
```bash
firebase deploy --only firestore:rules
```

### 4. Deploy Flutter App
```bash
# Build the app
flutter build apk --release

# Deploy to Firebase Hosting (if configured)
firebase deploy --only hosting
```

## Firestore Indexes

The following indexes are created for optimal performance:

### Teachers Collection
```json
{
  "fields": [
    { "fieldPath": "verificationStatus", "order": "ASCENDING" },
    { "fieldPath": "areaOfOperation", "order": "ASCENDING" },
    { "fieldPath": "subjects", "order": "ASCENDING" }
  ]
}
```

### Bookings Collection
```json
{
  "fields": [
    { "fieldPath": "teacherId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "startDate", "order": "ASCENDING" }
  ]
}
```

### Transactions Collection
```json
{
  "fields": [
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

### Platform Ledger Collection
```json
{
  "fields": [
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

## Environment Variables

Set the following environment variables in your Firebase project:

```bash
# Set environment variables
firebase functions:config:set mpesa.consumer_key="your_consumer_key"
firebase functions:config:set mpesa.consumer_secret="your_consumer_secret"
firebase functions:config:set mpesa.shortcode="your_shortcode"
firebase functions:config:set mpesa.passkey="your_passkey"
firebase functions:config:set mpesa.callback_url="your_callback_url"
```

## Testing

### 1. Local Testing with Emulators
```bash
# Start emulators
firebase emulators:start

# Run tests
flutter test
```

### 2. Integration Testing
- Test payment flows with M-Pesa sandbox
- Verify webhook handling
- Test teacher verification workflow
- Validate booking and lesson creation

### 3. Production Testing
- Deploy to staging environment first
- Test with real payment processing
- Monitor performance and errors
- Gradual rollout to users

## Monitoring

### 1. Firebase Console
- Monitor Cloud Functions logs
- Track Firestore query performance
- Monitor app usage and errors
- Set up alerts for critical issues

### 2. Performance Monitoring
- Monitor function execution times
- Track database query performance
- Monitor app startup time
- Set up performance budgets

### 3. Error Tracking
- Configure error reporting
- Set up alerts for critical errors
- Monitor user-reported issues
- Track error rates and trends

## Maintenance

### 1. Regular Updates
- Update Flutter and Firebase dependencies
- Monitor for security patches
- Update Cloud Functions as needed
- Review and optimize Firestore indexes

### 2. Performance Optimization
- Monitor query performance
- Optimize database indexes
- Reduce function cold start times
- Implement caching strategies

### 3. Cost Management
- Monitor Firestore usage
- Optimize function execution
- Clean up unused resources
- Set up budget alerts

## Troubleshooting

### Common Issues

1. **Functions Deployment Fails**
   - Check Node.js version compatibility
   - Verify Firebase CLI is up to date
   - Check for syntax errors in functions
   - Review package.json dependencies

2. **Firestore Indexes Not Created**
   - Verify the indexes file exists
   - Check file permissions
   - Ensure proper Firebase project access
   - Run deployment script with proper permissions

3. **Payment Webhook Issues**
   - Verify M-Pesa configuration
   - Check webhook URL accessibility
   - Test with M-Pesa sandbox
   - Monitor webhook logs

### Debug Commands

```bash
# View function logs
firebase functions:log

# View Firestore logs
firebase firestore:log

# Test functions locally
firebase functions:shell

# Check deployment status
firebase deploy --json
```

## Security Considerations

1. **Data Validation**
   - Validate all user inputs
   - Sanitize file uploads
   - Verify payment amounts
   - Check user permissions

2. **Access Control**
   - Implement proper Firebase security rules
   - Use Firebase authentication
   - Set up custom claims for user roles
   - Monitor for unauthorized access

3. **Payment Security**
   - Use HTTPS for all payment endpoints
   - Validate webhook signatures
   - Store payment data securely
   - Implement proper error handling

## Backup and Recovery

### 1. Data Backup
- Regular Firestore backups
- Cloud Functions code backup
- Configuration files backup
- Security rules backup

### 2. Disaster Recovery
- Set up automated backups
- Create recovery procedures
- Test backup restoration
- Document recovery processes

## Support

For issues and questions:
1. Check the Firebase documentation
2. Review the troubleshooting section
3. Monitor Firebase console logs
4. Contact Firebase support if needed

---

**Note**: Always test deployments in a staging environment before deploying to production.