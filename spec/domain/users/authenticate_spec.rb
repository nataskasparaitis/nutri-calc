require "rails_helper"

RSpec.describe Users::Authenticate do
  let!(:user) { create(:user, email: "natas@example.com", password: "top-secret-password") }

  def authenticate(email: "natas@example.com", password: "top-secret-password")
    described_class.for(email: email, password: password)
  end

  it "returns the user when the email and password are right" do
    expect(authenticate).to eq(user)
  end

  it "ignores capital letters and spaces in the email" do
    expect(authenticate(email: "  NATAS@Example.com ")).to eq(user)
  end

  {
    "the password is wrong" => { password: "wrong-password" },
    "no user has that email" => { email: "nobody@example.com" },
    "the password is nil" => { password: nil },
    "the email is nil" => { email: nil },
    "the password is a number" => { password: 123 }
  }.each do |description, credentials|
    it "raises InvalidCredentials when #{description}" do
      expect { authenticate(**credentials) }.to raise_error(Users::Errors::InvalidCredentials)
    end
  end
end
