# frozen_string_literal: true

RSpec.describe "Keeping rpremote documentation navigable and safe" do
  package_root = Pathname(__dir__).join("..").expand_path
  repository_root = package_root.join("../..").expand_path
  documentation_root = repository_root.join("docs")
  package_documents = %w[README.md README.ja.md RELEASING.md].map { |name| package_root.join(name) }
  guide_documents = Dir[documentation_root.join("*.md")].map { |path| Pathname(path) }
  documents = package_documents + guide_documents

  it "keeps every relative Markdown link connected to an existing file" do
    missing = documents.flat_map do |document|
      document.read.scan(/\[[^\]]+\]\(([^)]+)\)/).filter_map do |match|
        destination = match.first.delete_prefix("<").delete_suffix(">")
        next if destination.start_with?("#") || destination.match?(/\A[a-z][a-z0-9+.-]*:/i)

        path = destination.split("#", 2).first
        target = document.dirname.join(path).cleanpath
        "#{document.relative_path_from(repository_root)} -> #{destination}" unless target.exist?
      end
    end

    expect(missing).to be_empty, "missing documentation links:\n#{missing.join("\n")}"
  end

  it "keeps an English and Japanese version with the same heading structure for every guide" do
    japanese_guides, english_guides = guide_documents.partition { |path| path.basename.to_s.end_with?(".ja.md") }

    missing_japanese = english_guides.reject do |path|
      path.sub_ext(".ja.md").exist?
    end
    missing_english = japanese_guides.reject do |path|
      path.dirname.join(path.basename.to_s.sub(".ja.md", ".md")).exist?
    end

    expect(missing_japanese + missing_english).to be_empty

    heading_levels = lambda do |path|
      in_code_block = false
      path.each_line.filter_map do |line|
        if line.start_with?("```")
          in_code_block = !in_code_block
          next
        end
        next if in_code_block

        line[/\A(#+) /, 1]&.length
      end
    end
    pairs = english_guides.map { |path| [path, path.sub_ext(".ja.md")] }
    pairs << [package_root.join("README.md"), package_root.join("README.ja.md")]

    pairs.each do |english, japanese|
      expect(heading_levels.call(japanese)).to eq(heading_levels.call(english)), english.basename.to_s
    end
  end

  it "links the documentation index to every task-oriented guide" do
    english_index = documentation_root.join("README.md").read
    japanese_index = documentation_root.join("README.ja.md").read

    %w[command config firmware mrbgems dfu].each do |guide|
      expect(english_index).to include("(#{guide}.md)")
      expect(japanese_index).to include("(#{guide}.ja.md)")
    end
  end

  it "keeps a bilingual command-option matrix for comparing workflows" do
    english = documentation_root.join("config.md").read
    japanese = documentation_root.join("config.ja.md").read

    expect(english).to include("## Options by command", "`deploy PATH`", "`--reset-on-timeout`", "`dfu status` / `dfu remove`")
    expect(japanese).to include("## コマンド別オプション", "`deploy PATH`", "`--reset-on-timeout`", "`dfu status` / `dfu remove`")
  end

  it "keeps irreversible flash, DFU, and remote deletion warnings visible" do
    english_readme = package_root.join("README.md").read
    japanese_readme = package_root.join("README.ja.md").read
    english_dfu = documentation_root.join("dfu.md").read
    japanese_dfu = documentation_root.join("dfu.ja.md").read

    expect(english_readme).to include("replaces persistent R2P2 firmware")
    expect(english_readme).to include("permanently deletes the selected remote path")
    expect(english_dfu).to include("operation is permanent")
    expect(japanese_readme).to include("永続的なR2P2ファームウェアを置き換えます")
    expect(japanese_readme).to include("指定したリモートパスを完全に削除します")
    expect(japanese_dfu).to include("削除は元に戻せず")
  end

  it "keeps release, license, and third-party notices in the published package" do
    published_files = File.read(package_root.join("rpremote.gemspec"))

    expect(published_files).to include("CHANGELOG.md")
    expect(published_files).to include("LICENSE")
    expect(published_files).to include("RELEASING.md")
    expect(published_files).to include("THIRD_PARTY_NOTICES.md")
  end
end
