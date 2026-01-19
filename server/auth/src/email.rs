use lettre::{
    message::header::ContentType,
    transport::smtp::authentication::Credentials,
    AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor,
};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum EmailError {
    #[error("Email transport error: {0}")]
    Transport(#[from] lettre::transport::smtp::Error),
    #[error("Email build error: {0}")]
    Build(#[from] lettre::error::Error),
    #[error("Address parse error: {0}")]
    Address(#[from] lettre::address::AddressError),
    #[error("Email service not configured")]
    NotConfigured,
}

/// Email service configuration
#[derive(Clone)]
pub struct EmailConfig {
    pub smtp_host: String,
    pub smtp_port: u16,
    pub smtp_username: String,
    pub smtp_password: String,
    pub from_address: String,
    pub from_name: String,
    pub app_url: String,
}

impl EmailConfig {
    /// Load email configuration from environment variables
    pub fn from_env() -> Option<Self> {
        let smtp_host = std::env::var("SMTP_HOST").ok()?;
        let smtp_port = std::env::var("SMTP_PORT")
            .ok()
            .and_then(|p| p.parse().ok())
            .unwrap_or(587);
        let smtp_username = std::env::var("SMTP_USERNAME").ok()?;
        let smtp_password = std::env::var("SMTP_PASSWORD").ok()?;
        let from_address = std::env::var("SMTP_FROM_ADDRESS")
            .unwrap_or_else(|_| smtp_username.clone());
        let from_name = std::env::var("SMTP_FROM_NAME")
            .unwrap_or_else(|_| "Kinu".to_string());
        let app_url = std::env::var("APP_URL")
            .unwrap_or_else(|_| "https://kinuchat.com".to_string());

        Some(Self {
            smtp_host,
            smtp_port,
            smtp_username,
            smtp_password,
            from_address,
            from_name,
            app_url,
        })
    }
}

/// Email service for sending emails
pub struct EmailService {
    config: EmailConfig,
    mailer: AsyncSmtpTransport<Tokio1Executor>,
}

impl EmailService {
    /// Create a new email service
    pub fn new(config: EmailConfig) -> Result<Self, EmailError> {
        let creds = Credentials::new(
            config.smtp_username.clone(),
            config.smtp_password.clone(),
        );

        let mailer = AsyncSmtpTransport::<Tokio1Executor>::starttls_relay(&config.smtp_host)?
            .port(config.smtp_port)
            .credentials(creds)
            .build();

        Ok(Self { config, mailer })
    }

    /// Send a recovery email with token
    pub async fn send_recovery_email(
        &self,
        to_email: &str,
        handle: &str,
        token: &str,
    ) -> Result<(), EmailError> {
        let recovery_link = format!(
            "{}/recover?token={}&handle={}",
            self.config.app_url, token, handle
        );

        let html_body = format!(
            r#"<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Reset Your Password</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ text-align: center; margin-bottom: 30px; }}
        .logo {{ font-size: 24px; font-weight: bold; color: #1e3a5f; }}
        .button {{ display: inline-block; background: #1e3a5f; color: white; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: 600; margin: 20px 0; }}
        .button:hover {{ background: #2563eb; }}
        .footer {{ margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666; }}
        .warning {{ background: #fef3c7; border: 1px solid #f59e0b; border-radius: 8px; padding: 12px; margin: 20px 0; font-size: 14px; }}
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">Kinu</div>
    </div>

    <h2>Reset Your Password</h2>

    <p>Hi @{handle},</p>

    <p>We received a request to reset your Kinu account password. Click the button below to set a new password:</p>

    <p style="text-align: center;">
        <a href="{recovery_link}" class="button">Reset Password</a>
    </p>

    <div class="warning">
        <strong>This link expires in 1 hour.</strong> If you didn't request this reset, you can safely ignore this email.
    </div>

    <p>If the button doesn't work, copy and paste this link into your browser:</p>
    <p style="word-break: break-all; font-size: 12px; color: #666;">{recovery_link}</p>

    <div class="footer">
        <p>This email was sent by Kinu. If you have questions, contact us at support@kinuchat.com</p>
        <p>Kinu Foundation</p>
    </div>
</body>
</html>"#
        );

        let plain_body = format!(
            r#"Reset Your Password

Hi @{handle},

We received a request to reset your Kinu account password.

Reset your password here:
{recovery_link}

This link expires in 1 hour. If you didn't request this reset, you can safely ignore this email.

- Kinu Foundation"#
        );

        let email = Message::builder()
            .from(format!("{} <{}>", self.config.from_name, self.config.from_address).parse()?)
            .to(to_email.parse()?)
            .subject("Reset Your Kinu Password")
            .multipart(
                lettre::message::MultiPart::alternative()
                    .singlepart(
                        lettre::message::SinglePart::builder()
                            .header(ContentType::TEXT_PLAIN)
                            .body(plain_body),
                    )
                    .singlepart(
                        lettre::message::SinglePart::builder()
                            .header(ContentType::TEXT_HTML)
                            .body(html_body),
                    ),
            )?;

        self.mailer.send(email).await?;
        Ok(())
    }

    /// Send an email verification email
    pub async fn send_verification_email(
        &self,
        to_email: &str,
        handle: &str,
        token: &str,
    ) -> Result<(), EmailError> {
        let verify_link = format!(
            "{}/verify-email?token={}",
            self.config.app_url, token
        );

        let html_body = format!(
            r#"<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Verify Your Email</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ text-align: center; margin-bottom: 30px; }}
        .logo {{ font-size: 24px; font-weight: bold; color: #1e3a5f; }}
        .button {{ display: inline-block; background: #1e3a5f; color: white; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: 600; margin: 20px 0; }}
        .button:hover {{ background: #2563eb; }}
        .footer {{ margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666; }}
        .info {{ background: #e0f2fe; border: 1px solid #0ea5e9; border-radius: 8px; padding: 12px; margin: 20px 0; font-size: 14px; }}
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">Kinu</div>
    </div>

    <h2>Verify Your Email Address</h2>

    <p>Hi @{handle},</p>

    <p>Thanks for adding your email to your Kinu account! Please verify your email address by clicking the button below:</p>

    <p style="text-align: center;">
        <a href="{verify_link}" class="button">Verify Email</a>
    </p>

    <div class="info">
        <strong>Why verify?</strong> A verified email lets you recover your account if you forget your password or lose access to your device.
    </div>

    <p>If the button doesn't work, copy and paste this link into your browser:</p>
    <p style="word-break: break-all; font-size: 12px; color: #666;">{verify_link}</p>

    <p>This link expires in 24 hours.</p>

    <div class="footer">
        <p>If you didn't add this email to a Kinu account, you can safely ignore this email.</p>
        <p>Kinu Foundation</p>
    </div>
</body>
</html>"#
        );

        let plain_body = format!(
            r#"Verify Your Email Address

Hi @{handle},

Thanks for adding your email to your Kinu account! Please verify your email address:

{verify_link}

Why verify? A verified email lets you recover your account if you forget your password or lose access to your device.

This link expires in 24 hours.

If you didn't add this email to a Kinu account, you can safely ignore this email.

- Kinu Foundation"#
        );

        let email = Message::builder()
            .from(format!("{} <{}>", self.config.from_name, self.config.from_address).parse()?)
            .to(to_email.parse()?)
            .subject("Verify Your Kinu Email")
            .multipart(
                lettre::message::MultiPart::alternative()
                    .singlepart(
                        lettre::message::SinglePart::builder()
                            .header(ContentType::TEXT_PLAIN)
                            .body(plain_body),
                    )
                    .singlepart(
                        lettre::message::SinglePart::builder()
                            .header(ContentType::TEXT_HTML)
                            .body(html_body),
                    ),
            )?;

        self.mailer.send(email).await?;
        Ok(())
    }
}
