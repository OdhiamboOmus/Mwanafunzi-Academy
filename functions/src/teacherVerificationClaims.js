// Firebase Cloud Function for setting up teacher verification custom claims
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const logger = require('firebase-functions/logger');

// Initialize Firebase Admin
admin.initializeApp();

// Get Firestore instance
const db = admin.firestore();

/**
 * Set custom claims for teacher verification status
 * 
 * This function sets custom claims when a teacher's verification status changes
 * to 'verified' or 'rejected'. It also logs all claim assignments for debugging.
 */
exports.setTeacherVerificationClaims = functions.firestore
  .document('teachers/{teacherId}')
  .onUpdate(async (change, context) => {
    const teacherId = context.params.teacherId;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    debugPrint('setTeacherVerificationClaims: Teacher verification status update detected - TeacherID: ${teacherId}, Before: ${beforeData.verificationStatus}, After: ${afterData.verificationStatus}');
    logger.info('setTeacherVerificationClaims: Teacher verification status update detected', {
      teacherId,
      beforeStatus: beforeData.verificationStatus,
      afterStatus: afterData.verificationStatus
    });

    // Only process if verification status changed
    if (beforeData.verificationStatus === afterData.verificationStatus) {
      debugPrint('setTeacherVerificationClaims: Verification status unchanged, skipping claim assignment - TeacherID: ${teacherId}');
      logger.info('setTeacherVerificationClaims: Verification status unchanged, skipping claim assignment');
      return null;
    }

    try {
      const auth = admin.auth();
      const user = await auth.getUser(teacherId);

      debugPrint('setTeacherVerificationClaims: Retrieved user from Firebase Auth - TeacherID: ${teacherId}, Email: ${user.email}');
      logger.info('setTeacherVerificationClaims: Retrieved user from Firebase Auth', {
        teacherId,
        email: user.email,
        emailVerified: user.emailVerified
      });

      let customClaims = {
        role: 'teacher',
        verified: false,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      };

      // Set claims based on verification status
      if (afterData.verificationStatus === 'verified') {
        customClaims.verified = true;
        debugPrint('setTeacherVerificationClaims: Setting verified=true for teacher - TeacherID: ${teacherId}');
        logger.info('setTeacherVerificationClaims: Setting verified=true for teacher', { teacherId });
      } else if (afterData.verificationStatus === 'rejected') {
        customClaims.verified = false;
        customClaims.rejectionReason = afterData.rejectionReason || 'No reason provided';
        debugPrint('setTeacherVerificationClaims: Setting verified=false for rejected teacher - TeacherID: ${teacherId}, Reason: ${afterData.rejectionReason}');
        logger.info('setTeacherVerificationClaims: Setting verified=false for rejected teacher', {
          teacherId,
          rejectionReason: afterData.rejectionReason
        });
      }

      // Update custom claims
      await auth.setCustomUserClaims(teacherId, customClaims);

      debugPrint('setTeacherVerificationClaims: Custom claims updated successfully - TeacherID: ${teacherId}, Claims: ${JSON.stringify(customClaims)}');
      logger.info('setTeacherVerificationClaims: Custom claims updated successfully', {
        teacherId,
        customClaims,
        verificationStatus: afterData.verificationStatus
      });

      // Log the claim assignment for audit trail
      await logClaimAssignment(teacherId, customClaims, afterData.verificationStatus);

      return null;

    } catch (error) {
      debugPrint('setTeacherVerificationClaims: Error setting custom claims - TeacherID: ${teacherId}, Error: ${error.message}');
      logger.error('setTeacherVerificationClaims: Error setting custom claims', {
        error: error.message,
        stack: error.stack,
        teacherId
      });
      return null;
    }
  });

/**
 * Log custom claim assignments for audit trail
 */
async function logClaimAssignment(teacherId, customClaims, verificationStatus) {
  logger.info('logClaimAssignment: Logging claim assignment', {
    teacherId,
    verificationStatus,
    customClaims
  });

  try {
    const logEntry = {
      teacherId: teacherId,
      action: 'custom_claims_assigned',
      verificationStatus: verificationStatus,
      customClaims: customClaims,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      ipAddress: request?.ip || 'unknown', // Available in HTTP functions
      userAgent: request?.headers?.['user-agent'] || 'unknown' // Available in HTTP functions
    };

    await db.collection('admin_audit_logs').add(logEntry);

    logger.info('logClaimAssignment: Claim assignment logged successfully', {
      teacherId,
      verificationStatus
    });

  } catch (error) {
    logger.error('logClaimAssignment: Error logging claim assignment', {
      error: error.message,
      teacherId
    });
  }
}

/**
 * HTTP endpoint to manually trigger custom claims assignment
 * 
 * This endpoint allows admins to manually trigger custom claims assignment
 * for debugging purposes or bulk operations.
 */
