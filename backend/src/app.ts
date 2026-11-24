import express, { type NextFunction, type Request, type Response } from "express";
import rateLimit from "express-rate-limit";
import helmet from "helmet";
import { z } from "zod";
import { enquiryRequestSchema } from "./enquiries/enquiry.js";
import type { EnquiryService } from "./enquiries/EnquiryService.js";
import { NotFoundError, UpstreamError } from "./errors.js";
import { presentProduct, presentProducts } from "./http/presenters.js";
import type { CatalogService } from "./products/CatalogService.js";
import type { ProductImageService } from "./products/ProductImageService.js";

export type AppDependencies = {
  catalog: CatalogService;
  enquiries: EnquiryService;
  images: ProductImageService;
  /** Max enquiries per IP per 15 minutes. */
  enquiryRateLimit?: number;
};

type AsyncHandler = (req: Request, res: Response) => Promise<void>;
const handle =
  (fn: AsyncHandler) =>
  (req: Request, res: Response, next: NextFunction): void => {
    fn(req, res).catch(next);
  };

const searchQuerySchema = z.object({ search: z.string().trim().max(100).optional() });

/** Absolute API base for this request, used to build image URLs clients can load. */
const apiBase = (req: Request) => `${req.protocol}://${req.get("host")}/api`;

export function createApp({ catalog, enquiries, images, enquiryRateLimit = 10 }: AppDependencies) {
  const app = express();
  app.disable("x-powered-by");
  app.use(helmet());
  app.use(express.json({ limit: "10kb" }));

  app.get("/health", (_req, res) => {
    res.json({ status: "ok" });
  });

  const api = express.Router();

  api.get(
    "/products/featured",
    handle(async (_req, res) => {
      res.json({ products: presentProducts(await catalog.featured(), apiBase(_req)) });
    }),
  );

  api.get(
    "/products",
    handle(async (req, res) => {
      const parsed = searchQuerySchema.safeParse(req.query);
      if (!parsed.success) {
        res.status(400).json({ error: "Invalid search query" });
        return;
      }
      const term = parsed.data.search ?? "";
      res.json({ query: term, products: presentProducts(await catalog.search(term), apiBase(req)) });
    }),
  );

  api.get(
    "/products/:id",
    handle(async (req, res) => {
      res.json({ product: presentProduct(await catalog.product(String(req.params.id)), apiBase(req)) });
    }),
  );

  api.get(
    "/products/:id/image",
    handle(async (req, res) => {
      const product = await catalog.product(String(req.params.id));
      const image = await images.get(product.imageUrl);
      res.set("Content-Type", image.contentType);
      res.set("Cache-Control", "public, max-age=86400");
      res.send(image.body);
    }),
  );

  api.get(
    "/categories",
    handle(async (_req, res) => {
      res.json({ categories: await catalog.categories() });
    }),
  );

  api.get(
    "/categories/:id/products",
    handle(async (req, res) => {
      const page = await catalog.categoryPage(String(req.params.id));
      const base = apiBase(req);
      res.json({ ...page, topRated: presentProducts(page.topRated, base), others: presentProducts(page.others, base) });
    }),
  );

  api.post(
    "/enquiries",
    rateLimit({ windowMs: 15 * 60 * 1000, limit: enquiryRateLimit, standardHeaders: "draft-7", legacyHeaders: false }),
    handle(async (req, res) => {
      const parsed = enquiryRequestSchema.safeParse(req.body);
      if (!parsed.success) {
        res.status(400).json({
          error: "Validation failed",
          fields: parsed.error.issues.map((i) => ({ field: i.path.join("."), message: i.message })),
        });
        return;
      }
      const enquiry = await enquiries.submit(parsed.data);
      res.status(201).json({ id: enquiry.id, message: "Thank you! Our sales team will be in touch shortly." });
    }),
  );

  app.use("/api", api);

  app.use((_req, res) => {
    res.status(404).json({ error: "Not found" });
  });

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  app.use((error: unknown, _req: Request, res: Response, _next: NextFunction) => {
    if (error instanceof NotFoundError) {
      res.status(404).json({ error: error.message });
      return;
    }
    if (error instanceof SyntaxError && "body" in error) {
      res.status(400).json({ error: "Malformed JSON body" });
      return;
    }
    if (error instanceof UpstreamError) {
      console.error(error, error.cause);
      res.status(502).json({ error: "A downstream service is unavailable. Please try again later." });
      return;
    }
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  });

  return app;
}
