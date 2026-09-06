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

const AGY_SCHEMA = `
CREATE TABLE gen_metadata (idx integer PRIMARY KEY, data blob, size integer NOT NULL DEFAULT 0);
`;

function varintBytes(value: number): Uint8Array {
  const out: number[] = [];
  for (;;) {
    const byte = value % 128;
    value = Math.floor(value / 128);
    if (value !== 0) out.push(byte + 128);
    else {
      out.push(byte);
      return new Uint8Array(out);
    }
  }
}

function pbTag(field: number, wire: number): Uint8Array {
  return varintBytes(field * 8 + wire);
}

function pbVarint(field: number, value: number): Uint8Array {
  return concatBytes(pbTag(field, 0), varintBytes(value));
}

function pbBytes(field: number, payload: Uint8Array): Uint8Array {
  return concatBytes(pbTag(field, 2), varintBytes(payload.length), payload);
}

function concatBytes(...parts: Uint8Array[]): Uint8Array {
  const total = parts.reduce((sum, part) => sum + part.length, 0);
  const out = new Uint8Array(total);
  let offset = 0;
  for (const part of parts) {
    out.set(part, offset);
    offset += part.length;
  }
  return out;
}

function agyBlob(
  newInput: number,
  cacheRead: number,
  output: number,
  thinking: number,
  model: string,
  storedTotal?: number,
): Uint8Array {
  // Build one gen_metadata blob. Pass storedTotal to force parse drift.
  const total = storedTotal ?? output + thinking;
  const usage = concatBytes(
    pbVarint(1, 1318),
    pbVarint(2, newInput),
    pbVarint(3, total),
    pbVarint(5, cacheRead),
    pbVarint(9, output),
    pbVarint(10, thinking),
    pbBytes(11, new TextEncoder().encode("resp-id")),
  );
  const inner = concatBytes(
    pbVarint(3, 1318),
    pbBytes(4, usage),
    pbBytes(19, new TextEncoder().encode(model)),
  );
  return pbBytes(1, inner);
}

const AGY_ROWS: Array<[number, Uint8Array]> = [
  [0, agyBlob(1000, 20000, 300, 50, "gemini-3.8-flash")],
  [1, agyBlob(2000, 30000, 400, 60, "gemini-3.8-flash")],
  // Drifted row: stored total disagrees with output + thinking, so it must be
  // dropped rather than guessed at.
  [2, agyBlob(9999, 99999, 999, 99, "gemini-3.8-flash", 1)],
];

function buildAgy(dbPath: string, rows: Array<[number, Uint8Array]> = AGY_ROWS): void {
  const db = new Database(dbPath);
  db.exec(AGY_SCHEMA);
  const insert = db.prepare("INSERT INTO gen_metadata (idx, data, size) VALUES (?, ?, ?)");
  for (const [idx, blob] of rows) insert.run(idx, blob, blob.length);
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
  if (kind === "agy") {
    buildAgy(dbPath);
    return 0;
  }
  if (kind === "agy-drift") {
    buildAgy(dbPath, [AGY_ROWS[2]!]);
    return 0;
  }
  console.error(`unknown fixture kind: ${kind}`);
  return 2;
}

process.exit(main(process.argv.slice(2)));
