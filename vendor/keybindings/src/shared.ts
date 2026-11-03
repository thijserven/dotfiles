import { homedir } from "node:os";
import { isAbsolute, join } from "node:path";

export type Shortcut = {
  title: string;
  keys: string;
  category: string;
  tags: string[];
  file: string;
  source?: string;
  id?: string;
};

export type ObjectValue = Record<string, unknown>;

export function object(value: unknown): ObjectValue {
  return value !== null && typeof value === "object" && !Array.isArray(value) ? value as ObjectValue : {};
}

export function expandPath(value: string): string {
  const path = value.startsWith("~/") ? join(homedir(), value.slice(2)) : value;
  if (!isAbsolute(path)) throw new Error("Expected absolute path or ~/ path");
  return path;
}

export function titleCase(value: string): string {
  const label = value.replace(/[-_]+/g, " ").toLowerCase();
  return label.replace(/^\w/, character => character.toUpperCase());
}

export function formatKeys(value: string): string {
  const aliases: Record<string, string> = {
    slash: "/", comma: ",", period: ".", dot: ".", semicolon: ";", colon: ":",
    apostrophe: "'", quote: '"', backslash: "\\", backtick: "`", minus: "-", hyphen: "-",
    equal: "=", equals: "=", leftbracket: "[", rightbracket: "]", leftbrace: "{", rightbrace: "}",
    cmd: "cmd", command: "cmd", alt: "opt", option: "opt", super: "hyper",
    return: "return", enter: "enter", esc: "esc", escape: "esc", space: "space",
    backspace: "delete", delete: "⌫", ctrl: "ctrl", control: "ctrl", shift: "shift",
  };
  const tokens = value.split(/\s*\+\s*/).map(token => {
    const key = token.trim();
    return aliases[key.toLowerCase()] ?? key;
  });
  const keys = tokens.includes("hyper")
    ? ["hyper", ...tokens.filter(token => !["hyper", "ctrl", "opt", "shift"].includes(token))]
    : tokens;
  return keys.map(key => key.replace(/^\w/, character => character.toUpperCase())).join(" + ");
}
