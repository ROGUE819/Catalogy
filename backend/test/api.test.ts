import request from "supertest";
import { describe, expect, it, vi } from "vitest";
import { createApp } from "../src/app.js";
import type { Enquiry } from "../src/enquiries/enquiry.js";
import { renderEnquiryEmail, type EnquiryNotifier } from "../src/enquiries/EnquiryNotifier.js";
import { EnquiryService } from "../src/enquiries/EnquiryService.js";
import { UpstreamError } from "../src/errors.js";
import { CatalogService } from "../src/products/CatalogService.js";
import { ProductImageService } from "../src/products/ProductImageService.js";
import type { ProductSource } from "../src/products/ProductSource.js";
import { InMemoryProductSource, sampleProducts } from "./fixtures.js";

function setup(options: { source?: ProductSource; notifier?: EnquiryNotifier } = {}) {
  const catalog = new CatalogService(options.source ?? new InMemoryProductSource(sampleProducts), {
    featuredProductIds: ["7", "3", "5", "2", "1"],
    featuredCount: 5,
    categoryTopRatedCount: 2,
  });
  const sent: Enquiry[] = [];
  const notifier: EnquiryNotifier = options.notifier ?? { notify: async (e) => void sent.push(e) };
  const imageFetch = vi.fn(async () => new Response(new Uint8Array([137, 80, 78, 71]), { headers: { "Content-Type": "image/png" } }));
  const images = new ProductImageService(imageFetch);
  const app = createApp({ catalog, enquiries: new EnquiryService(catalog, notifier), images, enquiryRateLimit: 1000 });
  return { app, sent, imageFetch };
}

const validEnquiry = { productId: "7", name: "Ada Lovelace", email: "ada@example.com", message: "Bulk pricing?" };

describe("HTTP API", () => {
  it("GET /api/products/featured returns the 5 featured products", async () => {
    const res = await request(setup().app).get("/api/products/featured").expect(200);
    expect(res.body.products).toHaveLength(5);
    expect(res.body.products[0].id).toBe("7");
  });

  it("GET /api/categories lists categories", async () => {
    const res = await request(setup().app).get("/api/categories").expect(200);
    expect(res.body.categories).toContainEqual({ id: "jewelery", name: "Jewelery" });
  });

  it("GET /api/categories/:id/products returns top rated and other products", async () => {
    const res = await request(setup().app).get("/api/categories/mens-clothing/products").expect(200);
    expect(res.body.topRated).toHaveLength(2);
    expect(res.body.others).toHaveLength(2);
  });

  it("GET /api/categories/:id/products returns 404 for unknown category", async () => {
    await request(setup().app).get("/api/categories/unknown/products").expect(404);
  });

  it("GET /api/products?search= only returns matching products", async () => {
    const res = await request(setup().app).get("/api/products").query({ search: "gold" }).expect(200);
    expect(res.body.products.map((p: { id: string }) => p.id)).toEqual(["5", "6"]);
  });

  it("GET /api/products/:id returns product details or 404", async () => {
    const res = await request(setup().app).get("/api/products/3").expect(200);
    expect(res.body.product.title).toBe("Cotton Jacket");
    await request(setup().app).get("/api/products/999").expect(404);
  });

  it("rewrites image URLs to the backend and proxies the image", async () => {
    const { app, imageFetch } = setup();
    const res = await request(app).get("/api/products/7").expect(200);
    expect(res.body.product.imageUrl).toMatch(/\/api\/products\/7\/image$/);

    const image = await request(app).get("/api/products/7/image").expect(200);
    expect(image.headers["content-type"]).toBe("image/png");
    await request(app).get("/api/products/7/image").expect(200);
    expect(imageFetch).toHaveBeenCalledTimes(1); // cached
  });

  it("returns 404 for the image of an unknown product", async () => {
    await request(setup().app).get("/api/products/999/image").expect(404);
  });

  it("returns 502 when the product source is down", async () => {
    const source: ProductSource = { listProducts: () => Promise.reject(new UpstreamError("down")) };
    vi.spyOn(console, "error").mockImplementation(() => {});
    const res = await request(setup({ source }).app).get("/api/products/featured").expect(502);
    expect(res.body.error).toMatch(/unavailable/);
  });
});

describe("POST /api/enquiries", () => {
  it("sends the enquiry to sales and returns a thank-you message", async () => {
    const { app, sent } = setup();
    const res = await request(app).post("/api/enquiries").send(validEnquiry).expect(201);

    expect(res.body.message).toMatch(/thank you/i);
    expect(sent).toHaveLength(1);
    expect(sent[0]).toMatchObject({ productId: "7", productTitle: "SanDisk SSD", email: "ada@example.com" });
  });

  it("rejects invalid contact details with field errors", async () => {
    const { app, sent } = setup();
    const res = await request(app)
      .post("/api/enquiries")
      .send({ productId: "7", name: "", email: "not-an-email" })
      .expect(400);

    expect(res.body.fields.map((f: { field: string }) => f.field).sort()).toEqual(["email", "name"]);
    expect(sent).toHaveLength(0);
  });

  it("returns 404 for an unknown product", async () => {
    const { app, sent } = setup();
    await request(app).post("/api/enquiries").send({ ...validEnquiry, productId: "999" }).expect(404);
    expect(sent).toHaveLength(0);
  });

  it("returns 400 for malformed JSON", async () => {
    await request(setup().app)
      .post("/api/enquiries")
      .set("Content-Type", "application/json")
      .send("{bad json")
      .expect(400);
  });

  it("returns 502 when email delivery fails", async () => {
    vi.spyOn(console, "error").mockImplementation(() => {});
    const notifier: EnquiryNotifier = { notify: () => Promise.reject(new Error("SMTP down")) };
    await request(setup({ notifier }).app).post("/api/enquiries").send(validEnquiry).expect(502);
  });
});

describe("renderEnquiryEmail", () => {
  it("includes contact details and strips newlines from the subject", () => {
    const email = renderEnquiryEmail({
      ...validEnquiry,
      phone: undefined,
      id: "abc",
      productTitle: "Evil\r\nBcc: attacker@example.com",
      createdAt: new Date("2026-01-01T00:00:00Z"),
    });
    expect(email.subject).not.toMatch(/[\r\n]/);
    expect(email.text).toContain("ada@example.com");
    expect(email.replyTo).toBe("ada@example.com");
  });
});
