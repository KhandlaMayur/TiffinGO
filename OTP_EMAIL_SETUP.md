# OTP Email Setup Guide

## How OTP Now Works:

1. **User enters email and clicks "Register" or "Login"**
   - OTP code is generated (6 digits)
   - OTP is stored locally with 5-minute expiry
   - OTP request is sent to Firestore

2. **Cloud Function automatically sends email to Gmail**
   - Firebase Cloud Function picks up the request
   - Email is sent to user's Gmail inbox
   - User sees the OTP code in their email

3. **User enters OTP in the app**
   - Compares with stored OTP
   - If correct → proceeds to next step
   - If wrong → shows error message

---

## Setup Instructions:

### Step 1: Get Gmail App Password

1. Go to: https://myaccount.google.com/apppasswords
2. Select "Mail" and "Windows Computer" (or your platform)
3. Google will generate a 16-character password
4. Copy this password (you'll need it in Step 3)

---

### Step 2: Update Firebase Rules (Firestore)

Go to Firebase Console → Firestore → Rules and replace with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow anyone to create OTP requests
    match /otp_requests/{document=**} {
      allow create: if request.auth == null || request.auth != null;
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to access other collections
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

### Step 3: Deploy Cloud Function

1. **Open Terminal/PowerShell** in your project folder

2. **Navigate to functions directory:**
   ```
   cd functions
   ```

3. **Initialize Firebase Functions** (if not done):
   ```
   npm install firebase-functions firebase-admin nodemailer
   ```

4. **Create `.env` file in functions folder:**
   ```
   GMAIL_USER=your-email@gmail.com
   GMAIL_PASSWORD=your-16-char-app-password
   ```

5. **Update index.js with environment variables:**
   - Open `functions/index.js` or create it if doesn't exist
   - Add the Cloud Function code from `send_otp_email.js`

6. **Deploy to Firebase:**
   ```
   firebase deploy --only functions
   ```

---

### Step 4: Test the Flow

1. **Run your Flutter app**
2. **Go to Register page**
3. **Fill all details and click "Register"**
4. **You should see:**
   - Console message: `✓ OTP Email will be sent to: email@gmail.com`
   - OTP code printed to console: `OTP Code: 123456`
5. **Check your Gmail inbox** - you'll receive the OTP email
6. **Enter the OTP in the app**
7. **Verify and proceed to login page**

---

## What Happens in Background:

```
Register Screen
     ↓
Generate OTP (e.g., 123456)
     ↓
Store in local memory (with 5-min expiry)
     ↓
Save request to Firestore
     ↓
Cloud Function triggers automatically
     ↓
Cloud Function sends email to Gmail
     ↓
User receives email with OTP code
     ↓
User enters OTP in app
     ↓
App verifies against stored OTP
     ↓
If correct → Navigate to Login/Home
```

---

## Troubleshooting:

### Email not received?
1. Check spam folder in Gmail
2. Check Firestore console - is `otp_requests` collection created?
3. Check Firebase Cloud Functions logs in Firebase Console

### Cloud Function not triggering?
1. Make sure Firestore Rules allow write to `otp_requests`
2. Check Firebase Functions tab for errors
3. Deploy again: `firebase deploy --only functions`

### OTP code not working?
1. Make sure you're entering exactly 6 digits
2. Check if 5 minutes haven't passed
3. Try resending OTP

---

## Deployment Summary:

✅ App sends OTP to Firestore  
✅ Cloud Function reads from Firestore  
✅ Cloud Function sends real Gmail email  
✅ User receives OTP in Gmail  
✅ User enters OTP in app  
✅ App navigates to Login/Home on success  

---

## For Production:

Instead of App Password, use:
- **Firebase Extensions**: Email extension (managed by Google)
- **Third-party services**: SendGrid, Twilio, AWS SES
- **More secure**: Environment variables in Firebase Console

But for now, App Password method is simple and works perfectly!
