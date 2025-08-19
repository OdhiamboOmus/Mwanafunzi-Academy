// Cloud Functions entry point
const functions = require('firebase-functions');

// Import payment webhook handler
const paymentWebhook = require('./paymentWebhook');

// Import payout processor
const payoutProcessor = require('./payoutProcessor');

// Import teacher verification claims handler
const teacherVerificationClaims = require('./teacherVerificationClaims');

// Export payment webhook function
exports.handleMpesaWebhook = paymentWebhook.handleMpesaWebhook;

// Export payout processor function
exports.processPayout = payoutProcessor.processPayout;

// Export teacher verification claims functions
exports.setTeacherVerificationClaims = teacherVerificationClaims.setTeacherVerificationClaims;
exports.assignTeacherClaimsManually = teacherVerificationClaims.assignTeacherClaimsManually;
exports.batchAssignTeacherClaims = teacherVerificationClaims.batchAssignTeacherClaims;

// Log function initialization
console.log('Cloud Functions initialized successfully');