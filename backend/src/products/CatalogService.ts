import { byRatingDesc, type Category, type Product } from "../domain/product.js";
import { NotFoundError } from "../errors.js";
import type { ProductSource } from "./ProductSource.js";

export type CatalogOptions = {
  /** Merchandiser-curated ids for the home page; falls back to highest rated. */
  featuredProductIds: string[];
  featuredCount: number;
  categoryTopRatedCount: number;
};

export type CategoryPage = {
  category: Category;
  topRated: Product[];
  others: Product[];
};

/** Catalogue business rules, independent of transport (HTTP) and data source. */
export class CatalogService {
  constructor(
    private readonly source: ProductSource,
    private readonly options: CatalogOptions,
  ) {}

  async featured(): Promise<Product[]> {
    const products = await this.source.listProducts();
    const { featuredProductIds, featuredCount } = this.options;

    if (featuredProductIds.length > 0) {
      const byId = new Map(products.map((p) => [p.id, p]));
      // Keep curated order; silently skip ids that no longer exist upstream.
      const curated = featuredProductIds.flatMap((id) => byId.get(id) ?? []).slice(0, featuredCount);
      if (curated.length > 0) return curated;
    }
    return [...products].sort(byRatingDesc).slice(0, featuredCount);
  }

  async categories(): Promise<Category[]> {
    const products = await this.source.listProducts();
    const unique = new Map<string, Category>();
    for (const p of products) unique.set(p.category.id, p.category);
    return [...unique.values()].sort((a, b) => a.name.localeCompare(b.name));
  }

  async categoryPage(categoryId: string): Promise<CategoryPage> {
    const products = (await this.source.listProducts()).filter((p) => p.category.id === categoryId);
    const first = products[0];
    if (!first) throw new NotFoundError(`Category '${categoryId}' not found`);

    const sorted = [...products].sort(byRatingDesc);
    const n = this.options.categoryTopRatedCount;
    return { category: first.category, topRated: sorted.slice(0, n), others: sorted.slice(n) };
  }

  /**
   * Case-insensitive match of every whitespace-separated term against the
   * product's title, description or category name.
   */
  async search(query: string): Promise<Product[]> {
    const terms = query.toLowerCase().split(/\s+/).filter(Boolean);
    if (terms.length === 0) return [];
    const products = await this.source.listProducts();
    return products.filter((p) => {
      const haystack = `${p.title} ${p.description} ${p.category.name}`.toLowerCase();
      return terms.every((term) => haystack.includes(term));
    });
  }

  async product(id: string): Promise<Product> {
    const product = (await this.source.listProducts()).find((p) => p.id === id);
    if (!product) throw new NotFoundError(`Product '${id}' not found`);
    return product;
  }
}
