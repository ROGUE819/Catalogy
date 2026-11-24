import nodemailer, { type Transporter } from "nodemailer";
import type { Enquiry } from "./enquiry.js";

/** Port for delivering enquiries to the sales team (SMTP today; SES/SendGrid/CRM later). */
export interface EnquiryNotifier {
  notify(enquiry: Enquiry): Promise<void>;
}

export type EmailMessage = { subject: string; text: string; replyTo: string };

/** Plain-text only: avoids HTML injection from user-supplied fields. */
export function renderEnquiryEmail(enquiry: Enquiry): EmailMessage {
  const lines = [
    `New enquiry for: ${enquiry.productTitle} (id ${enquiry.productId})`,
    "",
    `Name:    ${enquiry.name}`,
    `Email:   ${enquiry.email}`,
    `Phone:   ${enquiry.phone ?? "-"}`,
    "",
    "Message:",
    enquiry.message ?? "-",
    "",
    `Enquiry id: ${enquiry.id}`,
    `Received:   ${enquiry.createdAt.toISOString()}`,
  ];
  // Strip CR/LF from the subject to prevent header injection.
  const subject = `Product enquiry: ${enquiry.productTitle}`.replace(/[\r\n]+/g, " ").slice(0, 200);
  return { subject, text: lines.join("\n"), replyTo: enquiry.email };
}

export class SmtpEnquiryNotifier implements EnquiryNotifier {
  private readonly transporter: Transporter;

  constructor(
    smtp: { host: string; port: number; secure: boolean; user?: string; pass?: string },
    private readonly to: string,
    private readonly from: string,
  ) {
    this.transporter = nodemailer.createTransport({
      host: smtp.host,
      port: smtp.port,
      secure: smtp.secure,
      auth: smtp.user ? { user: smtp.user, pass: smtp.pass } : undefined,
    });
  }

  async notify(enquiry: Enquiry): Promise<void> {
    const message = renderEnquiryEmail(enquiry);
    await this.transporter.sendMail({ to: this.to, from: this.from, ...message });
  }
}

/** Logs instead of sending; used when no SMTP server is available. */
export class ConsoleEnquiryNotifier implements EnquiryNotifier {
  constructor(private readonly to: string) {}

  async notify(enquiry: Enquiry): Promise<void> {
    const message = renderEnquiryEmail(enquiry);
    console.info(`[email] to=${this.to} subject="${message.subject}"\n${message.text}`);
  }
}
