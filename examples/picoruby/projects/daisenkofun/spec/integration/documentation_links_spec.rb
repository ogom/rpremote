# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "Daisen Kofun documentation" do
  let(:documents) do
    Dir[File.join(DAISENKOFUN_ROOT, "*.md")] + Dir[File.join(DAISENKOFUN_ROOT, "docs", "**", "*.md")]
  end

  it "contains no broken relative Markdown links" do
    broken = documents.flat_map do |document|
      File.read(document).scan(/\[[^\]]+\]\(([^)]+)\)/).filter_map do |match|
        target = match.first.sub(/\A</, "").sub(/>\z/, "").split("#", 2).first
        next if target.empty? || target.match?(/\A(?:https?:|mailto:)/)

        resolved = File.expand_path(target, File.dirname(document))
        [document, target] unless File.exist?(resolved)
      end
    end

    expect(broken).to be_empty
  end

  it "keeps Japanese and English guides paired" do
    english_guides = Dir[File.join(DAISENKOFUN_ROOT, "docs", "*.md")].reject { |path| path.end_with?(".ja.md") }

    missing = english_guides.reject { |path| File.exist?(path.sub(/\.md\z/, ".ja.md")) }
    expect(missing).to be_empty
  end

  it "keeps the human-facing mrbgem design decision in the project guide" do
    japanese = File.read(File.join(DAISENKOFUN_ROOT, "docs", "mrbgem_migration.ja.md"))
    english = File.read(File.join(DAISENKOFUN_ROOT, "docs", "mrbgem_migration.md"))

    expect(japanese).to include("mrbgemを使う理由", "トレードオフ")
    expect(english).to include("uses mrbgems", "Tradeoffs")
    expect(File.read(File.join(DAISENKOFUN_ROOT, "README.ja.md"))).to include("docs/mrbgem_migration.ja.md")
    expect(File.read(File.join(DAISENKOFUN_ROOT, "README.md"))).to include("docs/mrbgem_migration.md")
  end

  it "keeps safety guidance discoverable in both languages" do
    expect(File.read(File.join(DAISENKOFUN_ROOT, "docs", "hardware.ja.md"))).to include("安全上の注意")
    expect(File.read(File.join(DAISENKOFUN_ROOT, "docs", "hardware.md"))).to include("Safety")
    expect(File.read(File.join(DAISENKOFUN_ROOT, "README.ja.md"))).to include("医療機器ではありません")
    expect(File.read(File.join(DAISENKOFUN_ROOT, "README.md"))).to include("not a medical device")
  end
end
