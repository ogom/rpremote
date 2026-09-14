# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "Goryokaku documentation" do
  let(:documents) do
    Dir[File.join(GORYOKAKU_ROOT, "*.md")] + Dir[File.join(GORYOKAKU_ROOT, "docs", "**", "*.md")]
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

  it "keeps every Japanese and English project guide paired" do
    guides = Dir[File.join(GORYOKAKU_ROOT, "docs", "*.md")]
    missing = guides.filter_map do |path|
      counterpart = path.end_with?(".ja.md") ? path.sub(/\.ja\.md\z/, ".md") : path.sub(/\.md\z/, ".ja.md")
      [path, counterpart] unless File.exist?(counterpart)
    end

    expect(missing).to be_empty
  end

  it "keeps safety, operation, structure, and performance guidance reachable from both READMEs" do
    japanese = File.read(File.join(GORYOKAKU_ROOT, "README.ja.md"))
    english = File.read(File.join(GORYOKAKU_ROOT, "README.md"))

    %w[hardware modes illuminations led_layout structure development].each do |name|
      expect(japanese).to include("docs/#{name}.ja.md")
      expect(english).to include("docs/#{name}.md")
    end
    expect(japanese).to include("外部5 V電源")
    expect(english).to include("external 5 V supply")
    expect(japanese).to include("rpremote mrbgems lock")
    expect(english).to include("rpremote mrbgems lock")
  end
end
