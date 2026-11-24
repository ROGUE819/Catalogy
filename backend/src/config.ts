import { z } from "zod";

const idList = z
  .string()
  .optional()
  .transform((value) =>
    (value ?? "")
      .split(",")
      .map((id) => id.trim())
      .filter((id) => id.length > 0),
  );

const envSchema = z.object({
  PORT: z.coerce.number().int().positive().default(3000),
  FAKE_STORE_BASE_URL: z.string().url().default("https://fakestoreapi.com"),
  PRODUCT_CACHE_TTL_SECONDS: z.coerce.number().int().nonnegative().default(300),
  FEATURED_PRODUCT_IDS: idList,
  CATEGORY_TOP_RATED_COUNT: z.coerce.number().int().positive().default(3),
  EMAIL_TRANSPORT: z.enum(["smtp", "console"]).default("console"),
  SMTP_HOST: z.string().default("localhost"),
  SMTP_PORT: z.coerce.number().int().positive().default(1025),
  SMTP_SECURE: z
    .enum(["true", "false"])
    .default("false")
    .transform((v) => v === "true"),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
  SALES_INBOX: z.string().email().default("sales@catalogy.local"),
  EMAIL_FROM: z.string().default("Catalogy <no-reply@catalogy.local>"),
});

export type AppConfig = {
  port: number;
  fakeStoreBaseUrl: string;
  productCacheTtlMs: number;
  featuredProductIds: string[];
  featuredCount: number;
  categoryTopRatedCount: number;
  email: {
    transport: "smtp" | "console";
    smtp: { host: string; port: number; secure: boolean; user?: string; pass?: string };
    salesInbox: string;
    from: string;
  };
};

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const parsed = envSchema.safeParse(env);
  if (!parsed.success) {
    const issues = parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; ");
    throw new Error(`Invalid configuration: ${issues}`);
  }
  const e = parsed.data;
  return {
    port: e.PORT,
    fakeStoreBaseUrl: e.FAKE_STORE_BASE_URL,
    productCacheTtlMs: e.PRODUCT_CACHE_TTL_SECONDS * 1000,
    featuredProductIds: e.FEATURED_PRODUCT_IDS,
    featuredCount: 5,
    categoryTopRatedCount: e.CATEGORY_TOP_RATED_COUNT,
    email: {
      transport: e.EMAIL_TRANSPORT,
      smtp: {
        host: e.SMTP_HOST,
        port: e.SMTP_PORT,
        secure: e.SMTP_SECURE,
        user: e.SMTP_USER || undefined,
        pass: e.SMTP_PASS || undefined,
      },
      salesInbox: e.SALES_INBOX,
      from: e.EMAIL_FROM,
    },
  };
}
