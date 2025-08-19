// Firebase Cloud Function for M-Pesa payment webhook processing
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const logger = require('firebase-functions/logger');

// Initialize Firebase Admin
admin.initializeApp();

// Get Firestore instance
const db = admin.firestore();

/**
 * Handle M-Pesa payment webhook with comprehensive logging
 * 
 * This function processes incoming M-Pesa webhook notifications,
 * verifies payment status, updates transactions, activates bookings,
 * and sends notifications.
 */
exports.handleMpesaWebhook = functions.https.onRequest(async (req, res) => {
  logger.info('handleMpesaWebhook: Starting webhook processing', { 
    headers: req.headers,
    body: req.body 
  });

  try {
    // Verify webhook signature (in production, implement proper signature verification)
    const payload = req.body;
    logger.info('handleMpesaWebhook: Processing webhook payload', { payload });

    // Extract payment details
    const mpesaTransactionId = payload.TransactionID;
    const resultCode = payload.ResultCode;
    const resultDesc = payload.ResultDesc;
    const checkoutRequestID = payload.CheckoutRequestID;
    const mpesaReceiptNumber = payload.MpesaReceiptNumber;
    const phoneNumber = payload.MSISDN;

    logger.info('handleMpesaWebhook: Extracted payment details', {
      mpesaTransactionId,
      resultCode,
      resultDesc,
      checkoutRequestID,
      mpesaReceiptNumber,
      phoneNumber
    });

    // Find the transaction by M-Pesa transaction ID
    const transactionQuery = await db
      .collection('transactions')
      .where('mpesaTransactionId', '==', mpesaTransactionId)
      .limit(1)
      .get();

    if (transactionQuery.empty) {
      logger.error('handleMpesaWebhook: Transaction not found', { mpesaTransactionId });
      return res.status(404).json({ 
        success: false, 
        message: 'Transaction not found' 
      });
    }

    const transactionDoc = transactionQuery.docs[0];
    const transaction = transactionDoc.data();
    const transactionId = transactionDoc.id;

    logger.info('handleMpesaWebhook: Found transaction', { 
      transactionId,
      bookingId: transaction.bookingId,
      amount: transaction.amount 
    });

    // Update transaction status based on M-Pesa response
    const status = resultCode === '0' ? 'completed' : 'failed';
    const providerResponse = {
      resultCode,
      resultDesc,
      checkoutRequestID,
      mpesaReceiptNumber,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    logger.info('handleMpesaWebhook: Updating transaction status', {
      transactionId,
      status,
      providerResponse
    });

    await transactionDoc.ref.update({
      status,
      providerResponse,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // If payment is successful, activate booking and create ledger entries
    if (resultCode === '0') {
      logger.info('handleMpesaWebhook: Payment successful, activating booking', {
        bookingId: transaction.bookingId,
        amount: transaction.amount
      });

      // Activate the booking
      await activateBooking(transaction.bookingId, transaction.amount);

      // Create platform ledger entries
      await createPlatformLedgerEntries(transaction);

      // Send notifications
      await sendPaymentSuccessNotifications(transaction);

      logger.info('handleMpesaWebhook: Booking activated and notifications sent', {
        bookingId: transaction.bookingId
      });
    } else {
      logger.warn('handleMpesaWebhook: Payment failed', {
        transactionId,
        resultDesc
      });

      // Send payment failure notification
      await sendPaymentFailureNotification(transaction, resultDesc);
    }

    // Create immutable platform ledger entry for this transaction
    await createPlatformLedgerEntry({
      type: 'credit',
      amount: transaction.amount * 0.20, // 20% platform fee
      transactionId: transactionId,
      description: `Platform fee for booking ${transaction.bookingId}`,
    });

    logger.info('handleMpesaWebhook: Webhook processing completed successfully', {
      transactionId,
      status
    });

    res.status(200).json({ 
      success: true, 
      message: 'Webhook processed successfully',
      transactionId,
      status
    });

  } catch (error) {
    logger.error('handleMpesaWebhook: Error processing webhook', { error: error.message, stack: error.stack });
    
    res.status(500).json({ 
      success: false, 
      message: 'Internal server error',
      error: error.message 
    });
  }
});

/**
 * Activate booking and generate Zoom links
 */
async function activateBooking(bookingId, amount) {
  logger.info('activateBooking: Activating booking', { bookingId, amount });

  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingDoc = await bookingRef.get();

  if (!bookingDoc.exists) {
    throw new Error(`Booking not found: ${bookingId}`);
  }

  const booking = bookingDoc.data();

  // Update booking status to paid
  await bookingRef.update({
    status: 'paid',
    paidAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Generate Zoom link for the booking
  const zoomLink = generateZoomLink(bookingId);
  
  await bookingRef.update({
    zoomLink: zoomLink,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Update all related lessons to active status
  const lessonsRef = db.collection('lessons').where('bookingId', '==', bookingId);
  const lessonsSnapshot = await lessonsRef.get();
  
  const batch = db.batch();
  lessonsSnapshot.docs.forEach(doc => {
    batch.update(doc.ref, {
      status: 'active',
      zoomLink: zoomLink,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  
  await batch.commit();

  logger.info('activateBooking: Booking activated successfully', { 
    bookingId, 
    zoomLink,
    lessonsUpdated: lessonsSnapshot.docs.length 
  });
}

/**
 * Generate Zoom link for booking
 */
function generateZoomLink(bookingId) {
  // In production, integrate with Zoom API
  // For now, generate a mock Zoom link
  const meetingId = Math.floor(Math.random() * 900000000) + 100000000;
  return `https://zoom.us/j/${meetingId}?pwd=${bookingId.substring(0, 8)}`;
}

/**
 * Create platform ledger entries for successful payment
 */
async function createPlatformLedgerEntries(transaction) {
  logger.info('createPlatformLedgerEntries: Creating ledger entries', { 
    transactionId: transaction.id,
    amount: transaction.amount 
  });

  const platformFee = transaction.amount * 0.20; // 20% platform fee
  const teacherPayout = transaction.amount - platformFee;

  // Create platform fee entry
  await createPlatformLedgerEntry({
    type: 'credit',
    amount: platformFee,
    transactionId: transaction.id,
    description: `Platform fee for booking ${transaction.bookingId}`,
  });

  // Create teacher payout entry
  await createPlatformLedgerEntry({
    type: 'debit',
    amount: teacherPayout,
    transactionId: transaction.id,
    teacherId: transaction.teacherId,
    description: `Teacher payout for booking ${transaction.bookingId}`,
  });

  logger.info('createPlatformLedgerEntries: Ledger entries created', {
    platformFee,
    teacherPayout
  });
}

/**
 * Create single platform ledger entry
 */
async function createPlatformLedgerEntry(entryData) {
  logger.info('createPlatformLedgerEntry: Creating ledger entry', entryData);

  // Get current balance
  const ledgerSnapshot = await db
    .collection('platform_ledger')
    .orderBy('createdAt', 'desc')
    .limit(1)
    .get();

  let currentBalance = 0;
  if (!ledgerSnapshot.empty) {
    currentBalance = ledgerSnapshot.docs[0].data().balance;
  }

  // Calculate new balance
  const newBalance = entryData.type === 'credit' 
    ? currentBalance + entryData.amount 
    : currentBalance - entryData.amount;

  // Create ledger entry
  const ledgerEntry = {
    id: `PLG${Date.now()}`,
    transactionId: entryData.transactionId,
    type: entryData.type,
    amount: entryData.amount,
    balance: newBalance,
    description: entryData.description,
    teacherId: entryData.teacherId || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection('platform_ledger').doc(ledgerEntry.id).set(ledgerEntry);

  logger.info('createPlatformLedgerEntry: Ledger entry created', {
    entryId: ledgerEntry.id,
    newBalance
  });
}

/**
 * Send payment success notifications
 */
async function sendPaymentSuccessNotifications(transaction) {
  logger.info('sendPaymentSuccessNotifications: Sending notifications', { 
    transactionId: transaction.id,
    bookingId: transaction.bookingId 
  });

  try {
    // Get booking details
    const bookingDoc = await db.collection('bookings').doc(transaction.bookingId).get();
    const booking = bookingDoc.data();

    // Get teacher details
    const teacherDoc = await db.collection('teachers').doc(booking.teacherId).get();
    const teacher = teacherDoc.data();

    // Get parent details
    const parentDoc = await db.collection('parents').doc(booking.parentId).get();
    const parent = parentDoc.data();

    // Send notification to teacher
    if (teacher && teacher.fcmToken) {
      await sendNotification(
        teacher.fcmToken,
        'New Booking Confirmed!',
        `You have a new booking with ${parent?.fullName || 'a parent'} for ${booking.subject}. Check your dashboard for details.`,
        {
          type: 'booking',
          bookingId: transaction.bookingId,
          teacherId: booking.teacherId,
        }
      );
    }

    // Send notification to parent
    if (parent && parent.fcmToken) {
      await sendNotification(
        parent.fcmToken,
        'Booking Confirmed!',
        `Your booking with ${teacher?.fullName || 'the teacher'} for ${booking.subject} has been confirmed. Check your email for the Zoom link.`,
        {
          type: 'booking',
          bookingId: transaction.bookingId,
          parentId: booking.parentId,
        }
      );
    }

    logger.info('sendPaymentSuccessNotifications: Notifications sent successfully');

  } catch (error) {
    logger.error('sendPaymentSuccessNotifications: Error sending notifications', { error: error.message });
  }
}

/**
 * Send payment failure notification
 */
async function sendPaymentFailureNotification(transaction, reason) {
  logger.info('sendPaymentFailureNotification: Sending failure notification', { 
    transactionId: transaction.id,
    reason 
  });

  try {
    // Get booking details
    const bookingDoc = await db.collection('bookings').doc(transaction.bookingId).get();
    const booking = bookingDoc.data();

    // Get parent details
    const parentDoc = await db.collection('parents').doc(booking.parentId).get();
    const parent = parentDoc.data();

    // Send notification to parent
    if (parent && parent.fcmToken) {
      await sendNotification(
        parent.fcmToken,
        'Payment Failed',
        `Your payment for booking with ${booking.subject} failed. Reason: ${reason}. Please try again.`,
        {
          type: 'payment_failed',
          bookingId: transaction.bookingId,
          parentId: booking.parentId,
        }
      );
    }

    logger.info('sendPaymentFailureNotification: Failure notification sent');

  } catch (error) {
    logger.error('sendPaymentFailureNotification: Error sending failure notification', { error: error.message });
  }
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