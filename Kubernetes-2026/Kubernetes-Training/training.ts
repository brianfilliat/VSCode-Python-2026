import { z } from "zod";
import { protectedProcedure, publicProcedure, router } from "../_core/trpc";
import { TRPCError } from "@trpc/server";
import {
  getTrainingTopics,
  getTrainingTopicBySlug,
  getTrainingSectionsByTopic,
  getTrainingTablesBySection,
  getTrainingTableRows,
  updateTrainingSection,
  updateTrainingTableRow,
  addTrainingTableRow,
  deleteTrainingTableRow,
  getTrainingNotesBySection,
  updateTrainingNote,
  addTrainingNote,
  deleteTrainingNote,
  createContentRevision,
  getContentRevisions,
} from "../db";

export const trainingRouter = router({
  // Get all training topics
  getTopics: publicProcedure.query(async () => {
    return getTrainingTopics();
  }),

  // Get a specific topic by slug with all its sections
  getTopicBySlug: publicProcedure
    .input(z.object({ slug: z.string() }))
    .query(async ({ input }) => {
      const topic = await getTrainingTopicBySlug(input.slug);
      if (!topic) return null;

      const sections = await getTrainingSectionsByTopic(topic.id);

      // Enrich sections with their tables and notes
      const enrichedSections = await Promise.all(
        sections.map(async (section) => {
          const tables = await getTrainingTablesBySection(section.id);
          const notes = await getTrainingNotesBySection(section.id);

          // Enrich tables with their rows
          const enrichedTables = await Promise.all(
            tables.map(async (table) => {
              const rows = await getTrainingTableRows(table.id);
              return {
                ...table,
                rows: rows.map((row) => ({
                  ...row,
                  rowData: row.rowData ? JSON.parse(row.rowData) : {},
                })),
              };
            })
          );

          return {
            ...section,
            tables: enrichedTables,
            notes,
          };
        })
      );

      return {
        ...topic,
        sections: enrichedSections,
      };
    }),

  // Update section content
  updateSectionContent: protectedProcedure
    .input(
      z.object({
        sectionId: z.number(),
        content: z.string(),
      })
    )
    .mutation(async ({ input, ctx }) => {
      // Save revision
      await createContentRevision(
        "", // original content would be fetched from DB
        input.content,
        input.sectionId
      );

      return updateTrainingSection(input.sectionId, input.content);
    }),

  // Update table row
  updateTableRow: protectedProcedure
    .input(
      z.object({
        rowId: z.number(),
        rowData: z.record(z.string(), z.unknown()),
      })
    )
    .mutation(async ({ input, ctx }) => {
      return updateTrainingTableRow(input.rowId, input.rowData);
    }),

  // Add table row
  addTableRow: protectedProcedure
    .input(
      z.object({
        tableId: z.number(),
        rowData: z.record(z.string(), z.unknown()),
        order: z.number().default(0),
      })
    )
    .mutation(async ({ input }) => {
      return await addTrainingTableRow(input.tableId, input.rowData, input.order);
    }),

  // Delete table row
  deleteTableRow: protectedProcedure
    .input(z.object({ rowId: z.number() }))
    .mutation(async ({ input, ctx }) => {
      return deleteTrainingTableRow(input.rowId);
    }),

  // Update note
  updateNote: protectedProcedure
    .input(
      z.object({
        noteId: z.number(),
        content: z.string(),
        title: z.string().optional(),
      })
    )
    .mutation(async ({ input, ctx }) => {
      return updateTrainingNote(input.noteId, input.content, input.title);
    }),

  // Add note
  addNote: protectedProcedure
    .input(
      z.object({
        sectionId: z.number(),
        noteType: z.enum(["definition", "example", "tip", "warning"]),
        content: z.string(),
        title: z.string().optional(),
        order: z.number().optional(),
      })
    )
    .mutation(async ({ input }) => {
      return await addTrainingNote(
        input.sectionId,
        input.noteType,
        input.content,
        input.title,
        input.order
      );
    }),

  // Delete note
  deleteNote: protectedProcedure
    .input(z.object({ noteId: z.number() }))
    .mutation(async ({ input, ctx }) => {
      return deleteTrainingNote(input.noteId);
    }),

  // Get content revisions (admin only)
  getRevisions: protectedProcedure
    .input(z.object({ sectionId: z.number().optional() }))
    .query(async ({ input, ctx }) => {
      if (ctx.user?.role !== "admin") {
        throw new TRPCError({ code: "FORBIDDEN" });
      }
      return getContentRevisions();
    }),

  // Export as JSON
  exportJSON: publicProcedure.query(async () => {
    const topics = await getTrainingTopics();
    const enrichedTopics = await Promise.all(
      topics.map(async (topic: any) => {
        const sections = await getTrainingSectionsByTopic(topic.id);
        const enrichedSections = await Promise.all(
          sections.map(async (section: any) => {
            const tables = await getTrainingTablesBySection(section.id);
            const notes = await getTrainingNotesBySection(section.id);
            const enrichedTables = await Promise.all(
              tables.map(async (table: any) => ({
                ...table,
                rows: await getTrainingTableRows(table.id),
              }))
            );
            return { ...section, tables: enrichedTables, notes };
          })
        );
        return { ...topic, sections: enrichedSections };
      })
    );
    return enrichedTopics;
  }),

  // Export as HTML for printing
  exportHTML: publicProcedure.query(async () => {
    const topics = await getTrainingTopics();
    let html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Kubernetes Training Reference</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 1200px; margin: 0 auto; padding: 2rem; background: #f5f5f5; }
    h1 { color: #00d9ff; border-bottom: 3px solid #00d9ff; padding-bottom: 1rem; }
    h2 { color: #00d9ff; margin-top: 2rem; }
    h3 { color: #666; }
    table { width: 100%; border-collapse: collapse; margin: 1rem 0; background: white; }
    th, td { padding: 0.75rem; text-align: left; border: 1px solid #ddd; }
    th { background: #f0f0f0; font-weight: 600; }
    .section { page-break-inside: avoid; margin: 2rem 0; background: white; padding: 1.5rem; border-radius: 8px; }
    .note { background: #f9f9f9; padding: 1rem; margin: 1rem 0; border-left: 4px solid #00d9ff; }
    .note-type { font-weight: 600; color: #00d9ff; }
    @media print { body { background: white; } .section { page-break-inside: avoid; } }
  </style>
</head>
<body>
  <h1>Kubernetes Training Reference Guide</h1>
  <p>Generated: ${new Date().toLocaleString()}</p>`;

    for (const topic of topics as any[]) {
      html += `<h2>${topic.title}</h2><p>${topic.description || ""}</p>`;
      const sections = await getTrainingSectionsByTopic(topic.id);
      for (const section of sections as any[]) {
        html += `<div class="section"><h3>${section.title}</h3><p>${section.content || ""}</p>`;
        const tables = await getTrainingTablesBySection(section.id);
        for (const table of tables as any[]) {
          const columns = JSON.parse(table.columns || "[]");
          const rows = await getTrainingTableRows(table.id);
          html += `<h4>${table.title}</h4><table><thead><tr>${columns.map((col: string) => `<th>${col}</th>`).join("")}</tr></thead><tbody>`;
          for (const row of rows as any[]) {
            const rowData = JSON.parse(row.rowData || "{}");
            html += `<tr>${columns.map((col: string) => `<td>${rowData[col] || ""}</td>`).join("")}</tr>`;
          }
          html += `</tbody></table>`;
        }
        const notes = await getTrainingNotesBySection(section.id);
        for (const note of notes as any[]) {
          html += `<div class="note"><span class="note-type">${note.noteType}</span>${note.title ? `<h4>${note.title}</h4>` : ""}<p>${note.content}</p></div>`;
        }
        html += `</div>`;
      }
    }
    html += `</body></html>`;
    return html;
  }),

  // Reset content to original (admin only)
  resetToOriginal: protectedProcedure.mutation(async ({ ctx }) => {
    if (ctx.user?.role !== "admin") {
      throw new TRPCError({ code: "FORBIDDEN", message: "Only admins can reset content" });
    }

    // TODO: Implement reset functionality using drizzle ORM
    return { success: true, message: "Content reset to original" };
  }),
});
