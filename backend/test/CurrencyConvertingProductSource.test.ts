import { describe, expect, it } from "vitest";
import {
  CurrencyConvertingProductSource,
  roundToMinorUnit,
} from "../src/products/CurrencyConvertingProductSource.js";
import { InMemoryProductSource, sampleProducts } from "./fixtures.js";

describe("CurrencyConvertingProductSource", () => {
  const inner = new InMemoryProductSource(sampleProducts);

  it("converts USD prices to the display currency", async () => {
    const source = new CurrencyConvertingProductSource(inner, { from: "USD", to: "INR", rate: 83.5 });
    const [first] = await source.listProducts();
    expect(first?.currency).toBe("INR");
    expect(first?.price).toBe(roundToMinorUnit(sampleProducts[0]!.price * 83.5));
  });

  it("leaves products in other currencies untouched", async () => {
    const eur = new InMemoryProductSource([{ ...sampleProducts[0]!, currency: "EUR" }]);
    const source = new CurrencyConvertingProductSource(eur, { from: "USD", to: "INR", rate: 83.5 });
    const [product] = await source.listProducts();
    expect(product).toMatchObject({ currency: "EUR", price: sampleProducts[0]!.price });
  });

  it("does not mutate the upstream products", async () => {
    const source = new CurrencyConvertingProductSource(inner, { from: "USD", to: "INR", rate: 2 });
    await source.listProducts();
    expect(sampleProducts[0]!.currency).toBe("USD");
  });

  it.each([0, -1, Number.NaN, Number.POSITIVE_INFINITY])("rejects invalid rate %s", (rate) => {
    expect(() => new CurrencyConvertingProductSource(inner, { from: "USD", to: "INR", rate })).toThrow();
  });

  it("rounds to two decimals without float artefacts", () => {
    expect(roundToMinorUnit(109.95 * 83.5)).toBe(9180.83);
    expect(roundToMinorUnit(1.005)).toBe(1.01);
  });
});
