import { formatKeys, object, type Shortcut } from "../shared";

export function customShortcuts(text: string, file: string): Shortcut[] {
  const rows: unknown = JSON.parse(text);
  if (!Array.isArray(rows)) throw new Error("Expected JSON array");

  return rows.map((value, index) => {
    const row = object(value);
    if (typeof row.title !== "string" || !row.title.trim() || typeof row.keys !== "string" || !row.keys.trim() ||
        (row.category !== undefined && typeof row.category !== "string") ||
        (row.tags !== undefined && (!Array.isArray(row.tags) || row.tags.some(tag => typeof tag !== "string"))) ||
        ((row.source === undefined) !== (row.id === undefined)) ||
        (row.source !== undefined && row.source !== "aerospace") ||
        (row.id !== undefined && typeof row.id !== "string")) {
      throw new Error(`Invalid shortcut at row ${index + 1}`);
    }

    return {
      title: row.title,
      keys: formatKeys(row.keys),
      category: (row.category as string) || "Uncategorized",
      tags: (row.tags as string[]) || [],
      file,
      source: row.source as string | undefined,
      id: row.id as string | undefined,
    };
  });
}
