import type { Product } from "../domain/product.js";

/**
 * Shapes domain products for HTTP clients. Image URLs are rewritten to our own
 * image endpoint so clients never call the upstream provider directly.
 */
export function presentProduct(product: Product, apiBaseUrl: string): Product {
  return { ...product, imageUrl: `${apiBaseUrl}/products/${encodeURIComponent(product.id)}/image` };
}

export function presentProducts(products: Product[], apiBaseUrl: string): Product[] {
  return products.map((p) => presentProduct(p, apiBaseUrl));
}
