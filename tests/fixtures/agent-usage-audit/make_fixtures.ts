#!/usr/bin/env bun
/**
 * Generate binary SQLite fixtures for the agent-usage-audit tests.
 *
 * The repository's .gitignore ignores *.db, so these fixtures cannot be
 * committed as binaries; the tests build them from this script instead.
 *
 * Usage:
 *   bun tests/fixtures/agent-usage-audit/make_fixtures.ts opencode <db-path>
 *   bun tests/fixtures/agent-usage-audit/make_fixtures.ts agy <db-path>
 *   bun tests/fixtures/agent-usage-audit/make_fixtures.ts agy-drift <db-path>
 */
import { Database } from "bun:sqlite";

const OPENCODE_SCHEMA = `
CREATE TABLE session (
  id text PRIMARY KEY,
  parent_id text,
  directory text NOT NULL DEFAULT '',
  title text NOT NULL DEFAULT '',
  cost real NOT NULL DEFAULT 0,
  tokens_input integer NOT NULL DEFAULT 0,
  tokens_output integer NOT NULL DEFAULT 0,
  tokens_reasoning integer NOT NULL DEFAULT 0,
  tokens_cache_read integer NOT NULL DEFAULT 0,
  tokens_cache_write integer NOT NULL DEFAULT 0,
  model text,
  time_updated integer NOT NULL DEFAULT 0
);
`;

// id, parent_id, cost, input, output, reasoning, cache_read, cache_write, model
const OPENCODE_ROWS: Array<[string, string | null, number, number, number, number, number, number, string]> = [
  ["ses_fixture_parent", null, 0.42, 120, 340, 60, 5000, 700, "anthropic/claude-opus-5"],
  ["ses_fixture_child", "ses_fixture_parent", 0.08, 20, 30, 5, 900, 100, "anthropic/claude-sonnet-5"],
  ["ses_fixture_zero_cost_parent", null, 0, 1, 2, 0, 0, 0, "anthropic/claude-haiku-5"],
  ["ses_fixture_zero_cost_child", "ses_fixture_zero_cost_parent", 0, 3, 4, 0, 0, 0, "anthropic/claude-haiku-5"],
  ["ses_unrelated", null, 9.99, 111, 222, 333, 444, 555, "other/model"],
];

function buildOpencode(dbPath: string): void {
  const db = new Database(dbPath);
  db.exec(OPENCODE_SCHEMA);
  const insert = db.prepare(
    "INSERT INTO session (id, parent_id, cost, tokens_input, tokens_output," +
      " tokens_reasoning, tokens_cache_read, tokens_cache_write, model)" +
      " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
  );
  for (const row of OPENCODE_ROWS) insert.run(...row);
  db.close();
}

function main(argv: string[]): number {
  const [kind, dbPath] = argv;
  if (!kind || !dbPath) {
    console.error("usage: make_fixtures.ts opencode|agy|agy-drift <db-path>");
    return 2;
  }
  if (kind === "opencode") {
    buildOpencode(dbPath);
    return 0;
  }
  console.error(`unknown fixture kind: ${kind}`);
  return 2;
}

process.exit(main(process.argv.slice(2)));
