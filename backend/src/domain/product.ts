/**
 * Catalogue domain model. This is the contract exposed to clients and is
 * deliberately independent of any upstream provider's shape (e.g. Fake Store).
 */
export type Product = {
  id: string;
  title: string;
  description: string;
  price: number;
  currency: string;
  category: Category;
  imageUrl: string;
  rating: { average: number; count: number };
};

export type Category = {
  /** URL-safe identifier, e.g. "mens-clothing" */
  id: string;
  /** Display name, e.g. "Men's Clothing" */
  name: string;
};

export function slugify(value: string): string {
  return value
    .toLowerCase()
    .replace(/['’]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export function toCategory(rawName: string): Category {
  const name = rawName
    .split(" ")
    .map((word) => (word ? word[0]!.toUpperCase() + word.slice(1) : word))
    .join(" ");
  return { id: slugify(rawName), name };
}

/** Highest average rating first; ties broken by number of ratings. */
export function byRatingDesc(a: Product, b: Product): number {
  return b.rating.average - a.rating.average || b.rating.count - a.rating.count;
}
