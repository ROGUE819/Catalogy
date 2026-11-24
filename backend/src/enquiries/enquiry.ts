import { z } from "zod";

export const enquiryRequestSchema = z.object({
  productId: z.string().trim().min(1).max(64),
  name: z.string().trim().min(1, "Name is required").max(100),
  email: z.string().trim().email("A valid email is required").max(254),
  phone: z
    .string()
    .trim()
    .max(30)
    .regex(/^[+0-9 ()-]*$/, "Phone may only contain digits, spaces and + ( ) -")
    .optional()
    .transform((v) => (v ? v : undefined)),
  message: z
    .string()
    .trim()
    .max(2000)
    .optional()
    .transform((v) => (v ? v : undefined)),
});

export type EnquiryRequest = z.infer<typeof enquiryRequestSchema>;

export type Enquiry = EnquiryRequest & {
  id: string;
  productTitle: string;
  createdAt: Date;
};
