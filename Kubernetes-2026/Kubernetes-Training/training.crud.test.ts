import { describe, expect, it, beforeEach } from "vitest";
import { appRouter } from "./routers";
import type { TrpcContext } from "./_core/context";

const authenticatedUser = {
  id: 1,
  openId: "test-user",
  email: "test@example.com",
  name: "Test User",
  loginMethod: "manus",
  role: "user" as const,
  createdAt: new Date(),
  updatedAt: new Date(),
  lastSignedIn: new Date(),
};

function createContext(user?: typeof authenticatedUser): TrpcContext {
  return {
    user: user || null,
    req: {
      protocol: "https",
      headers: {},
    } as TrpcContext["req"],
    res: {} as TrpcContext["res"],
  };
}

describe("training.getTopics", () => {
  it("should return all training topics", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    const topics = await caller.training.getTopics();

    expect(Array.isArray(topics)).toBe(true);
    expect(topics.length).toBeGreaterThan(0);

    const firstTopic = topics[0];
    expect(firstTopic).toHaveProperty("id");
    expect(firstTopic).toHaveProperty("title");
    expect(firstTopic).toHaveProperty("slug");
    expect(firstTopic).toHaveProperty("description");
    expect(firstTopic).toHaveProperty("icon");
  });
});

describe("training.getTopicBySlug", () => {
  it("should return a topic with all sections", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    const topic = await caller.training.getTopicBySlug({
      slug: "kubernetes-architecture",
    });

    expect(topic).toBeDefined();
    expect(topic?.title).toBe("Kubernetes Architecture");
    expect(topic?.sections).toBeDefined();
    expect(Array.isArray(topic?.sections)).toBe(true);
  });

  it("should return null for non-existent topic", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    const topic = await caller.training.getTopicBySlug({
      slug: "non-existent-topic",
    });

    expect(topic).toBeNull();
  });

  it("should include sections with tables and notes", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    const topic = await caller.training.getTopicBySlug({
      slug: "kubernetes-architecture",
    });

    if (topic?.sections && topic.sections.length > 0) {
      const section = topic.sections[0];
      expect(section).toHaveProperty("id");
      expect(section).toHaveProperty("title");
      expect(section).toHaveProperty("content");
      expect(section).toHaveProperty("tables");
      expect(section).toHaveProperty("notes");
      expect(Array.isArray(section.tables)).toBe(true);
      expect(Array.isArray(section.notes)).toBe(true);
    }
  });
});

describe("training.updateSectionContent", () => {
  it("should require authentication", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    try {
      await caller.training.updateSectionContent({
        sectionId: 1,
        content: "Updated content",
      });
      expect.fail("Should have thrown an error");
    } catch (error: any) {
      expect(error.code).toBe("UNAUTHORIZED");
    }
  });

  it("should update section content for authenticated users", async () => {
    const ctx = createContext(authenticatedUser);
    const caller = appRouter.createCaller(ctx);

    // First get a section ID
    const topic = await caller.training.getTopicBySlug({
      slug: "kubernetes-architecture",
    });

    if (topic?.sections && topic.sections.length > 0) {
      const sectionId = topic.sections[0].id;
      const newContent = "Updated test content " + Date.now();

      const result = await caller.training.updateSectionContent({
        sectionId,
        content: newContent,
      });

      expect(result).toBeDefined();

      // Verify the update
      const updatedTopic = await caller.training.getTopicBySlug({
        slug: "kubernetes-architecture",
      });

      const updatedSection = updatedTopic?.sections?.find((s) => s.id === sectionId);
      expect(updatedSection?.content).toBe(newContent);
    }
  });
});

describe("training.addTableRow", () => {
  it("should require authentication", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    try {
      await caller.training.addTableRow({
        tableId: 1,
        rowData: { col1: "value1" },
        order: 0,
      });
      expect.fail("Should have thrown an error");
    } catch (error: any) {
      expect(error.code).toBe("UNAUTHORIZED");
    }
  });

  it("should add a table row for authenticated users", async () => {
    const ctx = createContext(authenticatedUser);
    const caller = appRouter.createCaller(ctx);

    // Get a table ID first
    const topic = await caller.training.getTopicBySlug({
      slug: "kubernetes-architecture",
    });

    if (topic?.sections && topic.sections.length > 0) {
      const section = topic.sections[0];
      if (section.tables && section.tables.length > 0) {
        const table = section.tables[0];
        const columns = JSON.parse(table.columns || "[]");

        const rowData: Record<string, any> = {};
        columns.forEach((col: string) => {
          rowData[col] = `Test Value ${Date.now()}`;
        });

        const result = await caller.training.addTableRow({
          tableId: table.id,
          rowData,
          order: 0,
        });

        expect(result).toBeDefined();

        // Verify the row was added
        const updatedTopic = await caller.training.getTopicBySlug({
          slug: "kubernetes-architecture",
        });

        const updatedTable = updatedTopic?.sections?.[0].tables?.find(
          (t) => t.id === table.id
        );
        expect(updatedTable?.rows?.length).toBeGreaterThan(0);
      }
    }
  });
});

describe("training.updateTableRow", () => {
  it("should require authentication", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    try {
      await caller.training.updateTableRow({
        rowId: 1,
        rowData: { col1: "updated" },
      });
      expect.fail("Should have thrown an error");
    } catch (error: any) {
      expect(error.code).toBe("UNAUTHORIZED");
    }
  });
});

describe("training.deleteTableRow", () => {
  it("should require authentication", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    try {
      await caller.training.deleteTableRow({ rowId: 1 });
      expect.fail("Should have thrown an error");
    } catch (error: any) {
      expect(error.code).toBe("UNAUTHORIZED");
    }
  });
});

describe("training.addNote", () => {
  it("should require authentication", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    try {
      await caller.training.addNote({
        sectionId: 1,
        noteType: "tip",
        content: "Test note",
      });
      expect.fail("Should have thrown an error");
    } catch (error: any) {
      expect(error.code).toBe("UNAUTHORIZED");
    }
  });

  it("should add a note for authenticated users", async () => {
    const ctx = createContext(authenticatedUser);
    const caller = appRouter.createCaller(ctx);

    // Get a section ID first
    const topic = await caller.training.getTopicBySlug({
      slug: "kubernetes-architecture",
    });

    if (topic?.sections && topic.sections.length > 0) {
      const sectionId = topic.sections[0].id;
      const noteContent = `Test note ${Date.now()}`;

      const result = await caller.training.addNote({
        sectionId,
        noteType: "tip",
        title: "Test Note",
        content: noteContent,
      });

      expect(result).toBeDefined();

      // Verify the note was added
      const updatedTopic = await caller.training.getTopicBySlug({
        slug: "kubernetes-architecture",
      });

      const section = updatedTopic?.sections?.find((s) => s.id === sectionId);
      expect(section?.notes?.length).toBeGreaterThan(0);
    }
  });
});

describe("training.updateNote", () => {
  it("should require authentication", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    try {
      await caller.training.updateNote({
        noteId: 1,
        content: "Updated note",
      });
      expect.fail("Should have thrown an error");
    } catch (error: any) {
      expect(error.code).toBe("UNAUTHORIZED");
    }
  });
});

describe("training.deleteNote", () => {
  it("should require authentication", async () => {
    const ctx = createContext();
    const caller = appRouter.createCaller(ctx);

    try {
      await caller.training.deleteNote({ noteId: 1 });
      expect.fail("Should have thrown an error");
    } catch (error: any) {
      expect(error.code).toBe("UNAUTHORIZED");
    }
  });
});
