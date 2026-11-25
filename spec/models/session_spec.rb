require "rails_helper"

RSpec.describe Session do
  subject(:session) { build(:session) }

  it { is_expected.to be_valid }

  describe "user_agent" do
    context "when it is exactly the maximum length" do
      before { session.user_agent = "a" * described_class::USER_AGENT_MAX_LENGTH }

      it "keeps all of it" do
        expect(session.user_agent.length).to eq(described_class::USER_AGENT_MAX_LENGTH)
      end
    end

    context "when it is longer than the maximum length" do
      before { session.user_agent = "a" * 300 }

      it "is cut to the maximum length" do
        expect(session.user_agent).to eq("a" * described_class::USER_AGENT_MAX_LENGTH)
      end

      it "can be saved" do
        expect { session.save! }.not_to raise_error
      end
    end

    context "when it is long and made of multi-byte characters" do
      before { session.user_agent = "😀" * 300 }

      it "is cut by characters, not bytes, and can be saved" do
        session.save!
        expect(session.reload.user_agent).to eq("😀" * described_class::USER_AGENT_MAX_LENGTH)
      end
    end

    context "when it is missing" do
      before { session.user_agent = nil }

      it { is_expected.to be_valid }

      it "stays nil" do
        session.save!
        expect(session.reload.user_agent).to be_nil
      end
    end
  end

  describe "ip_address" do
    context "when it is the longest possible IPv6 address" do
      before { session.ip_address = "ffff:ffff:ffff:ffff:ffff:ffff:255.255.255.255" }

      it "can be saved" do
        session.save!
        expect(session.reload.ip_address).to eq("ffff:ffff:ffff:ffff:ffff:ffff:255.255.255.255")
      end
    end

    context "when it is missing" do
      before { session.ip_address = nil }

      it { is_expected.to be_valid }
    end
  end

  describe "user" do
    context "when it is missing" do
      before { session.user = nil }

      it "says the user must exist" do
        session.valid?
        expect(session.errors).to be_of_kind(:user, :blank)
      end

      it "is still required by the database when validations are skipped" do
        expect { session.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
      end
    end
  end

  describe "deleting" do
    before { session.save! }

    it "is deleted with the user's account" do
      expect { session.user.destroy! }.to change(described_class, :count).by(-1)
    end

    it "keeps the user when the session is deleted" do
      expect { session.destroy! }.not_to change(User, :count)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end
end
