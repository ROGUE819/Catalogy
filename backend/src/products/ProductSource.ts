import type { Product } from "../domain/product.js";

/**
 * Port for wherever product data comes from (Fake Store today; a PIM, CMS or
 * database tomorrow). Business rules live in CatalogService, not here.
 */
export interface ProductSource {
  listProducts(): Promise<Product[]>;
}
