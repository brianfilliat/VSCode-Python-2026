import { int, mysqlEnum, mysqlTable, text, timestamp, varchar } from "drizzle-orm/mysql-core";

/**
 * Core user table backing auth flow.
 * Extend this file with additional tables as your product grows.
 * Columns use camelCase to match both database fields and generated types.
 */
export const users = mysqlTable("users", {
  /**
   * Surrogate primary key. Auto-incremented numeric value managed by the database.
   * Use this for relations between tables.
   */
  id: int("id").autoincrement().primaryKey(),
  /** Manus OAuth identifier (openId) returned from the OAuth callback. Unique per user. */
  openId: varchar("openId", { length: 64 }).notNull().unique(),
  name: text("name"),
  email: varchar("email", { length: 320 }),
  loginMethod: varchar("loginMethod", { length: 64 }),
  role: mysqlEnum("role", ["user", "admin"]).default("user").notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
  lastSignedIn: timestamp("lastSignedIn").defaultNow().notNull(),
});

export type User = typeof users.$inferSelect;
export type InsertUser = typeof users.$inferInsert;

/**
 * Training topics - main categories for Kubernetes content
 */
export const trainingTopics = mysqlTable("training_topics", {
  id: int("id").autoincrement().primaryKey(),
  title: varchar("title", { length: 255 }).notNull(),
  slug: varchar("slug", { length: 255 }).notNull().unique(),
  description: text("description"),
  icon: varchar("icon", { length: 64 }),
  order: int("order").default(0).notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type TrainingTopic = typeof trainingTopics.$inferSelect;
export type InsertTrainingTopic = typeof trainingTopics.$inferInsert;

/**
 * Training sections - subsections within each topic
 */
export const trainingSections = mysqlTable("training_sections", {
  id: int("id").autoincrement().primaryKey(),
  topicId: int("topicId").notNull(),
  title: varchar("title", { length: 255 }).notNull(),
  content: text("content"),
  order: int("order").default(0).notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type TrainingSection = typeof trainingSections.$inferSelect;
export type InsertTrainingSection = typeof trainingSections.$inferInsert;

/**
 * Training tables - structured data within sections
 */
export const trainingTables = mysqlTable("training_tables", {
  id: int("id").autoincrement().primaryKey(),
  sectionId: int("sectionId").notNull(),
  title: varchar("title", { length: 255 }).notNull(),
  tableName: varchar("tableName", { length: 255 }).notNull(),
  columns: text("columns"), // JSON array of column definitions
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type TrainingTable = typeof trainingTables.$inferSelect;
export type InsertTrainingTable = typeof trainingTables.$inferInsert;

/**
 * Training table rows - individual rows in training tables
 */
export const trainingTableRows = mysqlTable("training_table_rows", {
  id: int("id").autoincrement().primaryKey(),
  tableId: int("tableId").notNull(),
  rowData: text("rowData"), // JSON object with column values
  order: int("order").default(0).notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type TrainingTableRow = typeof trainingTableRows.$inferSelect;
export type InsertTrainingTableRow = typeof trainingTableRows.$inferInsert;

/**
 * Training notes - definitions, examples, tips, warnings
 */
export const trainingNotes = mysqlTable("training_notes", {
  id: int("id").autoincrement().primaryKey(),
  sectionId: int("sectionId").notNull(),
  noteType: mysqlEnum("noteType", ["definition", "example", "tip", "warning"]).notNull(),
  title: varchar("title", { length: 255 }),
  content: text("content").notNull(),
  order: int("order").default(0).notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type TrainingNote = typeof trainingNotes.$inferSelect;
export type InsertTrainingNote = typeof trainingNotes.$inferInsert;

/**
 * Content revisions - track changes for admin reset functionality
 */
export const contentRevisions = mysqlTable("content_revisions", {
  id: int("id").autoincrement().primaryKey(),
  sectionId: int("sectionId"),
  tableId: int("tableId"),
  noteId: int("noteId"),
  originalContent: text("originalContent").notNull(),
  modifiedContent: text("modifiedContent"),
  modifiedBy: int("modifiedBy"),
  revisionNumber: int("revisionNumber").default(1).notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
});

export type ContentRevision = typeof contentRevisions.$inferSelect;
export type InsertContentRevision = typeof contentRevisions.$inferInsert;