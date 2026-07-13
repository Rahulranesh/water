const express = require('express');
const admin = require('firebase-admin');
const cron = require('node-cron');
const dns = require('dns');
require('dotenv').config();

// ── Initialize App ──────────────────────────────────────────────────────────
const app = express();
const PORT = process.env.PORT || 3000;

// ── Initialize Firebase Admin SDK ──────────────────────────────────────────
// When deploying to Render, upload your service-account.json and specify the path,
// or set the GOOGLE_APPLICATION_CREDENTIALS environment variable.
const serviceAccountPath = process.env.FIREBASE_CREDENTIALS_PATH || './service-account.json';

try {
  admin.initializeApp({
    credential: admin.credential.cert(require(serviceAccountPath)),
    // Optional: Database URL is not needed for Firestore, but good practice
    // databaseURL: "https://water-a75c6.firebaseio.com"
  });
  console.log('Firebase Admin SDK initialized successfully!');
} catch (error) {
  console.error('Error initializing Firebase Admin SDK:', error);
  console.log('Ensure service-account.json exists in this folder or FIREBASE_CREDENTIALS_PATH is set.');
}

const db = admin.firestore();

// ── Notification Core Logic ──────────────────────────────────────────────────

/**
 * Iterates through all users in Firestore, fetches current local weather,
 * and pushes customized temperature-aware notifications.
 */
async function processAndSendWeatherAlerts() {
  console.log('Starting hourly weather-hydration notification scan...');
  try {
    const usersSnapshot = await db.collection('users').get();
    if (usersSnapshot.empty) {
      console.log('No registered users found in Firestore database.');
      return;
    }

    let notificationsSent = 0;

    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const { fcmToken, latitude, longitude, deviceId } = userData;

      if (!fcmToken) {
        console.log(`Skipping device ${deviceId}: No FCM token registered.`);
        continue;
      }

      if (latitude === undefined || longitude === undefined || latitude === null || longitude === null) {
        console.log(`Skipping device ${deviceId}: Location coordinates not shared.`);
        continue;
      }

      try {
        // Fetch current temperature from Open-Meteo
        const weatherUrl = `https://api.open-meteo.com/v1/forecast?latitude=${latitude.toFixed(4)}&longitude=${longitude.toFixed(4)}&current_weather=true`;
        const response = await fetch(weatherUrl);
        if (!response.ok) {
          console.error(`Failed to fetch weather for coordinates (${latitude}, ${longitude})`);
          continue;
        }

        const weatherData = await response.json();
        const currentTemp = weatherData.current_weather.temperature;

        // Custom notification details based on temperature bands
        let title = '';
        let body = '';
        let shouldSend = false;

        if (currentTemp >= 38) {
          title = '🔥 Extreme Heat Advisory!';
          body = `It's a scorching ${currentTemp.round ? Math.round(currentTemp) : currentTemp}°C. Sip 300ml of chilled water every 45 mins to stay safe.`;
          shouldSend = true;
        } else if (currentTemp >= 30) {
          title = '☀️ Heat Hydration Alert';
          body = `It's warm out there (${Math.round(currentTemp)}°C). Your goal is bumped for heat — keep drinking water!`;
          shouldSend = true;
        } else if (currentTemp <= 12) {
          title = '❄️ Stay Hydrated in the Cold';
          body = `It's cool (${Math.round(currentTemp)}°C). Cold air dehydrates silently — don't forget your hydration logs!`;
          shouldSend = true;
        }

        if (shouldSend) {
          const message = {
            notification: {
              title: title,
              body: body,
            },
            token: fcmToken,
            android: {
              notification: {
                icon: '@mipmap/ic_launcher',
                color: '#00A8A8',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                },
              },
            },
          };

          await admin.messaging().send(message);
          notificationsSent++;
          console.log(`Successfully sent push alert to device ${deviceId} (Temp: ${currentTemp}°C)`);
        }
      } catch (userError) {
        console.error(`Error processing device ${deviceId}:`, userError.message);
      }
    }

    console.log(`Scan complete. Sent ${notificationsSent} weather push alerts.`);
  } catch (error) {
    console.error('Error during push notification execution scan:', error);
  }
}

// ── Cron Scheduling ──────────────────────────────────────────────────────────
// Schedule cron to run every hour on the hour (* 0 * * * * or 0 * * * *)
// We'll schedule for every hour. You can adjust this using standard cron syntax.
cron.schedule('0 * * * *', () => {
  processAndSendWeatherAlerts();
});

// ── Server HTTP Endpoints ────────────────────────────────────────────────────

// Render requires a running server web service to keep it active and pass health checks.
app.get('/', (req, res) => {
  res.send({
    status: 'online',
    message: 'HydroFlow FCM server is active and scheduling weather cron alerts.',
    time: new Date().toISOString()
  });
});

// Endpoint to trigger alerts manually for testing
app.post('/trigger-now', async (req, res) => {
  try {
    await processAndSendWeatherAlerts();
    res.send({ success: true, message: 'Weather push alert scan executed manually.' });
  } catch (error) {
    res.status(500).send({ success: false, error: error.message });
  }
});

// New endpoint: triggers an immediate test push to all users, ignoring weather logic
app.post('/test-push', async (req, res) => {
  console.log('Starting manual /test-push campaign...');
  try {
    const usersSnapshot = await db.collection('users').get();
    if (usersSnapshot.empty) {
      return res.status(404).send({ success: false, error: 'No registered devices found in Firestore.' });
    }

    let sent = 0;
    for (const doc of usersSnapshot.docs) {
      const { fcmToken, deviceId } = doc.data();
      if (!fcmToken) continue;

      const message = {
        notification: {
          title: '⚡ HydroFlow Live Push Test',
          body: 'Hello! This is a real-time push notification delivered directly from your Render backend!',
        },
        token: fcmToken,
        android: {
          notification: {
            icon: '@mipmap/ic_launcher',
            color: '#00A8A8',
          },
        },
      };

      await admin.messaging().send(message);
      sent++;
      console.log(`Test notification sent successfully to device ${deviceId}`);
    }

    res.send({ success: true, message: `Successfully pushed test notifications to ${sent} devices.` });
  } catch (error) {
    res.status(500).send({ success: false, error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}...`);
  console.log('Cron alert scheduler configured: Run check every hour.');
});
