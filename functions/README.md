# Teacher Verification System - Cloud Functions

This directory contains the Cloud Functions for the teacher verification and payment processing system.

## Functions

### 1. Payment Webhook Handler (`paymentWebhook.js`)

**Purpose**: Handles incoming M-Pesa payment webhook notifications and processes payments.

**Features**:
- Verifies M-Pesa webhook signatures
- Updates transaction status based on payment response
- Activates bookings on successful payment
- Creates immutable financial ledger entries
- Sends notifications to teachers and parents
- Generates Zoom links for active bookings

**Trigger**: HTTP endpoint (`/handleMpesaWebhook`)

**Usage**:
```javascript
// Call the webhook handler
const response = await fetch('https://us-central1-your-project.cloudfunctions.net/handleMpesaWebhook', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(mpesaWebhookPayload),
});
```

### 2. Payout Processor (`payoutProcessor.js`)

**Purpose**: Automatically processes teacher payouts when lessons are completed.

**Features**:
- Triggers when lesson status changes to 'completed'
- Checks if all lessons in a booking are completed
- Calculates teacher payout (80% of total amount)
- Processes M-Pesa B2C transfers
- Handles payout failures with retry mechanism
- Sends payout confirmation notifications

**Trigger**: Firestore document update (`lessons/{lessonId}`)

**Usage**: Automatically triggered when a lesson is marked as completed.

## Setup Instructions

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Configure Firebase

Make sure you have the Firebase CLI installed and authenticated:

```bash
firebase login
firebase init functions
```

### 3. Deploy Functions

```bash
firebase deploy --only functions
```

### 4. Configure Environment Variables

Add the following environment variables to your Firebase project:

```bash
firebase functions:config:set mpesa.consumer_key="your_consumer_key"
firebase functions:config:set mpesa.consumer_secret="your_consumer_secret"
firebase functions:config:set mpesa.short_code="your_shortcode"
firebase functions:config:set mpesa.passkey="your_passkey"
firebase functions:config:set mpesa.callback_url="your_callback_url"
```

## Testing

### 1. Unit Tests

```bash
cd functions
npm test
```

### 2. Local Testing

```bash
firebase functions:shell
```

Then test the functions:

```javascript
// Test payment webhook
handleMpesaWebhook({ body: mockMpesaPayload });

// Test payout processor
processPayout({ before: { data: { status: 'scheduled' } }, after: { data: { status: 'completed' } } });
```

## Security Considerations

1. **Webhook Verification**: Always verify M-Pesa webhook signatures in production
2. **Rate Limiting**: Implement rate limiting for webhook endpoints
3. **Error Handling**: Comprehensive error handling with proper logging
4. **Data Validation**: Validate all incoming webhook data
5. **Access Control**: Ensure proper Firebase security rules are configured

## Monitoring and Logging

1. **Firebase Console**: Monitor function executions and logs
2. **Error Tracking**: Set up error tracking for production monitoring
3. **Performance Monitoring**: Monitor function execution times and memory usage
4. **Alerts**: Set up alerts for function failures

## Database Schema

### Collections Used

- `transactions`: Payment transaction records
- `bookings`: Booking information
- `lessons`: Individual lesson records
- `platform_ledger`: Immutable financial ledger entries
- `teachers`: Teacher profiles
- `parents`: Parent profiles

### Indexes

The `firestore.indexes.json` file contains optimized indexes for common queries.

## Troubleshooting

### Common Issues

1. **Function Timeout**: Increase timeout in `firebase.json` if needed
2. **Memory Issues**: Monitor memory usage and adjust allocation
3. **Permission Errors**: Ensure Firebase security rules are properly configured
4. **Webhook Failures**: Check webhook signatures and payload format

### Debug Mode

Enable debug logging by setting the log level:

```javascript
// In your function
logger.info('Debug message', { data });
```

## Future Enhancements

1. **Retry Mechanism**: Implement exponential backoff for failed payouts
2. **Batch Processing**: Process multiple payouts in a single function execution
3. **Advanced Analytics**: Add detailed analytics for payment processing
4. **Multi-Currency Support**: Support for multiple currencies
5. **Automated Disputes**: Automated dispute resolution system

## Support

For issues or questions:
1. Check the Firebase Console logs
2. Review the troubleshooting section
3. Contact the development team