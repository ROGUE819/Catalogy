import { UpstreamError } from "../errors.js";

export type ImageAsset = { body: Buffer; contentType: string };

type FetchFn = typeof fetch;

const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

/**
 * Fetches product images from the upstream source and caches them in memory, so
 * clients only ever talk to our backend (no direct Fake Store calls, one TLS
 * trust boundary, and a single place to swap in S3/CloudFront later).
 */
export class ProductImageService {
  private readonly cache = new Map<string, Promise<ImageAsset>>();

  constructor(private readonly fetchFn: FetchFn = fetch) {}

  get(url: string): Promise<ImageAsset> {
    let entry = this.cache.get(url);
    if (!entry) {
      entry = this.download(url);
      this.cache.set(url, entry);
      // Don't cache failures; allow a retry on the next request.
      entry.catch(() => this.cache.delete(url));
    }
    return entry;
  }

  private async download(url: string): Promise<ImageAsset> {
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
    const body = Buffer.from(await response.arrayBuffer());
    if (body.byteLength > MAX_IMAGE_BYTES) {
      throw new UpstreamError("Image is too large");
    }
    return { body, contentType };
  }
}
