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

  it "documents every illumination key with a title and visible effect in both languages" do
    registered_keys = Daisenkofun::Illumination::Setlist::PATTERNS.map do |entry|
      entry[Daisenkofun::Illumination::Setlist::KEY].to_s
    end

    %w[illuminations.ja.md illuminations.md].each do |filename|
      text = File.read(File.join(DAISENKOFUN_ROOT, "docs", filename))
      rows = text.scan(/^\|\s*`([^`]+)`\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|$/).to_h do |key, title, effect|
        [key, [title.strip, effect.strip]]
      end

      expect(rows.keys).to include(*registered_keys)
      expect(registered_keys.map { |key| rows.fetch(key) }.flatten).to all(satisfy { |value| !value.empty? })
    end
  end

  it "keeps biometric interpretation, persistent startup, and runtime logs available to operators" do
    japanese_music = File.read(File.join(DAISENKOFUN_ROOT, "docs", "biometric_pwm_music.ja.md"))
    english_music = File.read(File.join(DAISENKOFUN_ROOT, "docs", "biometric_pwm_music.md"))
    japanese_workflow = File.read(File.join(DAISENKOFUN_ROOT, "docs", "development.ja.md"))
    english_workflow = File.read(File.join(DAISENKOFUN_ROOT, "docs", "development.md"))

    expect(japanese_music).to include("拍間隔と音高", "SpO₂と音の上下", "脈波の幅と音色", "event=verification")
    expect(english_music).to include("Beat interval and pitch", "SpO₂ and pitch direction", "Pulse width and timbre", "event=verification")
    expect(japanese_workflow).to include("再起動後の自動実行", "rpremote dfu app", "## ログの読み方")
    expect(english_workflow).to include("startup after reset", "rpremote dfu app", "## Read the log")
  end
end
