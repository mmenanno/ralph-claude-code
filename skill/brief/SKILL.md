---
name: brief
description: "Generate a project brief to use for a ralph loop. Triggers on: create a ralph brief, write brief for ralph, plan my ralph loop."
---

# Brief Generator

Transform task requests into well-structured implementation briefs optimized for autonomous AI execution in Ralph loops.

---

## Workflow

1. **Check for existing BRIEF.md** - Before starting, check if `BRIEF.md` already exists in the working directory
   - If it exists, use `AskUserQuestion` to prompt the user with options:
     - Overwrite the existing file
     - Stop and do nothing
     - Provide an alternative filename
   - If the user chooses to stop, halt immediately without further action
   - If the user chooses an alternative filename, use their provided filename instead of `BRIEF.md`
2. Gather the user's task or feature request
3. Use `AskUserQuestion` to ask clarifying questions (1-4 questions per call, 2-4 options each). Continue asking follow-up questions in subsequent calls until you fully understand the task—do not rush to write the brief until all ambiguity is resolved
4. Compose answers into a structured brief document
5. Write output to `BRIEF.md` (or the alternative filename if specified)

**Essential:** Just create the brief, don't begin working on it

---

## Step 1: Gather Requirements

Only ask questions when the initial request leaves critical details unclear. Target these areas:

- **Objective:** What outcome or problem does this address?
- **Key Features:** What actions must the system support?
- **Boundaries:** What's explicitly out of scope?
- **Done Criteria:** What signals completion?

### Using AskUserQuestion

Use the `AskUserQuestion` tool to gather requirements interactively:

- **1-4 questions per call** — group related questions together
- **2-4 options per question** — users can always select "Other" for custom input
- **header** — max 12 characters, displayed as a chip/tag
- **label** — 1-5 words, concise choice text
- **description** — explains what the option means or its implications
- **multiSelect** — set to `true` when choices are not mutually exclusive
- **Iterate as needed** — make multiple calls until you have complete clarity

#### Example: Single-select questions

```json
{
  "questions": [
    {
      "question": "How should data be persisted?",
      "header": "Persistence",
      "options": [
        { "label": "Session-only", "description": "Ephemeral, lost on refresh" },
        { "label": "Database", "description": "Stored permanently in DB" },
        { "label": "Cache", "description": "Temporary with TTL" }
      ],
      "multiSelect": false
    },
    {
      "question": "What triggers this feature?",
      "header": "Trigger",
      "options": [
        { "label": "User action", "description": "Button click or form submit" },
        { "label": "Scheduled", "description": "Cron or background job" },
        { "label": "Webhook", "description": "External event or API call" }
      ],
      "multiSelect": false
    }
  ]
}
```

#### Example: Multi-select question

Use `multiSelect: true` when the user may need multiple options:

```json
{
  "questions": [
    {
      "question": "Which platforms should this feature support?",
      "header": "Platforms",
      "options": [
        { "label": "Web browser", "description": "Desktop and mobile web" },
        { "label": "iOS app", "description": "Native iPhone/iPad" },
        { "label": "Android app", "description": "Native Android devices" },
        { "label": "API only", "description": "Headless, no UI" }
      ],
      "multiSelect": true
    }
  ]
}
```

---

## Step 2: Scope Each Task for a Single Iteration

**Critical constraint: Every task must fit within one context window.**

Each Ralph iteration starts fresh with no memory of prior work. Oversized tasks exhaust the context before completion, resulting in incomplete or broken output.

### Appropriately scoped

- Add a validation rule to an existing form field
- Create an API endpoint that returns a single resource
- Implement a toggle switch for a settings page
- Write a helper function with unit tests

### Needs decomposition

| Overloaded Task | Break Into |
| --------------- | ---------- |
| "Build user profile page" | Fetch user query, avatar upload, edit form, save action |
| "Add search functionality" | Search input component, API endpoint, results display, pagination |
| "Implement notifications" | Notification model, creation triggers, UI badge, notification list |
| "Set up file uploads" | Storage config, upload endpoint, progress indicator, file preview |

**Guideline:** If explaining the change takes more than 2-3 sentences, split it up.

---

## Step 3: Sequence by Dependencies

Tasks run in listed order. A task must never rely on something defined in a later task.

**Typical progression:**

1. Database schema and migrations
2. Backend logic / API routes
3. Frontend components consuming the API
4. Aggregate views or dashboards

**Dependency violation example:**

```text
TASK-001: UI component (depends on schema that doesn't exist yet!)
TASK-002: Schema change
```

The UI component task would fail because the schema isn't created until TASK-002.

---

## Step 4: Define Verifiable Acceptance Criteria

Every criterion must be objectively verifiable—something Ralph can confirm as done or not done.

