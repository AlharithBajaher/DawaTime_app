const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions/logger");
const { defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const APP_NAME = "DawaTime";
const APP_URL = "https://dawatime.app";

const gmailEmail = defineString("GMAIL_EMAIL");
const gmailPass = defineString("GMAIL_PASS");

function createTransporter() {
  const email = gmailEmail.value();
  const pass = gmailPass.value();
  if (!email || !pass) {
    throw new Error(
      'Gmail credentials not configured. Run:\n' +
      '  firebase functions:config:set gmail.email="YOUR_GMAIL" gmail.pass="YOUR_APP_PASSWORD"'
    );
  }
  return nodemailer.createTransport({
    service: "gmail",
    auth: { user: email, pass },
  });
}

function formatDate(date) {
  if (!date) return "N/A";
  return new Date(date).toLocaleString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function buildPharmacistEmail(user) {
  const pharmacyInfo = [
    user.pharmacyName && `🏪 Pharmacy: ${user.pharmacyName}`,
    user.pharmacyLocation && `📍 Location: ${user.pharmacyLocation}`,
    user.pharmacyPhone && `📞 Phone: ${user.pharmacyPhone}`,
  ]
    .filter(Boolean)
    .join("<br>");

  return {
    subject: `🔔 New Pharmacist Registration - ${user.name}`,
    html: `
      <div dir="rtl" style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background: #f9f9f9;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 12px 12px 0 0; text-align: center;">
          <h1 style="color: #fff; margin: 0; font-size: 24px;">🆕 New Pharmacist Registration</h1>
          <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0;">${APP_NAME} Admin Notification</p>
        </div>
        <div style="background: #fff; padding: 30px; border-radius: 0 0 12px 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.08);">
          <p style="color: #e74c3c; font-weight: bold; font-size: 16px;">⚠️ This pharmacist requires your approval before they can access the platform.</p>
          <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
            <tr><td style="padding: 10px; border-bottom: 1px solid #eee; font-weight: bold; color: #555;">Name</td><td style="padding: 10px; border-bottom: 1px solid #eee;">${user.name}</td></tr>
            <tr><td style="padding: 10px; border-bottom: 1px solid #eee; font-weight: bold; color: #555;">Username</td><td style="padding: 10px; border-bottom: 1px solid #eee;">${user.username}</td></tr>
            <tr><td style="padding: 10px; border-bottom: 1px solid #eee; font-weight: bold; color: #555;">Email</td><td style="padding: 10px; border-bottom: 1px solid #eee;"><a href="mailto:${user.email}">${user.email}</a></td></tr>
            <tr><td style="padding: 10px; border-bottom: 1px solid #eee; font-weight: bold; color: #555;">Auth Provider</td><td style="padding: 10px; border-bottom: 1px solid #eee;">${user.authProvider}</td></tr>
            <tr><td style="padding: 10px; border-bottom: 1px solid #eee; font-weight: bold; color: #555;">Registered At</td><td style="padding: 10px; border-bottom: 1px solid #eee;">${formatDate(user.createdAt)}</td></tr>
            ${pharmacyInfo ? `<tr><td style="padding: 10px; font-weight: bold; color: #555;">Pharmacy Details</td><td style="padding: 10px;">${pharmacyInfo}</td></tr>` : ""}
          </table>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${APP_URL}" style="display: inline-block; background: #667eea; color: #fff; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-size: 16px; font-weight: bold;">Open Admin Dashboard to Approve</a>
          </div>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <div style="text-align: right;">
            <h3 style="color: #333;">تسجيل صيدلي جديد</h3>
            <p style="color: #e74c3c; font-weight: bold;">⚠️ هذا الحساب يحتاج موافقتك قبل أن يتمكن الصيدلي من دخول المنصة.</p>
            <p style="color: #666;">تم تسجيل صيدلي جديد في تطبيق ${APP_NAME}. يرجى مراجعة الطلب والموافقة عليه من لوحة التحكم.</p>
          </div>
        </div>
        <div style="text-align: center; padding: 20px; color: #999; font-size: 12px;">
          <p>${APP_NAME} - Automated Admin Notification</p>
          <p>This email was automatically sent because a new pharmacist registered.</p>
        </div>
      </div>
    `,
  };
}

function buildPatientEmail(user) {
  return {
    subject: `👤 New Patient Registered - ${user.name}`,
    html: `
      <div dir="rtl" style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background: #f9f9f9;">
        <div style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); padding: 30px; border-radius: 12px 12px 0 0; text-align: center;">
          <h1 style="color: #fff; margin: 0; font-size: 24px;">👤 New Patient Registration</h1>
          <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0;">${APP_NAME} Admin Notification</p>
        </div>
        <div style="background: #fff; padding: 30px; border-radius: 0 0 12px 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.08);">
          <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
            <tr><td style="padding: 10px; border-bottom: 1px solid #eee; font-weight: bold; color: #555;">Name</td><td style="padding: 10px; border-bottom: 1px solid #eee;">${user.name}</td></tr>
            <tr><td style="padding: 10px; border-bottom: 1px solid #eee; font-weight: bold; color: #555;">Username</td><td style="padding: 10px; border-bottom: 1px solid #eee;">${user.username}</td></tr>
            <tr><td style="padding: 10px; border-bottom: 1px solid #eee; font-weight: bold; color: #555;">Email</td><td style="padding: 10px; border-bottom: 1px solid #eee;"><a href="mailto:${user.email}">${user.email}</a></td></tr>
            <tr><td style="padding: 10px; border-bottom: 1px solid #eee; font-weight: bold; color: #555;">Auth Provider</td><td style="padding: 10px; border-bottom: 1px solid #eee;">${user.authProvider}</td></tr>
            <tr><td style="padding: 10px; border-bottom: 1px solid #eee; font-weight: bold; color: #555;">Registered At</td><td style="padding: 10px; border-bottom: 1px solid #eee;">${formatDate(user.createdAt)}</td></tr>
          </table>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <div style="text-align: right;">
            <h3 style="color: #333;">تسجيل مريض جديد</h3>
            <p style="color: #666;">تم تسجيل مريض جديد في تطبيق ${APP_NAME}.</p>
          </div>
        </div>
        <div style="text-align: center; padding: 20px; color: #999; font-size: 12px;">
          <p>${APP_NAME} - Automated Admin Notification</p>
        </div>
      </div>
    `,
  };
}

exports.sendNewUserNotification = onDocumentCreated(
  "users/{uid}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("No data associated with the event");
      return null;
    }

    const user = snapshot.data();
    const { uid } = event.params;

    if (user.role === "admin") {
      logger.info("Skipping email for admin account", { uid });
      return null;
    }

    if (!user.email || !user.name) {
      logger.warn("User missing email or name, skipping notification", {
        uid,
      });
      return null;
    }

    try {
      const transporter = createTransporter();

      const emailData =
        user.role === "pharmacist"
          ? buildPharmacistEmail(user)
          : buildPatientEmail(user);

      const mailOptions = {
        from: `"${APP_NAME} Notifications" <${gmailEmail.value()}>`,
        to: gmailEmail.value(),
        replyTo: user.email,
        ...emailData,
      };

      await transporter.sendMail(mailOptions);
      logger.info(`New ${user.role} notification sent to admin`, {
        uid,
        role: user.role,
        userEmail: user.email,
      });

      return null;
    } catch (error) {
      logger.error("Failed to send email notification", {
        uid,
        role: user.role,
        error: error.message,
      });
      return null;
    }
  }
);

