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
  ["ses_fixture_json_model_parent", null, 0.15, 100, 200, 20, 500, 50, '{"id":"glm-5.3","provider":"openrouter"}'],
  ["ses_fixture_json_model_child", "ses_fixture_json_model_parent", 0.05, 10, 20, 0, 50, 5, '{"id":"glm-4-flash"}'],
  ["ses_unrelated", null, 9.99, 111, 222, 333, 444, 555, "other/model"],
];

const OPENCODE_NESTED_ROWS: Array<[string, string | null, number, number, number, number, number, number, string]> = [
  ["ses_nested_parent", "ses_nested_grandchild", 0.1, 100, 200, 20, 1000, 100, "model-parent"],
  ["ses_nested_child", "ses_nested_parent", 0.2, 10, 20, 3, 200, 30, "model-child"],
  ["ses_nested_grandchild", "ses_nested_child", 0.3, 5, 6, 1, 50, 7, "model-grandchild"],
];

function buildOpencode(
  dbPath: string,
  rows: Array<[string, string | null, number, number, number, number, number, number, string]> = OPENCODE_ROWS,
): void {
  const db = new Database(dbPath);
  db.exec(OPENCODE_SCHEMA);
  const insert = db.prepare(
    "INSERT INTO session (id, parent_id, cost, tokens_input, tokens_output," +
      " tokens_reasoning, tokens_cache_read, tokens_cache_write, model)" +
      " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
  );
  for (const row of rows) insert.run(...row);
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

function pbBytesWithLength(field: number, declaredLength: number, payload: Uint8Array): Uint8Array {
  return concatBytes(pbTag(field, 2), varintBytes(declaredLength), payload);
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
  return agyBlobFromUsage(usage, model);
}

function agyBlobFromUsage(usage: Uint8Array, model: string): Uint8Array {
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

const AGY_MALFORMED_ROWS: Array<[number, Uint8Array]> = [
  [0, agyBlob(1000, 20000, 300, 50, "gemini-3.8-flash")],
  // Missing #3, #9, and #10 used to pass the self-check as 0 == 0 + 0.
  [1, agyBlobFromUsage(
    concatBytes(pbVarint(1, 1318), pbVarint(2, 9999), pbVarint(5, 8888)),
    "gemini-3.8-flash",
  )],
  // The outer length claims bytes that are not present.
  [2, (() => {
    const valid = agyBlob(777, 666, 5, 2, "gemini-3.8-flash");
    const inner = valid.subarray(2);
    return pbBytesWithLength(1, inner.length + 2, inner);
  })()],
  // A second #10 field ends in a truncated varint. The old parser accepted
  // the earlier zero value and treated this row as verified.
  [3, agyBlobFromUsage(
    concatBytes(
      pbVarint(1, 1318),
      pbVarint(2, 777),
      pbVarint(3, 5),
      pbVarint(5, 666),
      pbVarint(9, 5),
      pbVarint(10, 0),
      new Uint8Array([0x50, 0x80]),
    ),
    "gemini-3.8-flash",
  )],
];

const AGY_MULTI_MODEL_ROWS: Array<[number, Uint8Array]> = [
  [0, agyBlob(100, 200, 30, 5, "gemini-3.8-flash")],
  [1, agyBlob(500, 1000, 80, 20, "gemini-3.8-pro")],
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
    console.error("usage: make_fixtures.ts opencode|opencode-nested|agy|agy-drift|agy-malformed|agy-multi-model <db-path>");
    return 2;
  }
  if (kind === "opencode") {
    buildOpencode(dbPath);
    return 0;
  }
  if (kind === "opencode-nested") {
    buildOpencode(dbPath, OPENCODE_NESTED_ROWS);
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
  if (kind === "agy-malformed") {
    buildAgy(dbPath, AGY_MALFORMED_ROWS);
    return 0;
  }
  if (kind === "agy-multi-model") {
    buildAgy(dbPath, AGY_MULTI_MODEL_ROWS);
    return 0;
  }
  console.error(`unknown fixture kind: ${kind}`);
  return 2;
}

process.exit(main(process.argv.slice(2)));
