const functions = require("firebase-functions");
const nodemailer = require("nodemailer");

// Configure your Gmail account
// Create an App Password: https://myaccount.google.com/apppasswords
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "your-email@gmail.com", // Replace with your Gmail
    pass: "your-app-password", // Replace with App Password
  },
});

// Cloud Function triggered when OTP request is added to Firestore
exports.sendOtpEmail = functions.firestore
  .document("otp_requests/{docId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const email = data.email;
    const otp = data.otp;

    const mailOptions = {
      from: "your-email@gmail.com", // Replace with your Gmail
      to: email,
      subject: "Your OTP Code - Tiffin App",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #1E3A8A 0%, #3B82F6 100%); padding: 20px; border-radius: 10px 10px 0 0; color: white; text-align: center;">
            <h2 style="margin: 0;">Tiffin App Verification</h2>
          </div>
          
          <div style="padding: 30px; background: #f8f9fa; border-radius: 0 0 10px 10px;">
            <p style="color: #333; font-size: 16px; margin-bottom: 20px;">
              Hello,
            </p>
            
            <p style="color: #333; font-size: 16px; margin-bottom: 30px;">
              Your verification code is:
            </p>
            
            <div style="background: white; padding: 20px; border-radius: 8px; text-align: center; margin-bottom: 30px; border: 2px solid #1E3A8A;">
              <h1 style="color: #1E3A8A; font-size: 48px; margin: 0; letter-spacing: 5px;">
                ${otp}
              </h1>
            </div>
            
            <p style="color: #666; font-size: 14px; margin-bottom: 10px;">
              ⏱️ This code will expire in <strong>5 minutes</strong>
            </p>
            
            <p style="color: #666; font-size: 14px; margin-bottom: 20px;">
              If you didn't request this code, please ignore this email.
            </p>
            
            <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
            
            <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
              © 2025 Tiffin App. All rights reserved.
            </p>
          </div>
        </div>
      `,
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log(`OTP email sent to ${email}`);

      // Mark as sent in Firestore
      await snap.ref.update({
        sent: true,
        sentAt: new Date(),
      });

      return { success: true };
    } catch (error) {
      console.error(`Failed to send email to ${email}:`, error);
      return { success: false, error: error.toString() };
    }
  });
