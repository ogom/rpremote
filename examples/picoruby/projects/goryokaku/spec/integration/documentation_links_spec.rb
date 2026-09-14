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

  it "documents every illumination key with a title and visible effect in both languages" do
    registered_keys = Goryokaku::Illumination::Setlist::PATTERNS.map do |entry|
      entry[Goryokaku::Illumination::Setlist::KEY].to_s
    end

    %w[illuminations.ja.md illuminations.md].each do |filename|
      text = File.read(File.join(GORYOKAKU_ROOT, "docs", filename))
      rows = text.scan(/^\|\s*`([^`]+)`\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|$/).to_h do |key, title, effect|
        [key, [title.strip, effect.strip]]
      end

      expect(rows.keys).to include(*registered_keys)
      expect(registered_keys.map { |key| rows.fetch(key) }.flatten).to all(satisfy { |value| !value.empty? })
    end
  end

  it "keeps the operator-facing LED map and physical checks in both languages" do
    japanese = File.read(File.join(GORYOKAKU_ROOT, "docs", "led_layout.ja.md"))
    english = File.read(File.join(GORYOKAKU_ROOT, "docs", "led_layout.md"))

    expect(japanese).to include(
      "## ゾーン", "## 星形本体", "## 左右の並列走査", "## タンバリン演奏時の向き",
      "## 半月堡", "## 外周", "## 演出で配置を確認する", "`379`→`190`"
    )
    expect(english).to include(
      "## Zones", "## Star body", "## Left and right parallel scans", "## Tambourine orientation",
      "## Ravelin", "## Outer ring", "## Check the layout with effects", "`379`→`190`"
    )
  end

  it "keeps tambourine tuning, persistent startup, and runtime logs available to operators" do
    japanese_modes = File.read(File.join(GORYOKAKU_ROOT, "docs", "modes.ja.md"))
    english_modes = File.read(File.join(GORYOKAKU_ROOT, "docs", "modes.md"))
    japanese_workflow = File.read(File.join(GORYOKAKU_ROOT, "docs", "development.ja.md"))
    english_workflow = File.read(File.join(GORYOKAKU_ROOT, "docs", "development.md"))

    expect(japanese_modes).to include("姿勢とタンバリン感度", "shake_window_ms", "strike_release_threshold")
    expect(english_modes).to include("Orientation and tambourine sensitivity", "shake_window_ms", "strike_release_threshold")
    expect(japanese_workflow).to include("再起動後の自動実行", "rpremote dfu app", "## ログの読み方")
    expect(english_workflow).to include("startup after reset", "rpremote dfu app", "## Read the log")
  end
end
