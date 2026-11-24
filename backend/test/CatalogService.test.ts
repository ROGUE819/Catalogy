import { describe, expect, it } from "vitest";
import { NotFoundError } from "../src/errors.js";
import { CatalogService } from "../src/products/CatalogService.js";
import { InMemoryProductSource, sampleProducts } from "./fixtures.js";

const makeService = (featuredProductIds: string[] = []) =>
  new CatalogService(new InMemoryProductSource(sampleProducts), {
    featuredProductIds,
    featuredCount: 5,
    categoryTopRatedCount: 2,
  });

describe("CatalogService.featured", () => {
  it("returns the curated products in the configured order", async () => {
    const result = await makeService(["5", "1", "8", "2", "3"]).featured();
    expect(result.map((p) => p.id)).toEqual(["5", "1", "8", "2", "3"]);
  });

  it("caps curated products at 5 and skips unknown ids", async () => {
    const result = await makeService(["999", "1", "2", "3", "4", "5", "6"]).featured();
    expect(result.map((p) => p.id)).toEqual(["1", "2", "3", "4", "5"]);
  });

  it("falls back to the 5 highest rated when nothing is curated", async () => {
    const result = await makeService().featured();
    // 1 and 6 tie on 3.9; 1 wins on rating count.
    expect(result.map((p) => p.id)).toEqual(["7", "3", "5", "2", "1"]);
  });
});

describe("CatalogService.categoryPage", () => {
  it("splits a category into top rated and other products", async () => {
    const page = await makeService().categoryPage("mens-clothing");
    expect(page.category).toEqual({ id: "mens-clothing", name: "Men's Clothing" });
    expect(page.topRated.map((p) => p.id)).toEqual(["3", "2"]);
    expect(page.others.map((p) => p.id)).toEqual(["1", "4"]);
  });

  it("throws NotFoundError for an unknown category", async () => {
    await expect(makeService().categoryPage("nope")).rejects.toBeInstanceOf(NotFoundError);
  });
});

describe("CatalogService.categories", () => {
  it("lists unique categories sorted by name", async () => {
    const categories = await makeService().categories();
    expect(categories.map((c) => c.id)).toEqual(["electronics", "jewelery", "mens-clothing"]);
  });
});

describe("CatalogService.search", () => {
  it("matches title case-insensitively", async () => {
    const result = await makeService().search("SLIM");
    expect(result.map((p) => p.id)).toEqual(["2", "4"]);
  });

  it("matches description and category text", async () => {
    expect((await makeService().search("satisfaction")).map((p) => p.id)).toEqual(["6"]);
    expect((await makeService().search("jewelery")).map((p) => p.id)).toEqual(["5", "6"]);
  });

  it("requires every term to match", async () => {
    const result = await makeService().search("gold petite");
    expect(result.map((p) => p.id)).toEqual(["6"]);
  });

  it("returns nothing for blank or unmatched terms", async () => {
    expect(await makeService().search("   ")).toEqual([]);
    expect(await makeService().search("zzzz")).toEqual([]);
  });
});

describe("CatalogService.product", () => {
  it("returns a product by id", async () => {
    expect((await makeService().product("7")).title).toBe("SanDisk SSD");
  });

  it("throws NotFoundError for an unknown id", async () => {
    await expect(makeService().product("404")).rejects.toBeInstanceOf(NotFoundError);
  });
});
