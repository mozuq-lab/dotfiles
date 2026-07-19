# dart-lsp

Dart / Flutter language server for Claude Code, providing code intelligence,
refactoring, and analysis (go-to-definition, find-references, diagnostics).

## Supported Extensions
`.dart`

## Requirements

The Dart language server ships with the Dart / Flutter SDK. Verify it is on your
`PATH`:

```bash
dart language-server --help
```

If you use [fvm](https://fvm.app/), make sure the active Dart SDK is exposed on
`PATH` (e.g. `~/fvm/default/bin`). The plugin invokes the bare `dart` command, so
whichever `dart` resolves first on `PATH` will be used.

## How it works

Defined via the `lspServers` entry in the local marketplace manifest
(`.claude-plugin/marketplace.json`):

```json
"lspServers": {
  "dart": {
    "command": "dart",
    "args": ["language-server", "--protocol=lsp"],
    "extensionToLanguage": { ".dart": "dart" }
  }
}
```

## More Information
- [Dart analysis server](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/tool/lsp_spec/README.md)
