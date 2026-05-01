# Amazon Q MCP Server Setup Guide 2026

## Overview

MCP (Model Context Protocol) servers extend Amazon Q Developer with additional tools and capabilities.
AWS maintains a collection of MCP servers at: https://github.com/awslabs/mcp

> ⚠️ **Important:** AWS MCP servers run as **local stdio processes**, NOT remote HTTP endpoints.
> Using HTTP transport will cause: `SSE error: Invalid content type, expected "text/event-stream"`

---

## Prerequisites

Install `uv` (Python package runner):
```bash
# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# Verify installation
uvx --version
```

Reference: https://docs.astral.sh/uv/getting-started/installation/

---

## Configuration File Location

| Scope  | Path |
|--------|------|
| Global | `~/.aws/amazonq/mcp.json` |
| Local  | `.amazonq/mcp.json` (project root) |

---

## Setup: stdio Transport (Correct Method)

### Option 1 — Via Amazon Q IDE UI

1. Open Amazon Q MCP configuration UI
2. Click the **+** symbol
3. Select scope: **global** or **local**
4. Enter a **Name** (e.g., `aws-docs`)
5. Select **stdio** as the transport protocol
6. Set the **Command** (e.g., `uvx`)
7. Set **Args** (e.g., `awslabs.aws-documentation-mcp-server@latest`)
8. Click **Save**

### Option 2 — Edit JSON Directly
C:\Users\Mikef\.aws\amazonq\mcpAdmin
Edit `~/.aws/amazonq/mcp.json
C:\Users\Mikef\.aws\amazonq\mcpAdmin\mcp-state.json

```json
{
  "mcpServers": {
    "aws-docs": {
      "command": "uvx",
      "args": ["awslabs.aws-documentation-mcp-server@latest"],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR"
      }
    }
  }
}
```

---

## Available AWS MCP Servers

| Server | Args Value |
|--------|-----------|
| AWS Documentation | `awslabs.aws-documentation-mcp-server@latest` |
| Amazon Bedrock | `awslabs.amazon-bedrock-mcp-server@latest` |
| AWS CDK | `awslabs.cdk-mcp-server@latest` |
| Amazon S3 | `awslabs.s3-mcp-server@latest` |
| AWS Cost Explorer | `awslabs.cost-explorer-mcp-server@latest` |

Full list: https://github.com/awslabs/mcp

---

## Multiple Servers Example

```json
{
  "mcpServers": {
    "aws-docs": {
      "command": "uvx",
      "args": ["awslabs.aws-documentation-mcp-server@latest"],
      "env": { "FASTMCP_LOG_LEVEL": "ERROR" }
    },
    "aws-cdk": {
      "command": "uvx",
      "args": ["awslabs.cdk-mcp-server@latest"],
      "env": { "FASTMCP_LOG_LEVEL": "ERROR" }
    }
  }
}
```

---

## HTTP Transport (Remote Servers Only)

Use HTTP transport **only** for custom remote MCP servers you host yourself.

1. Open MCP configuration UI → **+**
2. Select scope
3. Enter **Name**
4. Select **http** as transport
5. Enter your server **URL** (e.g., `https://your-domain.com/mcp`)
6. Add optional **Headers** (key-value pairs)
7. Set **Timeout**
8. Click **Save**

```json
{
  "mcpServers": {
    "my-remote-server": {
      "url": "https://your-domain.com/mcp",
      "headers": {
        "Authorization": "Bearer <your-token>"
      }
    }
  }
}
```

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `SSE error: Invalid content type` | Using HTTP transport for a stdio server | Switch transport to **stdio** |
| `command not found: uvx` | `uv` not installed | Install uv (see Prerequisites) |
| Server not appearing in Q | Config file path wrong | Check scope — global vs local path |

---

## References

- AWS MCP Servers: https://github.com/awslabs/mcp
- uv Installation: https://docs.astral.sh/uv/getting-started/installation/
- Amazon Q Developer Docs: https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/

---

*Last Updated: 2026 | Status: Active*
