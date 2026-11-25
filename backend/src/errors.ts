export class NotFoundError extends Error {
  readonly status = 404;
  constructor(message: string) {
    super(message);
    this.name = "NotFoundError";
  }
}

/** Raised when an upstream dependency (product source, email provider) fails. */
export class UpstreamError extends Error {
  readonly status = 502;
  constructor(message: string, options?: { cause?: unknown }) {
    super(message, options);
    this.name = "UpstreamError";
  }
}