exports.sendPharmacistApprovalNotification = onDocumentUpdated(
  "users/{uid}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (after.role !== "pharmacist") return null;
    if (before.approvalStatus === after.approvalStatus) return null;

    const status = after.approvalStatus;

    try {
      const transporter = createTransporter();

      const subject =
        status === "approved"
          ? `✅ Pharmacist Approved - ${after.name}`
          : `❌ Pharmacist Rejected - ${after.name}`;

      const statusColor = status === "approved" ? "#27ae60" : "#e74c3c";
      const statusEmoji = status === "approved" ? "✅" : "❌";
      const statusAr =
        status === "approved" ? "تم اعتماد الحساب" : "تم رفض الحساب";
      const message =
        status === "approved"
          ? "The pharmacist has been approved and can now access the pharmacist dashboard."
          : "The pharmacist account has been rejected.";

      const mailOptions = {
        from: `"${APP_NAME} Notifications" <${gmailEmail.value()}>`,
        to: gmailEmail.value(),
        subject,
        html: `
          <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background: #f9f9f9;">
            <div style="background: ${statusColor}; padding: 30px; border-radius: 12px 12px 0 0; text-align: center;">
              <h1 style="color: #fff; margin: 0; font-size: 24px;">${statusEmoji} Pharmacist ${status.charAt(0).toUpperCase() + status.slice(1)}</h1>
            </div>
            <div style="background: #fff; padding: 30px; border-radius: 0 0 12px 12px;">
              <p style="font-size: 16px; color: #333;">${message}</p>
              <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
                <tr><td style="padding: 10px; border-bottom: 1px solid #eee; font-weight: bold; color: #555;">Name</td><td style="padding: 10px;">${after.name}</td></tr>
                <tr><td style="padding: 10px; border-bottom: 1px solid #eee; font-weight: bold; color: #555;">Email</td><td style="padding: 10px;">${after.email}</td></tr>
                <tr><td style="padding: 10px; font-weight: bold; color: #555;">Status</td><td style="padding: 10px; color: ${statusColor}; font-weight: bold;">${status.charAt(0).toUpperCase() + status.slice(1)}</td></tr>
              </table>
              <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
              <div style="text-align: right;">
                <h3 style="color: #333;">${statusAr}</h3>
                <p style="color: #666;">تم ${status === "approved" ? "اعتماد" : "رفض"} حساب الصيدلي ${after.name}.</p>
              </div>
            </div>
          </div>
        `,
      };

      await transporter.sendMail(mailOptions);
      logger.info("Pharmacist approval status change emailed to admin", {
        uid: event.params.uid,
        status,
      });
    } catch (error) {
      logger.error("Failed to send approval notification", {
        uid: event.params.uid,
        error: error.message,
      });
    }

    return null;
  }
);
