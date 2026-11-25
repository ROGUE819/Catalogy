import type { Product } from "../src/domain/product.js";
import { toCategory } from "../src/domain/product.js";
import type { ProductSource } from "../src/products/ProductSource.js";

export function makeProduct(overrides: Partial<Product> & { id: string }): Product {
  return {
    title: `Product ${overrides.id}`,
    description: "A product",
    price: 10,
    currency: "USD",
    category: toCategory("electronics"),
    imageUrl: "https://example.com/img.png",
    rating: { average: 3, count: 10 },
    ...overrides,
  };
}

export class InMemoryProductSource implements ProductSource {
  constructor(public products: Product[]) {}
  async listProducts(): Promise<Product[]> {
    return this.products;
  }
}

export const sampleProducts: Product[] = [
  makeProduct({ id: "1", title: "Fjallraven Backpack", category: toCategory("men's clothing"), rating: { average: 3.9, count: 120 } }),
  makeProduct({ id: "2", title: "Slim Fit T-Shirt", category: toCategory("men's clothing"), rating: { average: 4.1, count: 259 } }),
  makeProduct({ id: "3", title: "Cotton Jacket", category: toCategory("men's clothing"), rating: { average: 4.7, count: 500 } }),
  makeProduct({ id: "4", title: "Casual Slim Fit", category: toCategory("men's clothing"), rating: { average: 2.1, count: 430 } }),
  makeProduct({ id: "5", title: "Gold Bracelet", category: toCategory("jewelery"), rating: { average: 4.6, count: 400 } }),
  makeProduct({ id: "6", title: "Solid Gold Petite", description: "Satisfaction guaranteed", category: toCategory("jewelery"), rating: { average: 3.9, count: 70 } }),
  makeProduct({ id: "7", title: "SanDisk SSD", category: toCategory("electronics"), rating: { average: 4.8, count: 319 } }),
  makeProduct({ id: "8", title: "WD Hard Drive", category: toCategory("electronics"), rating: { average: 3.3, count: 203 } }),
];
