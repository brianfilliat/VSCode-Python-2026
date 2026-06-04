import { eq } from "drizzle-orm";
import { drizzle } from "drizzle-orm/mysql2";
import {
  InsertUser,
  users,
  trainingTopics,
  trainingSections,
  trainingTables,
  trainingTableRows,
  trainingNotes,
  contentRevisions,
} from "../drizzle/schema";
import { ENV } from './_core/env';

let _db: ReturnType<typeof drizzle> | null = null;

// Lazily create the drizzle instance so local tooling can run without a DB.
export async function getDb() {
  if (!_db && process.env.DATABASE_URL) {
    try {
      _db = drizzle(process.env.DATABASE_URL);
    } catch (error) {
      console.warn("[Database] Failed to connect:", error);
      _db = null;
    }
  }
  return _db;
}

export async function upsertUser(user: InsertUser): Promise<void> {
  if (!user.openId) {
    throw new Error("User openId is required for upsert");
  }

  const db = await getDb();
  if (!db) {
    console.warn("[Database] Cannot upsert user: database not available");
    return;
  }

  try {
    const values: InsertUser = {
      openId: user.openId,
    };
    const updateSet: Record<string, unknown> = {};

    const textFields = ["name", "email", "loginMethod"] as const;
    type TextField = (typeof textFields)[number];

    const assignNullable = (field: TextField) => {
      const value = user[field];
      if (value === undefined) return;
      const normalized = value ?? null;
      values[field] = normalized;
      updateSet[field] = normalized;
    };

    textFields.forEach(assignNullable);

    if (user.lastSignedIn !== undefined) {
      values.lastSignedIn = user.lastSignedIn;
      updateSet.lastSignedIn = user.lastSignedIn;
    }
    if (user.role !== undefined) {
      values.role = user.role;
      updateSet.role = user.role;
    } else if (user.openId === ENV.ownerOpenId) {
      values.role = 'admin';
      updateSet.role = 'admin';
    }

    if (!values.lastSignedIn) {
      values.lastSignedIn = new Date();
    }

    if (Object.keys(updateSet).length === 0) {
      updateSet.lastSignedIn = new Date();
    }

    await db.insert(users).values(values).onDuplicateKeyUpdate({
      set: updateSet,
    });
  } catch (error) {
    console.error("[Database] Failed to upsert user:", error);
    throw error;
  }
}

export async function getUserByOpenId(openId: string) {
  const db = await getDb();
  if (!db) {
    console.warn("[Database] Cannot get user: database not available");
    return undefined;
  }

  const result = await db.select().from(users).where(eq(users.openId, openId)).limit(1);

  return result.length > 0 ? result[0] : undefined;
}

/**
 * Training Topics
 */
export async function getTrainingTopics() {
  const db = await getDb();
  if (!db) return [];
  return db.select().from(trainingTopics).orderBy(trainingTopics.order);
}

export async function getTrainingTopicBySlug(slug: string) {
  const db = await getDb();
  if (!db) return undefined;
  const result = await db
    .select()
    .from(trainingTopics)
    .where(eq(trainingTopics.slug, slug))
    .limit(1);
  return result[0];
}

/**
 * Training Sections
 */
export async function getTrainingSectionsByTopic(topicId: number) {
  const db = await getDb();
  if (!db) return [];
  return db
    .select()
    .from(trainingSections)
    .where(eq(trainingSections.topicId, topicId))
    .orderBy(trainingSections.order);
}

export async function updateTrainingSection(
  sectionId: number,
  content: string
) {
  const db = await getDb();
  if (!db) return;
  return db
    .update(trainingSections)
    .set({ content, updatedAt: new Date() })
    .where(eq(trainingSections.id, sectionId));
}

/**
 * Training Tables
 */
export async function getTrainingTablesBySection(sectionId: number) {
  const db = await getDb();
  if (!db) return [];
  return db
    .select()
    .from(trainingTables)
    .where(eq(trainingTables.sectionId, sectionId));
}

export async function getTrainingTableRows(tableId: number) {
  const db = await getDb();
  if (!db) return [];
  return db
    .select()
    .from(trainingTableRows)
    .where(eq(trainingTableRows.tableId, tableId))
    .orderBy(trainingTableRows.order);
}

export async function addTrainingTableRow(
  tableId: number,
  rowData: Record<string, unknown>,
  order: number
) {
  const db = await getDb();
  if (!db) return;
  return db.insert(trainingTableRows).values({
    tableId,
    rowData: JSON.stringify(rowData),
    order,
  });
}

export async function updateTrainingTableRow(
  rowId: number,
  rowData: Record<string, unknown>
) {
  const db = await getDb();
  if (!db) return;
  return db
    .update(trainingTableRows)
    .set({ rowData: JSON.stringify(rowData), updatedAt: new Date() })
    .where(eq(trainingTableRows.id, rowId));
}

export async function deleteTrainingTableRow(rowId: number) {
  const db = await getDb();
  if (!db) return;
  return db.delete(trainingTableRows).where(eq(trainingTableRows.id, rowId));
}

/**
 * Training Notes
 */
export async function getTrainingNotesBySection(sectionId: number) {
  const db = await getDb();
  if (!db) return [];
  return db
    .select()
    .from(trainingNotes)
    .where(eq(trainingNotes.sectionId, sectionId))
    .orderBy(trainingNotes.order);
}

export async function updateTrainingNote(
  noteId: number,
  content: string,
  title?: string
) {
  const db = await getDb();
  if (!db) return;
  const updateData: Record<string, unknown> = {
    content,
    updatedAt: new Date(),
  };
  if (title) updateData.title = title;
  return db
    .update(trainingNotes)
    .set(updateData)
    .where(eq(trainingNotes.id, noteId));
}

export async function addTrainingNote(
  sectionId: number,
  noteType: "definition" | "example" | "tip" | "warning",
  content: string,
  title?: string,
  order?: number
) {
  const db = await getDb();
  if (!db) return;
  return db.insert(trainingNotes).values({
    sectionId,
    noteType,
    content,
    title,
    order: order ?? 0,
  });
}

export async function deleteTrainingNote(noteId: number) {
  const db = await getDb();
  if (!db) return;
  return db.delete(trainingNotes).where(eq(trainingNotes.id, noteId));
}

/**
 * Content Revisions
 */
export async function createContentRevision(
  originalContent: string,
  modifiedContent: string,
  sectionId?: number,
  tableId?: number,
  noteId?: number,
  modifiedBy?: number
) {
  const db = await getDb();
  if (!db) return;
  return db.insert(contentRevisions).values({
    originalContent,
    modifiedContent,
    sectionId,
    tableId,
    noteId,
    modifiedBy,
  });
}

export async function getContentRevisions(sectionId?: number) {
  const db = await getDb();
  if (!db) return [];
  if (sectionId) {
    return db
      .select()
      .from(contentRevisions)
      .where(eq(contentRevisions.sectionId, sectionId));
  }
  return db.select().from(contentRevisions);
}

