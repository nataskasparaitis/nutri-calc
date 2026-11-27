require "rails_helper"

RSpec.describe Users::Register do
  subject(:register) { described_class.for(email: email, nickname: "natas", password: password) }

  let(:email) { "natas@example.com" }
  let(:password) { "top-secret-password" }

  it "creates the user and returns it" do
    expect { register }.to change(User, :count).by(1)
    expect(register).to be_persisted.and have_attributes(email: "natas@example.com", nickname: "natas", admin: false)
  end

  it "saves a password that works" do
    expect(register.authenticate("top-secret-password")).to eq(register)
  end

  context "when the password is a number" do
    let(:password) { 123_456_789_012 }

    it "saves it as text" do
      expect(register.authenticate("123456789012")).to eq(register)
    end
  end

  context "when the email is already taken" do
    before { create(:user, email: "natas@example.com") }

    it "raises a validation error" do
      expect { register }.to raise_error(ActiveRecord::RecordInvalid, /Email has already been taken/)
    end
  end

  context "when the email is nil" do
    let(:email) { nil }

    it "raises a validation error instead of crashing" do
      expect { register }.to raise_error(ActiveRecord::RecordInvalid, /Email can't be blank/)
    end
  end
end
