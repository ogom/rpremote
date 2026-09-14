# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "Oximeter documentation" do
  let(:documents) do
    Dir[File.join(OXIMETER_ROOT, "*.md")] + Dir[File.join(OXIMETER_ROOT, "docs", "**", "*.md")]
  end

  it "contains no broken relative Markdown links" do
    broken = documents.flat_map do |document|
      File.read(document).scan(/\[[^\]]+\]\(([^)]+)\)/).filter_map do |match|
        target = match.first.sub(/\A</, "").sub(/>\z/, "").split("#", 2).first
        next if target.empty? || target.match?(/\A(?:https?:|mailto:)/)

        [document, target] unless File.exist?(File.expand_path(target, File.dirname(document)))
      end
    end

    expect(broken).to be_empty
  end

  it "keeps every Japanese and English guide paired" do
    guides = Dir[File.join(OXIMETER_ROOT, "docs", "*.md")]
    missing = guides.filter_map do |path|
      counterpart = path.end_with?(".ja.md") ? path.sub(/\.ja\.md\z/, ".md") : path.sub(/\.md\z/, ".ja.md")
      [path, counterpart] unless File.exist?(counterpart)
    end

    expect(missing).to be_empty
  end

  it "keeps medical limitations and electrical safety visible in both READMEs" do
    japanese = File.read(File.join(OXIMETER_ROOT, "README.ja.md"))
    english = File.read(File.join(OXIMETER_ROOT, "README.md"))

    expect(japanese).to include("医療機器ではありません", "GPIOからLEDへ給電しない")
    expect(english).to include("not a medical device", "Do not power LEDs from a GPIO")
  end

  it "keeps the Pub/Sub and tick design rationale discoverable" do
    japanese = File.read(File.join(OXIMETER_ROOT, "README.ja.md"))
    english = File.read(File.join(OXIMETER_ROOT, "README.md"))

    expect(japanese).to include("docs/pub_sub.ja.md", "docs/tick.ja.md")
    expect(english).to include("docs/pub_sub.md", "docs/tick.md")
  end
end
