import { createApp } from "./app.js";
import { loadConfig } from "./config.js";
import {
  ConsoleEnquiryNotifier,
  SmtpEnquiryNotifier,
  type EnquiryNotifier,
} from "./enquiries/EnquiryNotifier.js";
import { EnquiryService } from "./enquiries/EnquiryService.js";
import { CatalogService } from "./products/CatalogService.js";
import { FakeStoreProductSource } from "./products/FakeStoreProductSource.js";
import { ProductImageService } from "./products/ProductImageService.js";

// Composition root: the only place that knows which concrete adapters are used.
const config = loadConfig();

const source = new FakeStoreProductSource(config.fakeStoreBaseUrl, config.productCacheTtlMs);
const catalog = new CatalogService(source, {
  featuredProductIds: config.featuredProductIds,
  featuredCount: config.featuredCount,
  categoryTopRatedCount: config.categoryTopRatedCount,
});

const notifier: EnquiryNotifier =
  config.email.transport === "smtp"
    ? new SmtpEnquiryNotifier(config.email.smtp, config.email.salesInbox, config.email.from)
    : new ConsoleEnquiryNotifier(config.email.salesInbox);

const app = createApp({ catalog, enquiries: new EnquiryService(catalog, notifier),
  images: new ProductImageService(),
});

app.listen(config.port, () => {
  console.info(`Catalogy API listening on http://localhost:${config.port} (email: ${config.email.transport})`);
});
