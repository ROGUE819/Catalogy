import { describe, expect, it, vi } from "vitest";
import { UpstreamError } from "../src/errors.js";
import { FakeStoreProductSource } from "../src/products/FakeStoreProductSource.js";

const payload = [
  {
    id: 1,
    title: "Backpack",
    price: 109.95,
    description: "Fits laptops",
    category: "men's clothing",
    image: "https://fakestoreapi.com/img/1.jpg",
    rating: { rate: 3.9, count: 120 },
  },
];

const jsonResponse = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

describe("FakeStoreProductSource", () => {
  it("maps the upstream shape to the domain model", async () => {
    const fetchFn = vi.fn().mockResolvedValue(jsonResponse(payload));
    const source = new FakeStoreProductSource("https://api.test", 60_000, fetchFn);

    const [product] = await source.listProducts();

    expect(fetchFn).toHaveBeenCalledWith("https://api.test/products", expect.anything());
    expect(product).toEqual({
      id: "1",
      title: "Backpack",
      description: "Fits laptops",
      price: 109.95,
      currency: "USD",
      category: { id: "mens-clothing", name: "Men's Clothing" },
      imageUrl: "https://fakestoreapi.com/img/1.jpg",
      rating: { average: 3.9, count: 120 },
    });
  });

  it("caches results until the TTL expires", async () => {
    let now = 0;
    const fetchFn = vi.fn().mockImplementation(async () => jsonResponse(payload));
    const source = new FakeStoreProductSource("https://api.test", 1000, fetchFn, () => now);

    await source.listProducts();
    await source.listProducts();
    expect(fetchFn).toHaveBeenCalledTimes(1);

    now = 1001;
    await source.listProducts();
    expect(fetchFn).toHaveBeenCalledTimes(2);
  });

  it("raises UpstreamError on non-2xx responses", async () => {
    const source = new FakeStoreProductSource("https://api.test", 0, vi.fn().mockResolvedValue(jsonResponse({}, 503)));
    await expect(source.listProducts()).rejects.toBeInstanceOf(UpstreamError);
  });

  it("raises UpstreamError on network failure", async () => {
    const source = new FakeStoreProductSource("https://api.test", 0, vi.fn().mockRejectedValue(new TypeError("fetch failed")));
    await expect(source.listProducts()).rejects.toBeInstanceOf(UpstreamError);
  });

  it("raises UpstreamError on an unexpected payload", async () => {
    const source = new FakeStoreProductSource("https://api.test", 0, vi.fn().mockResolvedValue(jsonResponse([{ id: "x" }])));
    await expect(source.listProducts()).rejects.toBeInstanceOf(UpstreamError);
  });
});
