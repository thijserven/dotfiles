import { parse as parseToml } from 'smol-toml';
import { formatKeys, object, titleCase, type Shortcut } from '../shared';

function aerospaceTitle(command: string): string {
  const parts = command
    .trim()
    .split(/\s+/)
    .filter((part) => !part.startsWith('--'));
  const action = parts[0] || '';
  if (action === 'mode' && parts[1]) {
    return parts[1] === 'main' ? 'Return to normal shortcuts' : `Switch to ${parts[1]} shortcuts`;
  }
  if (action === 'move-workspace-to-monitor' && parts[1])
    return `Move workspace to ${parts[1]} monitor`;
  return titleCase(parts.join(' '));
}

export function aerospaceShortcuts(text: string, file: string): Shortcut[] {
  const config = parseToml(text);
  return Object.entries(object(config.mode)).flatMap(([mode, value]) =>
    Object.entries(object(object(value).binding)).map(([keys, commands]) => {
      if (
        typeof commands !== 'string' &&
        !(Array.isArray(commands) && commands.every((command) => typeof command === 'string'))
      ) {
        throw new Error(`Invalid AeroSpace binding: ${mode}.${keys}`);
      }

      return {
        title: (Array.isArray(commands) ? commands : [commands]).map(aerospaceTitle).join(' - '),
        keys: formatKeys(keys.split('-').join(' + ')),
        category: `AeroSpace - ${titleCase(mode)}`,
        tags: ['aerospace', mode],
        file,
        source: 'aerospace',
        id: `${mode}.${keys}`,
      };
    }),
  );
}
