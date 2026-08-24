# frozen_string_literal: true

RSpec.describe Rpremote::RemotePath do
  it "recognizes and unwraps a remote path" do
    expect(described_class.remote?(":/home/app.rb")).to be(true)
    expect(described_class.unwrap(":/home/app.rb")).to eq("/home/app.rb")
  end

  it "rejects local, relative, and parent-traversing paths" do
    expect { described_class.validate("/home/app.rb") }.to raise_error(ArgumentError, /prefix/)
    expect { described_class.validate(":home/app.rb") }.to raise_error(ArgumentError, /absolute/)
    expect { described_class.validate(":/home/../etc") }.to raise_error(ArgumentError, /must not contain/)
  end
end
