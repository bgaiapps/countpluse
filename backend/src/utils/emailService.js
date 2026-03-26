const { Resend } = require('resend');
const env = require('../config/env');

const resend = env.resendApiKey ? new Resend(env.resendApiKey) : null;

if (!env.resendApiKey) {
  console.warn('RESEND_API_KEY is not set. Email sending will fail.');
}

const sendMail = async (mailOptions, logLabel) => {
  if (!resend) {
    throw new Error('Resend is not configured');
  }
  const { error } = await resend.emails.send(mailOptions);
  if (error) {
    throw new Error(error.message || 'Resend send failed');
  }
  console.log(`${logLabel} email sent to ${mailOptions.to}`);
};

// Send verification email
const sendVerificationEmail = async (user, verificationUrl) => {
  const mailOptions = {
    from: env.emailFrom,
    to: user.email,
    subject: 'Verify Your Japlo Account',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #1A3A2A; color: #F0F0E0; padding: 20px; border-radius: 8px; text-align: center;">
          <h1 style="margin: 0; color: #FFBF00;">Japlo</h1>
          <p style="margin: 10px 0 0 0;">Email Verification</p>
        </div>
        
        <div style="padding: 20px; background-color: #f5f5f5; border-radius: 8px; margin-top: 20px;">
          <p style="color: #333; font-size: 16px;">Hello <strong>${user.name}</strong>,</p>
          <p style="color: #666; font-size: 14px; line-height: 1.6;">
            Thank you for registering with Japlo! To complete your registration and verify your email, 
            please click the button below.
          </p>
          
          <div style="text-align: center; margin: 30px 0;">
            <a href="${verificationUrl}" 
               style="background-color: #FFBF00; color: #1A3A2A; padding: 12px 30px; text-decoration: none; 
                      border-radius: 6px; font-weight: bold; font-size: 16px; display: inline-block;">
              Verify Email
            </a>
          </div>
          
          <p style="color: #666; font-size: 12px; margin-top: 20px;">
            If the button doesn't work, copy and paste this link in your browser:
          </p>
          <p style="color: #FFBF00; font-size: 12px; word-break: break-all;">
            ${verificationUrl}
          </p>
          
          <p style="color: #999; font-size: 12px; margin-top: 20px;">
            This verification link will expire in 24 hours.
          </p>
        </div>
        
        <div style="text-align: center; margin-top: 20px; color: #999; font-size: 12px;">
          <p>If you didn't register for Japlo, please ignore this email.</p>
          <p>&copy; 2026 Japlo. All rights reserved.</p>
        </div>
      </div>
    `,
  };

  try {
    await sendMail(mailOptions, 'Verification');
    return true;
  } catch (error) {
    console.error('Error sending email:', error);
    throw error;
  }
};

// Send login link email (for passwordless login alternative)
const sendLoginLinkEmail = async (user, loginUrl) => {
  const mailOptions = {
    from: env.emailFrom,
    to: user.email,
    subject: 'Your Japlo Login Link',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #1A3A2A; color: #F0F0E0; padding: 20px; border-radius: 8px; text-align: center;">
          <h1 style="margin: 0; color: #FFBF00;">Japlo</h1>
          <p style="margin: 10px 0 0 0;">Secure Login</p>
        </div>
        
        <div style="padding: 20px; background-color: #f5f5f5; border-radius: 8px; margin-top: 20px;">
          <p style="color: #333; font-size: 16px;">Hello <strong>${user.name}</strong>,</p>
          <p style="color: #666; font-size: 14px; line-height: 1.6;">
            Click the button below to securely log in to your Japlo account.
          </p>
          
          <div style="text-align: center; margin: 30px 0;">
            <a href="${loginUrl}" 
               style="background-color: #FFBF00; color: #1A3A2A; padding: 12px 30px; text-decoration: none; 
                      border-radius: 6px; font-weight: bold; font-size: 16px; display: inline-block;">
              Login to Japlo
            </a>
          </div>
          
          <p style="color: #999; font-size: 12px; margin-top: 20px;">
            This login link will expire in 15 minutes.
          </p>
        </div>
        
        <div style="text-align: center; margin-top: 20px; color: #999; font-size: 12px;">
          <p>If you didn't request this login link, please ignore this email.</p>
          <p>&copy; 2026 Japlo. All rights reserved.</p>
        </div>
      </div>
    `,
  };

  try {
    await sendMail(mailOptions, 'Login');
    return true;
  } catch (error) {
    console.error('Error sending login email:', error);
    throw error;
  }
};

// Send OTP email (for login/registration)
const sendOtpEmail = async (user, otpCode) => {
  const mailOptions = {
    from: env.emailFrom,
    to: user.email,
    subject: 'Your Japlo OTP Code',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #1A3A2A; color: #F0F0E0; padding: 20px; border-radius: 8px; text-align: center;">
          <h1 style="margin: 0; color: #FFBF00;">Japlo</h1>
          <p style="margin: 10px 0 0 0;">OTP Verification</p>
        </div>

        <div style="padding: 20px; background-color: #f5f5f5; border-radius: 8px; margin-top: 20px;">
          <p style="color: #333; font-size: 16px;">Hello <strong>${user.name || 'there'}</strong>,</p>
          <p style="color: #666; font-size: 14px; line-height: 1.6;">
            Use the OTP code below to verify your Japlo account.
          </p>

          <div style="text-align: center; margin: 24px 0;">
            <div style="display: inline-block; padding: 12px 24px; background: #FFBF00; color: #1A3A2A; font-weight: bold; font-size: 22px; letter-spacing: 4px; border-radius: 6px;">
              ${otpCode}
            </div>
          </div>

          <p style="color: #999; font-size: 12px; margin-top: 20px;">
            This OTP will expire in ${env.otpExpireMinutes} minutes.
          </p>
        </div>

        <div style="text-align: center; margin-top: 20px; color: #999; font-size: 12px;">
          <p>If you didn't request this OTP, please ignore this email.</p>
          <p>&copy; 2026 Japlo. All rights reserved.</p>
        </div>
      </div>
    `,
  };

  try {
    await sendMail(mailOptions, 'OTP');
    return true;
  } catch (error) {
    console.error('Error sending OTP email:', error);
    throw error;
  }
};

module.exports = {
  sendVerificationEmail,
  sendLoginLinkEmail,
  sendOtpEmail,
};
