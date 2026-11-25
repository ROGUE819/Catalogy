import { describe, expect, it } from "vitest";
import { loadConfig } from "../src/config.js";

describe("loadConfig", () => {
  it("applies safe defaults", () => {
    const config = loadConfig({});
    expect(config.port).toBe(3000);
    expect(config.email.transport).toBe("console");
    expect(config.currency).toEqual({ display: "INR", usdRate: 83.5 });
    expect(config.featuredProductIds).toEqual([]);
  });

  it("parses and trims featured ids", () => {
    expect(loadConfig({ FEATURED_PRODUCT_IDS: " 12, 3,,18 " }).featuredProductIds).toEqual(["12", "3", "18"]);
  });

  it.each([
    ["PORT", "abc"],
    ["DISPLAY_CURRENCY", "rupees"],
    ["USD_TO_DISPLAY_RATE", "-5"],
    ["EMAIL_TRANSPORT", "carrier-pigeon"],
    ["SALES_INBOX", "not-an-email"],
  ])("fails fast on invalid %s", (key, value) => {
    expect(() => loadConfig({ [key]: value })).toThrow(/Invalid configuration/);
  });
});
