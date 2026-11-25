import { describe, expect, it, vi } from "vitest";
import { UpstreamError } from "../src/errors.js";
import { ProductImageService } from "../src/products/ProductImageService.js";

const png = (headers: Record<string, string> = {}) =>
  new Response(new Uint8Array([137, 80, 78, 71]), { headers: { "Content-Type": "image/png", ...headers } });

describe("ProductImageService", () => {
  it("rejects non-http(s) URLs without fetching (SSRF guard)", async () => {
    const fetchFn = vi.fn();
    const service = new ProductImageService(fetchFn);
    await expect(service.get("file:///etc/passwd")).rejects.toBeInstanceOf(UpstreamError);
    await expect(service.get("not a url")).rejects.toBeInstanceOf(UpstreamError);
    expect(fetchFn).not.toHaveBeenCalled();
  });

  it("rejects non-image responses", async () => {
    const service = new ProductImageService(vi.fn().mockResolvedValue(new Response("<html>", { headers: { "Content-Type": "text/html" } })));
    await expect(service.get("https://img.test/1.png")).rejects.toBeInstanceOf(UpstreamError);
  });

  it("rejects oversized images by declared length", async () => {
    const service = new ProductImageService(vi.fn().mockResolvedValue(png({ "Content-Length": String(10 * 1024 * 1024) })));
    await expect(service.get("https://img.test/1.png")).rejects.toThrow(/too large/);
  });

  it("does not cache failures, so the next request retries", async () => {
    const fetchFn = vi.fn().mockRejectedValueOnce(new TypeError("offline")).mockResolvedValue(png());
    const service = new ProductImageService(fetchFn);
    await expect(service.get("https://img.test/1.png")).rejects.toBeInstanceOf(UpstreamError);
    await expect(service.get("https://img.test/1.png")).resolves.toMatchObject({ contentType: "image/png" });
    expect(fetchFn).toHaveBeenCalledTimes(2);
  });

  it("evicts the oldest entry when the cache is full", async () => {
    const fetchFn = vi.fn(async () => png());
    const service = new ProductImageService(fetchFn, 2);
    await service.get("https://img.test/a.png");
    await service.get("https://img.test/b.png");
    await service.get("https://img.test/c.png"); // evicts a
    await service.get("https://img.test/a.png"); // refetched
    expect(fetchFn).toHaveBeenCalledTimes(4);
  });
});
