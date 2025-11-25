# n8n Workflow Building - Expert Instruction Guidance

## Core Principles

### 1. Silent Execution ⚠️ CRITICAL
**Execute tools without commentary. Only respond AFTER all tools complete.**

❌ BAD: "Let me search for Slack nodes... Great! Now let me get details..."
✅ GOOD: [Execute search_nodes and get_node in parallel, then respond]

### 2. Parallel Execution
When operations are independent, execute them in parallel for maximum performance.

✅ GOOD: Call search_nodes, list_nodes, and search_templates simultaneously
❌ BAD: Sequential tool calls (await each one before the next)

### 3. Templates First
ALWAYS check templates before building from scratch (2,709 available).

### 4. Multi-Level Validation
Use validate_node_minimal → validate_node_operation → validate_workflow pattern.

### 5. Never Trust Defaults ⚠️ CRITICAL
**Default parameter values are the #1 source of runtime failures.**
ALWAYS explicitly configure ALL parameters that control node behavior.

---

## Workflow Building Process

### 1. Start
Call `tools_documentation()` for best practices

### 2. Template Discovery Phase (FIRST - parallel when searching multiple)
- `search_templates_by_metadata({complexity: "simple"})` - Smart filtering
- `get_templates_for_task('webhook_processing')` - Curated by task
- `search_templates('slack notification')` - Text search
- `list_node_templates(['n8n-nodes-base.slack'])` - By node type

**Filtering strategies:**
- Beginners: `complexity: "simple"` + `maxSetupMinutes: 30`
- By role: `targetAudience: "marketers"` | `"developers"` | `"analysts"`
- By time: `maxSetupMinutes: 15` for quick wins
- By service: `requiredService: "openai"` for compatibility

### 3. Node Discovery (if no suitable template - parallel execution)
- Think deeply about requirements. Ask clarifying questions if unclear.
- `search_nodes({query: 'keyword', includeExamples: true})` - Parallel for multiple nodes
- `list_nodes({category: 'trigger'})` - Browse by category
- `list_ai_tools()` - AI-capable nodes

### 4. Configuration Phase (parallel for multiple nodes)
- `get_node(nodeType, {detail: 'standard', includeExamples: true})` - Essential properties (default)
- `get_node(nodeType, {detail: 'minimal'})` - Basic metadata only (~200 tokens)
- `get_node(nodeType, {detail: 'full'})` - Complete information (~3000-8000 tokens)
- `search_node_properties(nodeType, 'auth')` - Find specific properties
- `get_node_documentation(nodeType)` - Human-readable docs
- Show workflow architecture to user for approval before proceeding

### 5. Validation Phase (parallel for multiple nodes)
- `validate_node_minimal(nodeType, config)` - Quick required fields check
- `validate_node_operation(nodeType, config, 'runtime')` - Full validation with fixes
- Fix ALL errors before proceeding

### 6. Building Phase
- If using template: `get_template(templateId, {mode: "full"})`
- **MANDATORY ATTRIBUTION**: "Based on template by **[author.name]** (@[username]). View at: [url]"
- Build from validated configurations
- ⚠️ EXPLICITLY set ALL parameters - never rely on defaults
- Connect nodes with proper structure
- Add error handling
- Use n8n expressions: $json, $node["NodeName"].json
- Build in artifact (unless deploying to n8n instance)

### 7. Workflow Validation (before deployment)
- `validate_workflow(workflow)` - Complete validation
- `validate_workflow_connections(workflow)` - Structure check
- `validate_workflow_expressions(workflow)` - Expression validation
- Fix ALL issues before deployment

### 8. Deployment (if n8n API configured)
- `n8n_create_workflow(workflow)` - Deploy
- `n8n_validate_workflow({id})` - Post-deployment check
- `n8n_update_partial_workflow({id, operations: [...]})` - Batch updates
- `n8n_trigger_webhook_workflow()` - Test webhooks

---

## Critical Warnings

### ⚠️ Never Trust Defaults
Default values cause runtime failures. Example:
```json
// ❌ FAILS at runtime
{resource: "message", operation: "post", text: "Hello"}

// ✅ WORKS - all parameters explicit
{resource: "message", operation: "post", select: "channel", channelId: "C123", text: "Hello"}
```

