import mysql from "mysql2/promise";
import dotenv from "dotenv";

dotenv.config();

const connection = await mysql.createConnection(process.env.DATABASE_URL);

// Training topics data
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

// Insert topics
console.log("Inserting training topics...");
for (const topic of topics) {
  await connection.execute(
    "INSERT INTO training_topics (title, slug, description, icon, `order`) VALUES (?, ?, ?, ?, ?)",
    [topic.title, topic.slug, topic.description, topic.icon, topic.order]
  );
}

// Get topics to get their IDs
const [topicsResult] = await connection.execute("SELECT id, slug FROM training_topics");
const topicMap = Object.fromEntries(topicsResult.map((t) => [t.slug, t.id]));

// Sample sections and content
const sectionsData = {
  "kubernetes-architecture": [
    {
      title: "Master Node Components",
      content: "The master node runs the Kubernetes control plane components including API Server, Scheduler, and Controller Manager.",
      tables: [
        {
          title: "Master Node Components",
          tableName: "master_components",
          columns: JSON.stringify(["Component", "Description", "Port"]),
          rows: [
            { Component: "API Server", Description: "RESTful API for cluster management", Port: "6443" },
            { Component: "Scheduler", Description: "Assigns pods to nodes", Port: "10251" },
            { Component: "Controller Manager", Description: "Runs controller processes", Port: "10252" },
            { Component: "etcd", Description: "Key-value store for cluster data", Port: "2379" },
          ],
        },
      ],
      notes: [
        {
          noteType: "definition",
          title: "Control Plane",
          content: "The control plane is the set of components that make global decisions about the cluster and detect and respond to cluster events.",
        },
        {
          noteType: "tip",
          title: "High Availability",
          content: "For production, run multiple master nodes in high availability configuration with load balancing.",
        },
      ],
    },
    {
      title: "Worker Node Components",
      content: "Worker nodes run containerized applications and communicate with the master node.",
      tables: [
        {
          title: "Worker Node Components",
          tableName: "worker_components",
          columns: JSON.stringify(["Component", "Description", "Function"]),
          rows: [
            { Component: "kubelet", Description: "Node agent", Function: "Ensures containers are running" },
            { Component: "kube-proxy", Description: "Network proxy", Function: "Maintains network rules" },
            { Component: "Container Runtime", Description: "Docker/containerd", Function: "Runs containers" },
          ],
        },
      ],
      notes: [
        {
          noteType: "definition",
          title: "kubelet",
          content: "The kubelet is the primary node agent that ensures containers are running in pods.",
        },
      ],
    },
  ],
  "pods-containers": [
    {
      title: "Pod Basics",
      content: "A pod is the smallest deployable unit in Kubernetes. It can contain one or more containers.",
      tables: [
        {
          title: "Pod Configuration",
          tableName: "pod_config",
          columns: JSON.stringify(["Property", "Type", "Required", "Description"]),
          rows: [
            { Property: "apiVersion", Type: "string", Required: "Yes", Description: "API version" },
            { Property: "kind", Type: "string", Required: "Yes", Description: "Resource type (Pod)" },
            { Property: "metadata", Type: "object", Required: "Yes", Description: "Pod metadata" },
            { Property: "spec", Type: "object", Required: "Yes", Description: "Pod specification" },
          ],
        },
      ],
      notes: [
        {
          noteType: "definition",
          title: "Pod",
          content: "A pod is a wrapper around one or more containers. Containers in a pod share network namespace.",
        },
        {
          noteType: "tip",
          title: "Single Container Pods",
          content: "Most pods contain a single container. Multi-container pods are used for tightly coupled containers.",
        },
      ],
    },
  ],
  "deployments-scaling": [
    {
      title: "Deployment Basics",
      content: "Deployments provide declarative updates for Pods and ReplicaSets.",
      tables: [
        {
          title: "Deployment Strategies",
          tableName: "deployment_strategies",
          columns: JSON.stringify(["Strategy", "Description", "Use Case"]),
          rows: [
            { Strategy: "Rolling Update", Description: "Gradually replace old pods", Use: "Default, safe updates" },
            { Strategy: "Recreate", Description: "Delete all pods then create new", Use: "When downtime acceptable" },
            { Strategy: "Blue-Green", Description: "Run two identical environments", Use: "Zero-downtime deployments" },
            { Strategy: "Canary", Description: "Gradually shift traffic", Use: "Risk mitigation" },
          ],
        },
      ],
      notes: [
        {
          noteType: "definition",
          title: "Deployment",
          content: "A Deployment provides declarative updates for Pods and ReplicaSets.",
        },
      ],
    },
  ],
};

// Insert sections and related data
console.log("Inserting training sections and content...");
for (const [slug, sections] of Object.entries(sectionsData)) {
  const topicId = topicMap[slug];
  if (!topicId) continue;

  for (let sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
    const section = sections[sectionIndex];

    // Insert section
    const [sectionResult] = await connection.execute(
      "INSERT INTO training_sections (topicId, title, content, `order`) VALUES (?, ?, ?, ?)",
      [topicId, section.title, section.content, sectionIndex]
    );
    const sectionId = sectionResult.insertId;

    // Insert tables
    if (section.tables) {
      for (const table of section.tables) {
        const [tableResult] = await connection.execute(
          "INSERT INTO training_tables (sectionId, title, tableName, columns) VALUES (?, ?, ?, ?)",
          [sectionId, table.title, table.tableName, table.columns]
        );
        const tableId = tableResult.insertId;

        // Insert table rows
        if (table.rows) {
          for (let rowIndex = 0; rowIndex < table.rows.length; rowIndex++) {
            await connection.execute(
              "INSERT INTO training_table_rows (tableId, rowData, `order`) VALUES (?, ?, ?)",
              [tableId, JSON.stringify(table.rows[rowIndex]), rowIndex]
            );
          }
        }
      }
    }

    // Insert notes
    if (section.notes) {
      for (let noteIndex = 0; noteIndex < section.notes.length; noteIndex++) {
        const note = section.notes[noteIndex];
        await connection.execute(
          "INSERT INTO training_notes (sectionId, noteType, title, content, `order`) VALUES (?, ?, ?, ?, ?)",
          [sectionId, note.noteType, note.title, note.content, noteIndex]
        );
      }
    }
  }
}

console.log("✅ Training data seeded successfully!");
await connection.end();
