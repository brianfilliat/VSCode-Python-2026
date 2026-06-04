import { protectedProcedure, publicProcedure, router } from "../_core/trpc";
import { getDb } from "../db";
import { z } from "zod";
import { TRPCError } from "@trpc/server";

export const trainingExportRouter = router({
  // Export all training content as JSON
  exportAsJSON: publicProcedure.query(async () => {
    const db = await getDb();
    if (!db) throw new TRPCError({ code: "INTERNAL_SERVER_ERROR", message: "Database unavailable" });

    const [topics] = await db.execute(`
      SELECT t.*, 
        COUNT(DISTINCT s.id) as sectionCount,
        COUNT(DISTINCT tr.id) as tableCount,
        COUNT(DISTINCT n.id) as noteCount
      FROM training_topics t
      LEFT JOIN training_sections s ON t.id = s.topicId
      LEFT JOIN training_tables tr ON s.id = tr.sectionId
      LEFT JOIN training_notes n ON s.id = n.sectionId
      GROUP BY t.id
      ORDER BY t.\`order\`
    `);

    const topicsWithContent = await Promise.all(
      (topics as any[]).map(async (topic) => {
        const [sections] = await db.execute(
          "SELECT * FROM training_sections WHERE topicId = ? ORDER BY `order`",
          [topic.id]
        );

        const sectionsWithContent = await Promise.all(
          (sections as any[]).map(async (section) => {
            const [tables] = await db.execute(
              "SELECT * FROM training_tables WHERE sectionId = ? ORDER BY id",
              [section.id]
            );

            const tablesWithRows = await Promise.all(
              (tables as any[]).map(async (table) => {
                const [rows] = await db.execute(
                  "SELECT * FROM training_table_rows WHERE tableId = ? ORDER BY `order`",
                  [table.id]
                );
                return { ...table, rows };
              })
            );

            const [notes] = await db.execute(
              "SELECT * FROM training_notes WHERE sectionId = ? ORDER BY `order`",
              [section.id]
            );

            return { ...section, tables: tablesWithRows, notes };
          })
        );

        return { ...topic, sections: sectionsWithContent };
      })
    );

    return topicsWithContent;
  }),

  // Export as HTML for printing
  exportAsHTML: publicProcedure.query(async () => {
    const db = await getDb();
    if (!db) throw new TRPCError({ code: "INTERNAL_SERVER_ERROR", message: "Database unavailable" });

    const [topics] = await db.execute(`
      SELECT * FROM training_topics ORDER BY \`order\`
    `);

    let html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Kubernetes Training Reference</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 1200px;
      margin: 0 auto;
      padding: 2rem;
      background: #f5f5f5;
    }
    h1 { color: #00d9ff; border-bottom: 3px solid #00d9ff; padding-bottom: 1rem; }
    h2 { color: #00d9ff; margin-top: 2rem; }
    h3 { color: #666; }
    table { width: 100%; border-collapse: collapse; margin: 1rem 0; background: white; }
    th, td { padding: 0.75rem; text-align: left; border: 1px solid #ddd; }
    th { background: #f0f0f0; font-weight: 600; }
    .section { page-break-inside: avoid; margin: 2rem 0; background: white; padding: 1.5rem; border-radius: 8px; }
    .note { background: #f9f9f9; padding: 1rem; margin: 1rem 0; border-left: 4px solid #00d9ff; }
    .note-type { font-weight: 600; color: #00d9ff; }
    @media print {
      body { background: white; }
      .section { page-break-inside: avoid; }
    }
  </style>
</head>
<body>
  <h1>Kubernetes Training Reference Guide</h1>
  <p>Generated: ${new Date().toLocaleString()}</p>
`;

    for (const topic of topics as any[]) {
      html += `<h2>${topic.title}</h2>`;
      html += `<p>${topic.description || ""}</p>`;

      const [sections] = await db.execute(
        "SELECT * FROM training_sections WHERE topicId = ? ORDER BY `order`",
        [topic.id]
      );

      for (const section of sections as any[]) {
        html += `<div class="section">`;
        html += `<h3>${section.title}</h3>`;
        html += `<p>${section.content || ""}</p>`;

        const [tables] = await db.execute(
          "SELECT * FROM training_tables WHERE sectionId = ? ORDER BY id",
          [section.id]
        );

        for (const table of tables as any[]) {
          html += `<h4>${table.title}</h4>`;
          const columns = JSON.parse(table.columns || "[]");
          const [rows] = await db.execute(
            "SELECT rowData FROM training_table_rows WHERE tableId = ? ORDER BY `order`",
            [table.id]
          );

          html += `<table>`;
          html += `<thead><tr>${columns.map((col: string) => `<th>${col}</th>`).join("")}</tr></thead>`;
          html += `<tbody>`;
          for (const row of rows as any[]) {
            const rowData = JSON.parse(row.rowData || "{}");
            html += `<tr>${columns.map((col: string) => `<td>${rowData[col] || ""}</td>`).join("")}</tr>`;
          }
          html += `</tbody></table>`;
        }

        const [notes] = await db.execute(
          "SELECT * FROM training_notes WHERE sectionId = ? ORDER BY `order`",
          [section.id]
        );

        for (const note of notes as any[]) {
          html += `<div class="note">`;
          html += `<span class="note-type">${note.noteType}</span>`;
          if (note.title) html += `<h4>${note.title}</h4>`;
          html += `<p>${note.content}</p>`;
          html += `</div>`;
        }

        html += `</div>`;
      }
    }

    html += `</body></html>`;
    return html;
  }),

  // Admin: Reset content to original seed data
  resetToOriginal: protectedProcedure.mutation(async ({ ctx }) => {
    if (ctx.user?.role !== "admin") {
      throw new TRPCError({ code: "FORBIDDEN", message: "Only admins can reset content" });
    }

    const db = await getDb();
    if (!db) throw new TRPCError({ code: "INTERNAL_SERVER_ERROR", message: "Database unavailable" });

    // Delete all current content
    await db.execute("DELETE FROM training_table_rows");
    await db.execute("DELETE FROM training_tables");
    await db.execute("DELETE FROM training_notes");
    await db.execute("DELETE FROM training_sections");
    await db.execute("DELETE FROM training_topics");

    // Re-seed original data
    const topics = [
      {
        title: "Kubernetes Architecture",
        slug: "kubernetes-architecture",
        description: "Understand the core components and architecture of Kubernetes",
        icon: "🏗️",
        order: 1,
      },
      {
        title: "Pods & Containers",
        slug: "pods-containers",
        description: "Learn about pods, containers, and container management",
        icon: "📦",
        order: 2,
      },
      {
        title: "Deployments & Scaling",
        slug: "deployments-scaling",
        description: "Manage deployments and scale applications",
        icon: "📈",
        order: 3,
      },
      {
        title: "Services & Networking",
        slug: "services-networking",
        description: "Configure services and network policies",
        icon: "🌐",
        order: 4,
      },
      {
        title: "Storage & Volumes",
        slug: "storage-volumes",
        description: "Manage persistent storage and volumes",
        icon: "💾",
        order: 5,
      },
      {
        title: "Security & RBAC",
        slug: "security-rbac",
        description: "Implement security controls and role-based access",
        icon: "🔒",
        order: 6,
      },
      {
        title: "ConfigMaps & Secrets",
        slug: "configmaps-secrets",
        description: "Manage configuration and sensitive data",
        icon: "🔑",
        order: 7,
      },
      {
        title: "Monitoring & Logging",
        slug: "monitoring-logging",
        description: "Monitor and log Kubernetes applications",
        icon: "📊",
        order: 8,
      },
    ];

    for (const topic of topics) {
      await db.execute(
        "INSERT INTO training_topics (title, slug, description, icon, `order`) VALUES (?, ?, ?, ?, ?)",
        [topic.title, topic.slug, topic.description, topic.icon, topic.order]
      );
    }

    return { success: true, message: "Content reset to original" };
  }),
});