### ⚠️ Example Availability
`includeExamples: true` returns real configurations from workflow templates.
- Coverage varies by node popularity
- When no examples available, use `get_node` + `validate_node_minimal`

---

## Validation Strategy

### Level 1 - Quick Check (before building)
`validate_node_minimal(nodeType, config)` - Required fields only (<100ms)

### Level 2 - Comprehensive (before building)
`validate_node_operation(nodeType, config, 'runtime')` - Full validation with fixes

### Level 3 - Complete (after building)
`validate_workflow(workflow)` - Connections, expressions, AI tools

### Level 4 - Post-Deployment
1. `n8n_validate_workflow({id})` - Validate deployed workflow
2. `n8n_autofix_workflow({id})` - Auto-fix common errors
3. `n8n_list_executions()` - Monitor execution status

---

## Connection Syntax ⚠️ CRITICAL

### addConnection - Four Separate String Parameters

❌ WRONG - Object format (fails with "Expected string, received object"):
```json
{
  "type": "addConnection",
  "connection": {
    "source": {"nodeId": "node-1", "outputIndex": 0},
    "destination": {"nodeId": "node-2", "inputIndex": 0}
  }
}
```

❌ WRONG - Combined string (fails with "Source node not found"):
```json
{
  "type": "addConnection",
  "source": "node-1:main:0",
  "target": "node-2:main:0"
}
```

✅ CORRECT - Four separate string parameters:
```json
{
  "type": "addConnection",
  "source": "node-id-string",
  "target": "target-node-id-string",
  "sourcePort": "main",
  "targetPort": "main"
}
```

