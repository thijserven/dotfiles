import { readFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { aerospaceShortcuts } from "./parsers/aerospace";
import { customShortcuts } from "./parsers/custom";
import { expandPath, type Shortcut } from "./shared";

export { aerospaceShortcuts } from "./parsers/aerospace";
export { customShortcuts } from "./parsers/custom";
export { expandPath, formatKeys, type Shortcut } from "./shared";

export type Options = {
  jsonPath?: string;
  sketchybarPath?: string;
  aerospacePath?: string;
  detectAerospace?: boolean;
};

export function loadShortcuts(options: Options): { shortcuts: Shortcut[]; warnings: string[] } {
  const shortcuts: Shortcut[] = [];
  const warnings: string[] = [];
  const read = (label: string, path: string, parse: (file: string) => Shortcut[], optional = false) => {
    try {
      shortcuts.push(...parse(expandPath(path)));
    } catch (error) {
      if (optional && (error as NodeJS.ErrnoException)?.code === "ENOENT") return;
      warnings.push(`${label}: ${path}: ${error instanceof Error ? error.message : String(error)}`);
    }
  };

  let overrides: Shortcut[] = [];
  if (options.jsonPath?.trim()) {
    try {
      const file = expandPath(options.jsonPath.trim());
      overrides = customShortcuts(readFileSync(file, "utf8"), file);
      shortcuts.push(...overrides.filter(row => !row.source || !row.id));
    } catch (error) {
      warnings.push(`JSON: ${options.jsonPath.trim()}: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  if (options.sketchybarPath?.trim()) {
    read("SketchyBar", options.sketchybarPath.trim(), file => customShortcuts(readFileSync(file, "utf8"), file), true);
  }

  if (options.detectAerospace) {
    const path = options.aerospacePath?.trim() || [join(homedir(), ".config/aerospace/aerospace.toml"), join(homedir(), ".aerospace.toml")].find(existsSync);
    if (path) read("AeroSpace", path, file => aerospaceShortcuts(readFileSync(file, "utf8"), file));
  }

  const overridesById = new Map(overrides.filter(row => row.source && row.id).map(row => [`${row.source}:${row.id}`, row]));
  const result = shortcuts.map(row => {
    const override = row.source && row.id ? overridesById.get(`${row.source}:${row.id}`) : undefined;
    return override ? {
      ...row,
      title: override.title,
      keys: override.keys,
      category: override.category === "Uncategorized" ? row.category : override.category,
      tags: [...new Set([...row.tags, ...override.tags])],
    } : row;
  });
  return { shortcuts: result, warnings };
}
