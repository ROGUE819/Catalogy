import { z } from "zod";
import { toCategory, type Product } from "../domain/product.js";
import { UpstreamError } from "../errors.js";
import type { ProductSource } from "./ProductSource.js";

const fakeStoreProductSchema = z.object({
  id: z.number(),
  title: z.string(),
  price: z.number(),
  description: z.string(),
  category: z.string(),
  image: z.string(),
  rating: z.object({ rate: z.number(), count: z.number() }).optional(),
});

type FetchFn = typeof fetch;

/**
 * Adapter for https://fakestoreapi.com. Fake Store has no server-side search
 * and only ~20 products, so we fetch the full list once and cache it in memory.
 */
export class FakeStoreProductSource implements ProductSource {
  private cache?: { products: Product[]; expiresAt: number };
  private inFlight?: Promise<Product[]>;

  constructor(
    private readonly baseUrl: string,
    private readonly ttlMs: number,
    private readonly fetchFn: FetchFn = fetch,
    private readonly now: () => number = Date.now,
  ) {}

  async listProducts(): Promise<Product[]> {
    if (this.cache && this.cache.expiresAt > this.now()) {
      return this.cache.products;
    }
    // De-duplicate concurrent cache misses.
    this.inFlight ??= this.fetchProducts().finally(() => {
      this.inFlight = undefined;
    });
    return this.inFlight;
  }

  private async fetchProducts(): Promise<Product[]> {
    let response: Response;
    try {
      response = await this.fetchFn(`${this.baseUrl}/products`, {
        headers: { Accept: "application/json" },
        signal: AbortSignal.timeout(8000),
      });
    } catch (error) {
      throw new UpstreamError("Product source is unreachable", { cause: error });
    }
    if (!response.ok) {
      throw new UpstreamError(`Product source responded with ${response.status}`);
    }

    const parsed = z.array(fakeStoreProductSchema).safeParse(await response.json());
    if (!parsed.success) {
      throw new UpstreamError("Product source returned an unexpected payload", { cause: parsed.error });
    }

    const products = parsed.data.map(
      (p): Product => ({
        id: String(p.id),
        title: p.title,
        description: p.description,
        price: p.price,
        currency: "USD",
        category: toCategory(p.category),
        imageUrl: p.image,
        rating: { average: p.rating?.rate ?? 0, count: p.rating?.count ?? 0 },
      }),
    );
    this.cache = { products, expiresAt: this.now() + this.ttlMs };
    return products;
  }
}