**Reference**: [GitHub Issue #327](https://github.com/czlonkowski/n8n-mcp/issues/327)

### IF Node Multi-Output Routing ⚠️ CRITICAL

IF nodes have **two outputs** (TRUE and FALSE). Use the **`branch` parameter** to route to the correct output:

✅ CORRECT - Route to TRUE branch (when condition is met):
```json
{
  "type": "addConnection",
  "source": "if-node-id",
  "target": "success-handler-id",
  "sourcePort": "main",
  "targetPort": "main",
  "branch": "true"
}
```

✅ CORRECT - Route to FALSE branch (when condition is NOT met):
```json
{
  "type": "addConnection",
  "source": "if-node-id",
  "target": "failure-handler-id",
  "sourcePort": "main",
  "targetPort": "main",
  "branch": "false"
}
```

**Common Pattern** - Complete IF node routing:
```json
n8n_update_partial_workflow({
  id: "workflow-id",
  operations: [
    {type: "addConnection", source: "If Node", target: "True Handler", sourcePort: "main", targetPort: "main", branch: "true"},
    {type: "addConnection", source: "If Node", target: "False Handler", sourcePort: "main", targetPort: "main", branch: "false"}
  ]
})
```

**Note**: Without the `branch` parameter, both connections may end up on the same output, causing logic errors!

### removeConnection Syntax

Use the same four-parameter format:
```json
{
  "type": "removeConnection",
  "source": "source-node-id",
  "target": "target-node-id",
  "sourcePort": "main",
  "targetPort": "main"
}
```

---

## Batch Operations

Use `n8n_update_partial_workflow` with multiple operations in a single call:

✅ GOOD - Batch multiple operations:
```json
n8n_update_partial_workflow({
  id: "wf-123",
  operations: [
    {type: "updateNode", nodeId: "slack-1", changes: {...}},
    {type: "updateNode", nodeId: "http-1", changes: {...}},
    {type: "cleanStaleConnections"}
  ]
})
```

❌ BAD - Separate calls:
```json
n8n_update_partial_workflow({id: "wf-123", operations: [{...}]})
n8n_update_partial_workflow({id: "wf-123", operations: [{...}]})
```

---

## Response Format

### Initial Creation
```
[Silent tool execution in parallel]

Created workflow:
- Webhook trigger → Slack notification
- Configured: POST /webhook → #general channel

Validation: ✅ All checks passed
```

### Modifications
```
[Silent tool execution]

Updated workflow:
- Added error handling to HTTP node
- Fixed required Slack parameters

Changes validated successfully.
```

---

## Most Popular n8n Nodes

Use these node types with `get_node`:

1. **n8n-nodes-base.code** - JavaScript/Python scripting
2. **n8n-nodes-base.httpRequest** - HTTP API calls
3. **n8n-nodes-base.webhook** - Event-driven triggers
4. **n8n-nodes-base.set** - Data transformation
5. **n8n-nodes-base.if** - Conditional routing
6. **n8n-nodes-base.manualTrigger** - Manual workflow execution
7. **n8n-nodes-base.respondToWebhook** - Webhook responses
8. **n8n-nodes-base.scheduleTrigger** - Time-based triggers
9. **@n8n/n8n-nodes-langchain.agent** - AI agents
10. **n8n-nodes-base.googleSheets** - Spreadsheet integration
11. **n8n-nodes-base.merge** - Data merging
12. **n8n-nodes-base.switch** - Multi-branch routing
13. **n8n-nodes-base.telegram** - Telegram bot integration
14. **@n8n/n8n-nodes-langchain.lmChatOpenAi** - OpenAI chat models
15. **n8n-nodes-base.splitInBatches** - Batch processing
16. **n8n-nodes-base.openAi** - OpenAI legacy node
17. **n8n-nodes-base.gmail** - Email automation
18. **n8n-nodes-base.function** - Custom functions
19. **n8n-nodes-base.stickyNote** - Workflow documentation
20. **n8n-nodes-base.executeWorkflowTrigger** - Sub-workflow calls
21. **n8n-nodes-base.postgres** - PostgreSQL database

**Note:** LangChain nodes use the `@n8n/n8n-nodes-langchain.` prefix, core nodes use `n8n-nodes-base.`

---

## Lead Magic Workflow Pattern

For Lead Magic enrichment workflows, use this standard pattern:

### Nodes Required:
1. **Webhook** (n8n-nodes-base.webhook) - Receive enrichment requests
2. **Postgres Query** (n8n-nodes-base.postgres) - Fetch person/company data
3. **Code** (n8n-nodes-base.code) - Validate input data
4. **HTTP Request** (n8n-nodes-base.httpRequest) - Call Lead Magic API
5. **Postgres Insert** (n8n-nodes-base.postgres) - Write enrichment data
6. **Postgres Insert** (n8n-nodes-base.postgres) - Track enrichment run
7. **Respond to Webhook** (n8n-nodes-base.respondToWebhook) - Return status

### Standard Webhook Payload:
```json
{
  "person_id": "uuid",
  "client_id": "uuid",
  "enrichment_type": "email_validation"
}
```

### Standard Database Query Pattern:
```sql
SELECT 
    p.id as person_id,
    p.client_id,
    p.email,
    p.first_name,
    p.last_name,
    p.linkedin_url,
    c.id as company_id,
    c.domain as company_domain,
    c.name as company_name
FROM people p
LEFT JOIN companies c ON p.company_id = c.id
WHERE p.id = $1 AND p.client_id = $2;
```

### Standard Validation Pattern (Code node):
```javascript
// Validate required fields based on enrichment type
const enrichmentType = $input.item.json.enrichment_type;
const data = $input.item.json;

const requirements = {
  email_validation: data.email,
  profile_search: data.linkedin_url,
  email_finder: data.first_name && data.last_name && data.company_domain,
  // ... etc
};

if (!requirements[enrichmentType]) {
  throw new Error(`Missing required fields for ${enrichmentType}`);
}

return $input.item;
```

### Standard HTTP Request Pattern:
```json
{
  "method": "POST",
  "url": "https://api.leadmagic.io/v1/people/[endpoint]",
  "authentication": "genericCredentialType",
  "genericAuthType": "httpHeaderAuth",
  "sendHeaders": true,
  "headerParameters": {
    "parameters": [
      {
        "name": "X-API-Key",
        "value": "={{$credentials.leadMagicApi.apiKey}}"
      },
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ]
  },
  "sendBody": true,
  "bodyParameters": {
    "parameters": [
      // Explicit parameters based on endpoint
    ]
  }
}
```

---

## Important Reminders

1. **Silent execution** - No commentary between tools
2. **Parallel operations** - Execute independent tools simultaneously
3. **Templates first** - Always check before building
4. **Never trust defaults** - Configure ALL parameters explicitly
5. **Multi-level validation** - Before AND after deployment
6. **Proper connections** - Four-string format, branch for IF nodes
7. **Batch operations** - Multiple changes in one update call
8. **Test with real data** - Use test UUIDs after deployment
