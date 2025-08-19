// Cloud Functions entry point
const functions = require('firebase-functions');

// Import payment webhook handler
const paymentWebhook = require('./paymentWebhook');

// Import payout processor
const payoutProcessor = require('./payoutProcessor');

// Export payment webhook function
exports.handleMpesaWebhook = paymentWebhook.handleMpesaWebhook;

// Export payout processor function
exports.processPayout = payoutProcessor.processPayout;

// Log function initialization
console.log('Cloud Functions initialized successfully');