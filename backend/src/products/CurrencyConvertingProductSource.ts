import type { Product } from "../domain/product.js";
import type { ProductSource } from "./ProductSource.js";

export type CurrencyConversion = {
  /** ISO 4217 code of the upstream prices, e.g. "USD". */
  from: string;
  /** ISO 4217 code shown to customers, e.g. "INR". */
  to: string;
  /** Units of `to` per 1 unit of `from`. */
  rate: number;
};

/**
 * Decorator that presents prices in the store's display currency.
 *
 * PoC assumption: a fixed, configured rate. In production this would come from
 * a pricing service or the product source itself would return local prices.
 * Being a decorator, it works with any `ProductSource` and can be removed
 * without touching the business rules or the HTTP layer.
 */
export class CurrencyConvertingProductSource implements ProductSource {
  constructor(
    private readonly inner: ProductSource,
    private readonly conversion: CurrencyConversion,
  ) {
    if (!(conversion.rate > 0) || !Number.isFinite(conversion.rate)) {
      throw new Error(`Invalid currency rate: ${conversion.rate}`);
    }
  }

  async listProducts(): Promise<Product[]> {
    const { from, to, rate } = this.conversion;
    const products = await this.inner.listProducts();
    return products.map((p) =>
      p.currency === from ? { ...p, price: roundToMinorUnit(p.price * rate), currency: to } : p,
    );
  }
}

/** Round to 2 decimal places without float artefacts (e.g. 1.005 -> 1.01). */
export const roundToMinorUnit = (value: number): number =>
  Math.round((value + Number.EPSILON) * 100) / 100;