### Concrete (good)

- "Create `expires_at` timestamp column on sessions table"
- "Error message displays below input field when validation fails"
- "API returns 404 status code when resource not found"
- "Modal closes when clicking outside its boundary"
- "Test suite passes with no failures"

### Ambiguous (avoid)

- "Behaves as expected"
- "Fast response times"
- "Clean code"
- "User-friendly interface"

### Required criteria

Every task must include as the final items:

```text
"Testing passes"
"Linting passes"
```

### Tasks modifying the UI must also include

```text
"Verify changes work in browser"
```

---

## Brief Structure

Structure the brief with these sections:

### 1. Overview

Concise explanation of the task and the problem it addresses.

### 2. Objectives

Measurable outcomes in bullet form.

### 3. Tasks

Each task requires:

- **ID:** Sequential identifier (TASK-001, TASK-002, etc.)
- **Title:** Brief descriptive label
- **Description:** "As a [role], I need [capability] so that [value]"
- **Acceptance Criteria:** Checklist of verifiable conditions

**Template:**

```markdown
### TASK-001: [Title]
**Description:** As a [role], I need [capability] so that [value].

**Acceptance Criteria:**
- [ ] Verifiable condition
- [ ] Another condition
- [ ] Testing passes
- [ ] Linting passes
- [ ] [UI tasks] Verify changes work in browser
```

### 4. Out of Scope

Explicitly state what this feature will NOT do. Essential for maintaining focus.

### 5. Implementation Notes (Optional)

- Constraints or limitations
- Existing code to leverage

---

## Example Brief

```markdown
# Brief: Comment Threading System

## Introduction

Enable nested replies on comments so users can have focused discussions. Comments can have replies up to 3 levels deep, with collapse/expand controls and visual indentation.

## Objectives

- Support threaded replies on any comment
- Limit nesting to 3 levels to maintain readability
- Allow collapsing/expanding reply threads
- Show reply count on collapsed threads

## Tasks

### TASK-001: Add parent reference to comments table
**Description:** As a developer, I need to track comment relationships so replies link to their parent.

**Acceptance Criteria:**
- [ ] Add nullable `parent_id` foreign key column referencing comments table
- [ ] Add index on `parent_id` for query performance
- [ ] Migration runs without errors
- [ ] Testing passes
- [ ] Linting passes

### TASK-002: Create reply submission endpoint
**Description:** As a user, I need to submit a reply to an existing comment.

**Acceptance Criteria:**
- [ ] POST endpoint accepts `parent_id` and `content`
- [ ] Validates parent exists and nesting depth <= 3
- [ ] Returns 422 if max depth exceeded
- [ ] Testing passes
- [ ] Linting passes

### TASK-003: Render nested comment tree
**Description:** As a user, I want to see replies indented beneath their parent comment.

**Acceptance Criteria:**
- [ ] Replies render with increasing left margin per level
- [ ] Maximum 3 indentation levels displayed
- [ ] Reply count badge shows on comments with replies
- [ ] Testing passes
- [ ] Linting passes
- [ ] Verify changes work in browser

### TASK-004: Add collapse/expand toggle
**Description:** As a user, I want to collapse reply threads to reduce visual noise.

**Acceptance Criteria:**
- [ ] Toggle button appears on comments with replies
- [ ] Collapsed state hides all nested replies
- [ ] Toggle state persists in component state (not URL)
- [ ] Testing passes
- [ ] Linting passes
- [ ] Verify changes work in browser

## Out of Scope

- No @mentions or notifications for replies
- No editing or deleting replies after posting
- No pagination within threads

## Implementation Notes

- Leverage existing Comment component, add depth prop
- Use recursive rendering for nested structure
```

---

## Output

Write the completed brief to `BRIEF.md` in the working directory (or the alternative filename if one was specified during the file existence check).

---

## Pre-Save Validation

Before saving, confirm:

- [ ] Checked if BRIEF.md already exists and prompted user if so
- [ ] Clarifying questions were asked using `AskUserQuestion`
- [ ] User responses are reflected in the brief
- [ ] Tasks follow TASK-001 sequential ID format
- [ ] Each task fits within a single iteration (appropriately scoped)
- [ ] Task order respects dependencies (data layer → logic → UI)
- [ ] All acceptance criteria are objectively checkable
- [ ] Every task includes "Testing passes" and "Linting passes"
- [ ] UI-related tasks include "Verify changes work in browser"
- [ ] Out of Scope section clearly defines boundaries
- [ ] If applicable constraints or limitations are added to Implementation Notes
- [ ] You have looked for existing code to leverage and if applicable added it to Implementation Notes
- [ ] Brief written to BRIEF.md (or alternative filename if specified)
