require "rails_helper"

RSpec.describe Users::Serialize do
  subject(:result) { described_class.for(user: user) }

  let(:user) { build(:user, id: 7, email: "natas@example.com", nickname: "natas", admin: false) }

  it "returns only the public fields" do
    expect(result).to eq(id: 7, email: "natas@example.com", nickname: "natas", admin: false)
  end

  context "when the user is an admin" do
    let(:user) { build(:user, :admin) }

    it "says so" do
      expect(result[:admin]).to be(true)
    end
  end
end