exports.assignTeacherClaimsManually = functions.https.onRequest(async (req, res) => {
  logger.info('assignTeacherClaimsManually: Manual claims assignment request received', {
    headers: req.headers,
    body: req.body
  });

  try {
    // Verify admin access
    if (!req.headers.authorization || !req.headers.authorization.startsWith('Bearer ')) {
      logger.warn('assignTeacherClaimsManually: Missing or invalid authorization header');
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const idToken = req.headers.authorization.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    if (!decodedToken.admin) {
      logger.warn('assignTeacherClaimsManually: Non-admin user attempted access', { uid: decodedToken.uid });
      return res.status(403).json({ success: false, message: 'Forbidden' });
    }

    const { teacherId, forceUpdate = false } = req.body;

    if (!teacherId) {
      logger.warn('assignTeacherClaimsManually: Missing teacherId in request body');
      return res.status(400).json({ success: false, message: 'teacherId is required' });
    }

    logger.info('assignTeacherClaimsManually: Processing manual claim assignment', {
      teacherId,
      forceUpdate,
      adminUid: decodedToken.uid
    });

    // Get teacher document
    const teacherDoc = await db.collection('teachers').doc(teacherId).get();
    
    if (!teacherDoc.exists) {
      logger.error('assignTeacherClaimsManually: Teacher not found', { teacherId });
      return res.status(404).json({ success: false, message: 'Teacher not found' });
    }

    const teacherData = teacherDoc.data();
    const verificationStatus = teacherData.verificationStatus;

    logger.info('assignTeacherClaimsManually: Retrieved teacher data', {
      teacherId,
      verificationStatus,
      currentClaims: teacherData
    });

    // Only update if status is verified or if forceUpdate is true
    if (verificationStatus === 'verified' || forceUpdate) {
      const auth = admin.auth();
      const user = await auth.getUser(teacherId);

      let customClaims = {
        role: 'teacher',
        verified: verificationStatus === 'verified',
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      };

      if (verificationStatus === 'rejected') {
        customClaims.rejectionReason = teacherData.rejectionReason || 'No reason provided';
      }

      await auth.setCustomUserClaims(teacherId, customClaims);

      // Log the manual assignment
      await logClaimAssignment(teacherId, customClaims, verificationStatus);

      logger.info('assignTeacherClaimsManually: Manual claim assignment completed', {
        teacherId,
        customClaims,
        verificationStatus
      });

      return res.status(200).json({
        success: true,
        message: 'Custom claims assigned successfully',
        teacherId,
        customClaims
      });
    } else {
      logger.info('assignTeacherClaimsManually: Teacher not verified, skipping assignment', {
        teacherId,
        verificationStatus
      });

      return res.status(200).json({
        success: true,
        message: 'Teacher not verified, no claims assigned',
        teacherId,
        verificationStatus
      });
    }

  } catch (error) {
    logger.error('assignTeacherClaimsManually: Error processing manual assignment', {
      error: error.message,
      stack: error.stack
    });

    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

/**
 * Batch function to assign custom claims to multiple teachers
 * 
 * This function allows bulk assignment of custom claims for teachers
 * who may have missed the automatic assignment.
 */
exports.batchAssignTeacherClaims = functions.firestore
  .document('admin_audit_logs/{logId}')
  .onCreate(async (snap, context) => {
    const logData = snap.data();
    
    // Only process if this is a bulk assignment request
    if (logData.action !== 'bulk_claim_assignment_request') {
      return null;
    }

    logger.info('batchAssignTeacherClaims: Processing bulk claim assignment', {
      logId: context.params.logId,
      teacherIds: logData.teacherIds,
      totalCount: logData.teacherIds.length
    });

    try {
      const auth = admin.auth();
      const results = {
        success: 0,
        failed: 0,
        errors: []
      };

      // Process teachers in batches to avoid rate limiting
      const batchSize = 50;
      for (let i = 0; i < logData.teacherIds.length; i += batchSize) {
        const batch = logData.teacherIds.slice(i, i + batchSize);
        
        const promises = batch.map(async (teacherId) => {
          try {
            const teacherDoc = await db.collection('teachers').doc(teacherId).get();
            
            if (teacherDoc.exists) {
              const teacherData = teacherDoc.data();
              const verificationStatus = teacherData.verificationStatus;
              
              if (verificationStatus === 'verified' || verificationStatus === 'rejected') {
                let customClaims = {
                  role: 'teacher',
                  verified: verificationStatus === 'verified',
                  lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                };

                if (verificationStatus === 'rejected') {
                  customClaims.rejectionReason = teacherData.rejectionReason || 'No reason provided';
                }

                await auth.setCustomUserClaims(teacherId, customClaims);
                await logClaimAssignment(teacherId, customClaims, verificationStatus);
                
                results.success++;
                logger.debug('batchAssignTeacherClaims: Successfully assigned claims to teacher', { teacherId });
              } else {
                logger.debug('batchAssignTeacherClaims: Teacher not verified, skipping assignment', {
                  teacherId,
                  verificationStatus
                });
              }
            } else {
              throw new Error(`Teacher not found: ${teacherId}`);
            }
          } catch (error) {
            results.failed++;
            results.errors.push({ teacherId, error: error.message });
            logger.error('batchAssignTeacherClaims: Error assigning claims to teacher', {
              teacherId,
              error: error.message
            });
          }
        });

        await Promise.all(promises);
        
        // Small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 100));
      }

      // Log the results
      await db.collection('admin_audit_logs').add({
        action: 'bulk_claim_assignment_completed',
        results: results,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        originalRequestId: logData.requestId
      });

      logger.info('batchAssignTeacherClaims: Bulk assignment completed', {
        logId: context.params.logId,
        results
      });

      return null;

    } catch (error) {
      logger.error('batchAssignTeacherClaims: Error in bulk assignment', {
        error: error.message,
        stack: error.stack,
        logId: context.params.logId
      });
      return null;
    }
  });