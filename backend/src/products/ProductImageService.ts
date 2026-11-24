import { UpstreamError } from "../errors.js";

export type ImageAsset = { body: Buffer; contentType: string };

type FetchFn = typeof fetch;

const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
/** Bounded so a large catalogue can't exhaust memory; oldest entries are evicted first. */
const DEFAULT_MAX_ENTRIES = 200;
const ALLOWED_PROTOCOLS = new Set(["https:", "http:"]);

/**
 * Fetches product images from the upstream source and caches them in memory, so
 * clients only ever talk to our backend (no direct Fake Store calls, one TLS
 * trust boundary, and a single place to swap in S3/CloudFront later).
 */
export class ProductImageService {
  private readonly cache = new Map<string, Promise<ImageAsset>>();

  constructor(
    private readonly fetchFn: FetchFn = fetch,
    private readonly maxEntries = DEFAULT_MAX_ENTRIES,
  ) {}

  get(url: string): Promise<ImageAsset> {
    let entry = this.cache.get(url);
    if (!entry) {
      entry = this.download(url);
      this.cache.set(url, entry);
      // Don't cache failures; allow a retry on the next request.
      entry.catch(() => this.cache.delete(url));
      if (this.cache.size > this.maxEntries) {
        const oldest = this.cache.keys().next().value;
        if (oldest !== undefined) this.cache.delete(oldest);
      }
    }
    return entry;
  }

  private async download(url: string): Promise<ImageAsset> {
    // Defence in depth against SSRF: only plain web URLs from the product source.
    let parsed: URL;
    try {
      parsed = new URL(url);
    } catch {
      throw new UpstreamError("Product has an invalid image URL");
    }
    if (!ALLOWED_PROTOCOLS.has(parsed.protocol)) {
      throw new UpstreamError(`Unsupported image URL protocol: ${parsed.protocol}`);
    }
    let response: Response;
    try {
      response = await this.fetchFn(url, { signal: AbortSignal.timeout(8000) });
    } catch (error) {
      throw new UpstreamError("Image source is unreachable", { cause: error });
    }
    const contentType = response.headers.get("content-type") ?? "";
    if (!response.ok || !contentType.startsWith("image/")) {
      throw new UpstreamError(`Image source responded with ${response.status} (${contentType || "no type"})`);
    }
    const declared = Number(response.headers.get("content-length") ?? 0);
    if (declared > MAX_IMAGE_BYTES) {
      throw new UpstreamError("Image is too large");
    }
    const body = Buffer.from(await response.arrayBuffer());
    if (body.byteLength > MAX_IMAGE_BYTES) {
      throw new UpstreamError("Image is too large");
    }
    return { body, contentType };
  }
}
