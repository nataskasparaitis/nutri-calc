require "rails_helper"

RSpec.describe Sanitize::Text do
  it "strips spaces around the text" do
    expect(described_class.for("  natas  ")).to eq("natas")
  end

  it "removes invisible characters" do
    expect(described_class.for("na\u200Btas")).to eq("natas")
  end

  it "removes invalid UTF-8 bytes" do
    expect(described_class.for("na\xFFtas")).to eq("natas")
  end

  it "turns nil into an empty string" do
    expect(described_class.for(nil)).to eq("")
  end

  it "squeezes repeated spaces inside the text into one" do
    expect(described_class.for("food    enjoyer")).to eq("food enjoyer")
  end

  it "joins a letter and a separate accent mark into one character" do
    expect(described_class.for("e\u0301")).to eq("\u00E9")
  end

  it "keeps the joiner that glues emoji together" do
    expect(described_class.for("\u{1F468}\u200D\u{1F469}")).to eq("\u{1F468}\u200D\u{1F469}")
  end
end
