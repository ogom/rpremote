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

## Documentation cleanup and preservation

- Classify information by purpose before shortening it: operating guidance, safety, design rationale, executable contract, or temporary investigation record. Do not classify material only from its filename, age, or level of technical detail.
- Keep design rationale in human-facing documentation. A document that explains the problem, alternatives considered, selected approach, tradeoffs, and conditions for reconsideration remains useful even when it originated during a migration or debugging effort.
- Move measurable behavior, boundaries, ordering, and mappings to tests, but do not use tests as a replacement for explaining why an architecture was chosen. Tests preserve what the system does; documentation preserves the human decision behind it.
- Remove raw logs, stale paths, temporary names, and step-by-step investigation history when they no longer help a reader make a current decision. Condense them into evidence for the conclusion instead of deleting the conclusion with them.
- Before deleting an entire tracked document, inspect its current content, inbound links, neighboring guides, and Git history. State what unique human purpose it serves. If that purpose is plausible or ambiguous, reorganize the document and improve its navigation rather than deleting it.
- Treat line-count reduction as a diagnostic metric, not a completion target. A smaller document set is only better when users retain the context needed to operate the project safely and understand consequential design choices.
- When feedback changes a cleanup decision, update the plan, documentation index, paired-language file, and automated documentation checks together so they no longer encode the rejected assumption.

## Executable specifications

- Before removing exact defaults, bounds, mappings, ordering, or failure behavior from prose, establish the corresponding executable expectation.
- For `packages/rpremote`, treat `bundle exec rake spec` documentation output as a human-facing artifact. Organize top-level groups by feature or workflow, express conditions in context names, and describe observable outcomes in example names.
- Keep formatter output in a stable reader-oriented order and suppress incidental command or debug output from successful examples.
- Human-readable group names do not need to repeat implementation class names. Preserve code discovery with a specific `*_spec.rb` filename, an explicit require, and a nearby binding to the target class or module. Avoid vague names such as `misc_spec.rb` and groups that combine unrelated features.
- Make every description correspond to a direct expectation. Avoid descriptions such as "works correctly" that cannot identify the protected behavior.
- Documentation integrity specs should protect important relative links, language-pair structure, guide navigation, safety guidance, and release or legal files. Do not lock whole prose passages when a smaller invariant is sufficient.

### Japanese

- Use polite `です・ます` style in prose. Express required and unsafe actions explicitly with `〜してください` or `〜しないでください`.
- Use descriptive, goal-oriented headings such as `準備`, `配線`, `ビルドと実行`, `使い方`, `結果の確認`, and `トラブルシューティング`. Use `ファイル構成` when listing files and their roles.
- Use `クローン` and `R2P2シェル`.
- Do not add unnecessary spaces around English words or inline code in Japanese prose.
- Do not add a space before Japanese counters such as `8個` or `60秒`.
