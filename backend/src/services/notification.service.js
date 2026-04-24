const admin = require('../config/firebase');
const { query } = require('../config/postgres');

const sendPushNotification = async (firebaseUid, title, body, data = {}) => {
  try {
    // Get FCM token from Firestore (stored by Flutter app on login)
    const userDoc = await admin.firestore().collection('users').doc(firebaseUid).get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return;

    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data,
    });
    console.log(`📲 Notification sent to ${firebaseUid}`);
  } catch (err) {
    console.error('Notification error:', err.message);
  }
};

const notifyIncompleteUsers = async () => {
  try {
    const rows = await query(
      `SELECT firebase_uid, current_state FROM users
       WHERE notifications_enabled = TRUE
       AND current_state IN ('REGISTRATION', 'VERIFICATION', 'CHECK_STATUS')`
    );

    for (const user of rows) {
      const messages = {
        REGISTRATION: { title: '📋 Complete your registration', body: 'You haven\'t finished registering to vote yet!' },
        CHECK_STATUS: { title: '🔍 Check your voter status', body: 'Find out if you\'re on the electoral roll.' },
        VERIFICATION: { title: '✅ Verify your details', body: 'One step left before you\'re ready to vote!' },
      };
      const msg = messages[user.current_state];
      if (msg) await sendPushNotification(user.firebase_uid, msg.title, msg.body);
    }
  } catch (err) {
    console.error('Error notifying incomplete users:', err.message);
  }
};

module.exports = { sendPushNotification, notifyIncompleteUsers };