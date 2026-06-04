import { describe, expect, it, vi, beforeEach } from "vitest";
import { appRouter } from "./routers";
import type { TrpcContext } from "./_core/context";

// Mock user contexts
const adminUser = {
  id: 1,
  openId: "admin-user",
  email: "admin@example.com",
  name: "Admin User",
  loginMethod: "manus",
  role: "admin" as const,
  createdAt: new Date(),
  updatedAt: new Date(),
  lastSignedIn: new Date(),
};

const regularUser = {
  id: 2,
  openId: "regular-user",
  email: "user@example.com",
  name: "Regular User",
  loginMethod: "manus",
  role: "user" as const,
  createdAt: new Date(),
  updatedAt: new Date(),
  lastSignedIn: new Date(),
};

function createContext(user?: typeof adminUser | typeof regularUser): TrpcContext {
  return {
    user: user || null,
    req: {
      protocol: "https",
      headers: {},
    } as TrpcContext["req"],
    res: {} as TrpcContext["res"],
  };
}

describe("training.exportJSON", () => {
  it("should export training content as JSON", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    const result = await caller.training.exportJSON();

    expect(Array.isArray(result)).toBe(true);
    expect(result.length).toBeGreaterThan(0);

    // Check structure of first topic
    const firstTopic = result[0];
    expect(firstTopic).toHaveProperty("id");
    expect(firstTopic).toHaveProperty("title");
    expect(firstTopic).toHaveProperty("slug");
    expect(firstTopic).toHaveProperty("sections");
    expect(Array.isArray(firstTopic.sections)).toBe(true);
  });

  it("should include sections with tables and notes", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    const result = await caller.training.exportJSON();

    // Find a topic with sections
    const topicWithSections = result.find((t: any) => t.sections?.length > 0);
    expect(topicWithSections).toBeDefined();

    if (topicWithSections) {
      const section = topicWithSections.sections[0];
      expect(section).toHaveProperty("id");
      expect(section).toHaveProperty("title");
      expect(section).toHaveProperty("content");
      expect(section).toHaveProperty("tables");
      expect(section).toHaveProperty("notes");
    }
  });
});

describe("training.exportHTML", () => {
  it("should export training content as HTML", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    const result = await caller.training.exportHTML();

    expect(typeof result).toBe("string");
    expect(result).toContain("<!DOCTYPE html>");
    expect(result).toContain("Kubernetes Training Reference Guide");
    expect(result).toContain("</html>");
  });

  it("should include proper HTML structure", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    const result = await caller.training.exportHTML();

    expect(result).toContain("<head>");
    expect(result).toContain("<body>");
    expect(result).toContain("<table>");
    expect(result).toContain("<style>");
  });
});

describe("training.resetToOriginal", () => {
  it("should reject non-admin users", async () => {
    const ctx = createContext(regularUser);
    const caller = appRouter.createCaller(ctx);

    try {
      await caller.training.resetToOriginal();
      expect.fail("Should have thrown an error");
    } catch (error: any) {
      expect(error.code).toBe("FORBIDDEN");
    }
  });

  it("should reject unauthenticated users", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    try {
      await caller.training.resetToOriginal();
      expect.fail("Should have thrown an error");
    } catch (error: any) {
      expect(error.code).toBe("UNAUTHORIZED");
    }
  });

  it("should allow admin users to reset content", async () => {
    const ctx = createContext(adminUser);
    const caller = appRouter.createCaller(ctx);

    const result = await caller.training.resetToOriginal();

    expect(result).toHaveProperty("success");
    expect(result.success).toBe(true);
    expect(result).toHaveProperty("message");
  });
});
