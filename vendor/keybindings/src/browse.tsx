import { useEffect, useState } from 'react';
import { Action, ActionPanel, Color, Detail, getPreferenceValues, List } from '@vicinae/api';
import { loadShortcuts, type Options } from './data';

export default function Browse() {
  const [result, setResult] = useState<ReturnType<typeof loadShortcuts>>();
  const [category, setCategory] = useState('all');
  const [revision, setRevision] = useState(0);
  useEffect(() => {
    setResult(loadShortcuts(getPreferenceValues<Options>()));
  }, [revision]);
  const rows = result?.shortcuts || [];
  const categories = [...new Set(rows.map((row) => row.category))].sort();
  const refresh = (
    <Action title="Reload Files" onAction={() => setRevision((value) => value + 1)} />
  );
  return (
    <List
      isLoading={!result}
      searchBarPlaceholder="Search keys, actions, categories, tags..."
      searchBarAccessory={
        <List.Dropdown tooltip="Filter category" value={category} onChange={setCategory}>
          <List.Dropdown.Item value="all" title="All shortcuts" />
          {categories.map((value) => (
            <List.Dropdown.Item key={value} value={value} title={value} />
          ))}
        </List.Dropdown>
      }
    >
      {!!result?.warnings.length && (
        <List.Item
          title="Some shortcut sources could not be read"
          subtitle={`${result.warnings.length} error(s)`}
          actions={
            <ActionPanel>
              <Action.Push
                title="Show Errors"
                target={<Detail markdown={result.warnings.map((text) => `- ${text}`).join('\n')} />}
              />
              {refresh}
            </ActionPanel>
          }
        />
      )}
      {categories
        .filter((value) => category === 'all' || category === value)
        .map((value) => (
          <List.Section key={value} title={value}>
            {rows.map((row, index) =>
              row.category === value ? (
                <List.Item
                  key={String(index)}
                  title={row.title}
                  keywords={[row.keys, row.category, ...row.tags]}
                  accessories={row.keys.split(/\s*(\+)\s*/).map((part) =>
                    part === '+'
                      ? { text: { value: part, color: Color.SecondaryText } }
                      : { text: { value: part, color: Color.PrimaryText } },
                  )}
                  actions={
                    <ActionPanel>
                      <Action.CopyToClipboard title="Copy Keys" content={row.keys} />
                      {refresh}
                      <Action.Open title="Open Source File" target={row.file} />
                    </ActionPanel>
                  }
                />
              ) : null,
            )}
          </List.Section>
        ))}
      {result && rows.length === 0 && !result.warnings.length && (
        <List.EmptyView
          title="No shortcuts found"
          description="Configure source paths in extension preferences."
          actions={<ActionPanel>{refresh}</ActionPanel>}
        />
      )}
    </List>
  );
}
