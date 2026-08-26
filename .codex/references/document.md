# Document writing

## Tone and style

- Organize user-facing documents around the reader's path to success: purpose, prerequisites and safety, setup or wiring, execution, result verification, troubleshooting, then technical reference material.
- Prefer the shortest complete path in a README. Put exhaustive options and detailed specifications in `docs/`, and link instead of repeating the same explanation.
- Explain the expected result immediately after a command. For logs, say what the message means and what the reader should do next.
- Use a clear, direct style.
- Treat `Raspberry Pi Pico 2` as the first-use board name and `Pico 2` as the subsequent short form.
- Wrap API names, class names, commands, paths, and log values in backticks.
- Put a space between a number and a unit symbol, such as `5 V`, `400 kHz`, and `350 ms`.
- For wiring and signal paths, use ASCII `->`. Prefer tables for simple pin mappings and arrows for paths through multiple components.
- Keep paired Japanese and English documents equivalent in heading order, commands, tables, code examples, and safety information. Translate for equivalent reader outcomes rather than word-for-word correspondence.
- When changing documentation, check Markdown links, heading hierarchy, table rendering, paired-document structure, and the standard terminology and punctuation searches.

### Japanese

- Use polite `です・ます` style in prose. Express required and unsafe actions explicitly with `〜してください` or `〜しないでください`.
- Use descriptive, goal-oriented headings such as `準備`, `配線`, `ビルドと実行`, `使い方`, `結果の確認`, and `トラブルシューティング`. Use `ファイル構成` when listing files and their roles.
- Use `クローン` and `R2P2シェル`.
- Do not add unnecessary spaces around English words or inline code in Japanese prose.
- Do not add a space before Japanese counters such as `8個` or `60秒`.
