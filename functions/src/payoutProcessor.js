// Firebase Cloud Function for automated teacher payout processing
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const logger = require('firebase-functions/logger');

// Initialize Firebase Admin
admin.initializeApp();

// Get Firestore instance
const db = admin.firestore();

/**
 * Process teacher payouts when lessons are completed
 * 
 * This function triggers when a lesson status is updated to 'completed'.
 * It checks if all lessons in a booking are completed, calculates the payout,
 * and initiates M-Pesa B2C transfer.
 */
exports.processPayout = functions.firestore
  .document('lessons/{lessonId}')
  .onUpdate(async (change, context) => {
    const lessonId = context.params.lessonId;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    logger.info('processPayout: Lesson status update detected', {
      lessonId,
      beforeStatus: beforeData.status,
      afterStatus: afterData.status
    });

    // Only process if status changed to 'completed'
    if (beforeData.status === 'completed' || afterData.status !== 'completed') {
      logger.info('processPayout: Lesson not newly completed, skipping processing');
      return null;
    }

    try {
      const bookingId = afterData.bookingId;
      const teacherId = afterData.teacherId;

      logger.info('processPayout: Processing completed lesson', {
        lessonId,
        bookingId,
        teacherId
      });

      // Check if all lessons in the booking are completed
      const allCompleted = await areAllLessonsCompleted(bookingId);
      
      if (!allCompleted) {
        logger.info('processPayout: Not all lessons completed, skipping payout');
        return null;
      }

      // Get booking details
      const bookingDoc = await db.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        logger.error('processPayout: Booking not found', { bookingId });
        return null;
      }

      const booking = bookingDoc.data();

      // Calculate teacher payout (80% of total amount)
      const teacherPayout = booking.teacherPayout;

      logger.info('processPayout: Calculating payout', {
        bookingId,
        teacherId,
        teacherPayout,
        totalAmount: booking.totalAmount
      });

      // Check if payout already processed
      const existingPayout = await db
        .collection('transactions')
        .where('type', '==', 'payout')
        .where('bookingId', '==', bookingId)
        .where('status', '==', 'completed')
        .limit(1)
        .get();

      if (!existingPayout.empty) {
        logger.info('processPayout: Payout already processed', { bookingId });
        return null;
      }

      // Create payout transaction
      const payoutTransactionId = await createPayoutTransaction({
        bookingId,
        teacherId,
        amount: teacherPayout,
      });

      logger.info('processPayout: Payout transaction created', {
        payoutTransactionId,
        teacherPayout
      });

      // Process M-Pesa B2C transfer
      const payoutSuccess = await processMpesaB2CTransfer({
        teacherId,
        amount: teacherPayout,
        payoutTransactionId,
      });

      if (payoutSuccess) {
        // Update payout transaction status
        await db.collection('transactions').doc(payoutTransactionId).update({
          status: 'completed',
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update booking status to completed
        await bookingDoc.ref.update({
          status: 'completed',
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Send payout confirmation notification
        await sendPayoutConfirmationNotification({
          teacherId,
          bookingId,
          amount: teacherPayout,
          payoutTransactionId,
        });

        logger.info('processPayout: Payout processed successfully', {
          payoutTransactionId,
          teacherPayout
        });
      } else {
        // Update payout transaction status to failed
        await db.collection('transactions').doc(payoutTransactionId).update({
          status: 'failed',
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Schedule retry (in production, implement proper retry mechanism)
        await schedulePayoutRetry(payoutTransactionId);

        logger.error('processPayout: Payout failed', {
          payoutTransactionId,
          teacherPayout
        });
      }

      return null;

    } catch (error) {
      logger.error('processPayout: Error processing payout', { 
        error: error.message, 
        stack: error.stack 
      });
      return null;
    }
  });

/**
 * Check if all lessons in a booking are completed
 */
async function areAllLessonsCompleted(bookingId) {
  logger.info('areAllLessonsCompleted: Checking lessons completion', { bookingId });

  const lessonsSnapshot = await db
    .collection('lessons')
    .where('bookingId', '==', bookingId)
    .get();

  const totalLessons = lessonsSnapshot.docs.length;
  const completedLessons = lessonsSnapshot.docs.filter(doc => 
    doc.data().status === 'completed'
  ).length;

  const allCompleted = completedLessons === totalLessons;

  logger.info('areAllLessonsCompleted: Completion check result', {
    bookingId,
    totalLessons,
    completedLessons,
    allCompleted
  });

  return allCompleted;
}

/**
 * Create payout transaction record
 */
async function createPayoutTransaction({ bookingId, teacherId, amount }) {
  logger.info('createPayoutTransaction: Creating payout transaction', {
    bookingId,
    teacherId,
    amount
  });

  const transactionId = `Payout${Date.now()}`;
  
  const transaction = {
    id: transactionId,
    type: 'payout',
    bookingId: bookingId,
    teacherId: teacherId,
    amount: amount,
    mpesaTransactionId: '',
    mpesaReceiptNumber: '',
    phoneNumber: '', // Will be populated from teacher profile
    status: 'pending',
    providerResponse: {},
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection('transactions').doc(transactionId).set(transaction);

  logger.info('createPayoutTransaction: Payout transaction created', {
    transactionId
  });

  return transactionId;
}

/**
 * Process M-Pesa B2C transfer
 */
async function processMpesaB2CTransfer({ teacherId, amount, payoutTransactionId }) {
  logger.info('processMpesaB2CTransfer: Processing B2C transfer', {
    teacherId,
    amount,
    payoutTransactionId
  });

  try {
    // Get teacher profile for phone number
    const teacherDoc = await db.collection('teachers').doc(teacherId).get();
    if (!teacherDoc.exists) {
      throw new Error(`Teacher not found: ${teacherId}`);
    }

    const teacher = teacherDoc.data();
    const phoneNumber = teacher.phone;

    if (!phoneNumber) {
      throw new Error(`Phone number not found for teacher: ${teacherId}`);
    }

    // Format phone number for M-Pesa
    const formattedPhone = formatPhoneNumber(phoneNumber);

    logger.info('processMpesaB2CTransfer: Formatted phone number', {
      teacherId,
      originalPhone: phoneNumber,
      formattedPhone
    });

    // Simulate M-Pesa B2C API call (in production, integrate with actual M-Pesa API)
    const mpesaResponse = await simulateMpesaB2CApi({
      phoneNumber: formattedPhone,
      amount: amount,
      transactionId: payoutTransactionId,
    });

    if (mpesaResponse.success) {
      // Update payout transaction with M-Pesa details
      await db.collection('transactions').doc(payoutTransactionId).update({
        mpesaTransactionId: mpesaResponse.transactionId,
        mpesaReceiptNumber: mpesaResponse.receiptNumber,
        status: 'completed',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info('processMpesaB2CTransfer: B2C transfer successful', {
        teacherId,
        amount,
        mpesaTransactionId: mpesaResponse.transactionId
      });

      return true;
    } else {
      // Update payout transaction with failure details
      await db.collection('transactions').doc(payoutTransactionId).update({
        status: 'failed',
        providerResponse: {
          error: mpesaResponse.error,
          errorCode: mpesaResponse.errorCode,
        },
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.error('processMpesaB2CTransfer: B2C transfer failed', {
        teacherId,
        amount,
        error: mpesaResponse.error
      });

      return false;
    }

  } catch (error) {
    logger.error('processMpesaB2CTransfer: Error processing B2C transfer', {
      error: error.message,
      teacherId,
      amount
    });

    // Update payout transaction with error
    await db.collection('transactions').doc(payoutTransactionId).update({
      status: 'failed',
      providerResponse: {
        error: error.message,
        errorCode: 'INTERNAL_ERROR',
      },
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return false;
  }
}

/**
 * Format phone number for M-Pesa
 */
function formatPhoneNumber(phone) {
  // Remove all non-digit characters
  const digits = phone.replace(/\D/g, '');
  
  // Ensure it starts with country code
  if (digits.startsWith('254')) {
    return `+${digits}`;
  } else if (digits.startsWith('0')) {
    return `+254${digits.substring(1)}`;
  } else if (digits.startsWith('+')) {
    return digits;
  } else {
    return `+254${digits}`;
  }
}

/**
 * Simulate M-Pesa B2C API call
 */
async function simulateMpesaB2CApi({ phoneNumber, amount, transactionId }) {
  logger.info('simulateMpesaB2CApi: Simulating B2C API call', {
    phoneNumber,
    amount,
    transactionId
  });

  // Simulate network delay
  await new Promise(resolve => setTimeout(resolve, 3000));

  // Simulate success/failure based on amount
  const success = amount > 0 && amount <= 50000; // Limit for demo purposes
  
  if (success) {
    return {
      success: true,
      transactionId: `B2C${Date.now()}`,
      receiptNumber: `REC${Date.now()}`,
      responseCode: '0',
      responseDescription: 'Success',
    };
  } else {
    return {
      success: false,
      error: amount > 50000 ? 'Amount exceeds limit' : 'Invalid amount',
      errorCode: amount > 50000 ? 'AMOUNT_EXCEEDS_LIMIT' : 'INVALID_AMOUNT',
    };
  }
}

/**
 * Send payout confirmation notification
 */
async function sendPayoutConfirmationNotification({ teacherId, bookingId, amount, payoutTransactionId }) {
  logger.info('sendPayoutConfirmationNotification: Sending notification', {
    teacherId,
    bookingId,
    amount,
    payoutTransactionId
  });

  try {
    // Get teacher details
    const teacherDoc = await db.collection('teachers').doc(teacherId).get();
    const teacher = teacherDoc.data();

    // Get booking details
    const bookingDoc = await db.collection('bookings').doc(bookingId).get();
    const booking = bookingDoc.data();

    if (teacher && teacher.fcmToken) {
      await sendNotification(
        teacher.fcmToken,
        'Payout Processed Successfully!',
        `Your payout of Ksh ${amount.toFixed(2)} for ${booking.subject} has been processed to your M-Pesa account. Transaction ID: ${payoutTransactionId}`,
        {
          type: 'payout',
          payoutTransactionId: payoutTransactionId,
          teacherId: teacherId,
          amount: amount,
        }
      );
    }

    logger.info('sendPayoutConfirmationNotification: Notification sent successfully');

  } catch (error) {
    logger.error('sendPayoutConfirmationNotification: Error sending notification', { error: error.message });
  }
}

/**
 * Schedule payout retry for failed transactions
 */
async function schedulePayoutRetry(payoutTransactionId) {
  logger.info('schedulePayoutRetry: Scheduling payout retry', {
    payoutTransactionId
  });

  // In production, implement proper retry mechanism with exponential backoff
  // For now, just log the retry scheduling
  
  // Schedule retry after 1 hour
  const retryTime = new Date(Date.now() + 60 * 60 * 1000);
  
  await db.collection('payout_retries').add({
    payoutTransactionId: payoutTransactionId,
    scheduledAt: admin.firestore.FieldValue.serverTimestamp(),
    retryAt: retryTime,
    attempts: 1,
    maxAttempts: 3,
  });

  logger.info('schedulePayoutRetry: Retry scheduled', {
    payoutTransactionId,
    retryTime
  });
}

/**
 * Send FCM notification
 */
async function sendNotification(token, title, body, data) {
  logger.info('sendNotification: Sending FCM notification', { token, title });

  const message = {
    token: token,
    notification: {
      title: title,
      body: body,
    },
    data: data,
    android: {
      priority: 'high',
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: title,
            body: body,
          },
          sound: 'default',
        },
      },
    },
  };

  try {
    await admin.messaging().send(message);
    logger.info('sendNotification: FCM notification sent successfully');
  } catch (error) {
    logger.error('sendNotification: Error sending FCM notification', { error: error.message });
  }
}