#!/usr/bin/env node
// Build-time helper: for each dist/extensions/<id>, materialize a per-plugin
// node_modules/<dep> symlink into the hoisted /app/node_modules/<dep>.
//
// Why: the runtime plugin loader's ensureBundledPluginRuntimeDeps does a
// strict per-plugin sentinel check at <pluginRoot>/node_modules/<dep>/package.json
// (see src/plugins/bundled-runtime-deps.ts). On rootless Podman with
// ReadonlyRootfs=true, the loader cannot fall back to runtime npm install
// because /app/dist/extensions/<id>/node_modules does not exist and mkdir
// fails with ENOENT. Pre-creating those directories with symlinks into the
// already-hoisted root node_modules satisfies the sentinel check at zero
// runtime cost and a few KB of inodes per plugin.
//
// Skips deps that are not actually present at /app/node_modules — leaving a
// dangling symlink would re-trigger the loader's install path.

import fs from "node:fs";
import path from "node:path";

const repoRoot = process.cwd();
const distExtensionsDir = path.join(repoRoot, "dist", "extensions");
const rootNodeModules = path.join(repoRoot, "node_modules");

if (!fs.existsSync(distExtensionsDir)) {
  console.log("[link-bundled-plugin-deps] no dist/extensions directory; skipping");
  process.exit(0);
}
if (!fs.existsSync(rootNodeModules)) {
  console.error("[link-bundled-plugin-deps] no /app/node_modules; build is incomplete");
  process.exit(1);
}

function readJson(p) {
  try {
    return JSON.parse(fs.readFileSync(p, "utf8"));
  } catch {
    return null;
  }
}

function ensureSymlink(linkPath, targetAbs) {
  if (fs.existsSync(linkPath)) {
    return "exists";
  }
  fs.mkdirSync(path.dirname(linkPath), { recursive: true });
  fs.symlinkSync(targetAbs, linkPath);
  return "linked";
}

const pluginIds = fs
  .readdirSync(distExtensionsDir, { withFileTypes: true })
  .filter((d) => d.isDirectory())
  .map((d) => d.name);

let totalLinked = 0;
let totalExisting = 0;
let totalMissingTarget = 0;

for (const pluginId of pluginIds) {
  const pluginRoot = path.join(distExtensionsDir, pluginId);
  const pkgPath = path.join(pluginRoot, "package.json");
  const pkg = readJson(pkgPath);
  if (!pkg) {
    continue;
  }

  const deps = {
    ...pkg.dependencies,
    ...pkg.optionalDependencies,
  };
  const depNames = Object.keys(deps);
  if (depNames.length === 0) {
    continue;
  }

  for (const depName of depNames) {
    const targetAbs = path.join(rootNodeModules, depName);
    const linkPath = path.join(pluginRoot, "node_modules", depName);

    if (!fs.existsSync(targetAbs)) {
      totalMissingTarget++;
      continue;
    }

    try {
      const result = ensureSymlink(linkPath, targetAbs);
      if (result === "linked") {
        totalLinked++;
      } else {
        totalExisting++;
      }
    } catch (err) {
      console.error(`[link-bundled-plugin-deps] failed for ${pluginId}/${depName}: ${err.message}`);
      process.exit(1);
    }
  }
}

console.log(
  `[link-bundled-plugin-deps] linked=${totalLinked} existing=${totalExisting} missing-target=${totalMissingTarget}`,
);
