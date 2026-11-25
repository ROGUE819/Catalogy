import { randomUUID } from "node:crypto";
import { UpstreamError } from "../errors.js";
import type { CatalogService } from "../products/CatalogService.js";
import type { EnquiryRequest, Enquiry } from "./enquiry.js";
import type { EnquiryNotifier } from "./EnquiryNotifier.js";

export class EnquiryService {
  constructor(
    private readonly catalog: CatalogService,
    private readonly notifier: EnquiryNotifier,
  ) {}

  async submit(request: EnquiryRequest): Promise<Enquiry> {
    // Throws NotFoundError for unknown products, so we never email about junk ids.
    const product = await this.catalog.product(request.productId);
    const enquiry: Enquiry = {
      ...request,
      id: randomUUID(),
      productTitle: product.title,
      createdAt: new Date(),
    };
    try {
      await this.notifier.notify(enquiry);
    } catch (error) {
      throw new UpstreamError("Could not deliver enquiry", { cause: error });
    }
    return enquiry;
  }
}
