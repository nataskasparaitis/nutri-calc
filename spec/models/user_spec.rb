require "rails_helper"

RSpec.describe User do
  subject(:user) { build(:user) }

  shared_examples "invalid character in nickname" do
    it { is_expected.not_to be_valid }

    it "explains what is allowed" do
      user.valid?
      expect(user.errors[:nickname]).to include("can only contain letters, numbers, dots, dashes and underscores")
    end
  end

  it { is_expected.to be_valid }

  describe "nickname" do
    context "when it is valid" do
      context "when its length is 3" do
        before { user.nickname = "a" * 3 }

        it { is_expected.to be_valid }
      end

      context "when its length is 20" do
        before { user.nickname = "a" * 20 }

        it { is_expected.to be_valid }
      end

      context "when it contains a letter, a number, a dot, a dash and an underscore" do
        before { user.nickname = "a1.-_" }

        it { is_expected.to be_valid }
      end

      context "when it contains uppercase letters" do
        before { user.nickname = "FoodEnjoyer" }

        it { is_expected.to be_valid }
      end
    end

    context "when it is missing" do
      [ nil, "", "   " ].each do |blank|
        context "when it is #{blank.inspect}" do
          before { user.nickname = blank }

          it "says it can't be blank" do
            user.valid?
            expect(user.errors).to be_of_kind(:nickname, :blank)
          end
        end
      end
    end

    context "when it is too short" do
      before { user.nickname = "a" * 2 }

      it "explains the minimum length" do
        user.valid?
        expect(user.errors[:nickname]).to include("is too short (minimum is 3 characters)")
      end
    end

    context "when it is too long" do
      before { user.nickname = "a" * 21 }

      it "explains the maximum length" do
        user.valid?
        expect(user.errors[:nickname]).to include("is too long (maximum is 20 characters)")
      end
    end

    context "when it contains an emoji" do
      before { user.nickname = "😀😀😀" }

      it_behaves_like "invalid character in nickname"
    end

    context "when it contains non-English letters" do
      before { user.nickname = "Ąčėüñ" }

      it_behaves_like "invalid character in nickname"
    end

    context "when it contains a Cyrillic letter that looks like a Latin one" do
      before { user.nickname = "N\u0430tas" }

      it_behaves_like "invalid character in nickname"
    end

    context "when it contains a space" do
      before { user.nickname = "food enjoyer" }

      it_behaves_like "invalid character in nickname"
    end

    context "when it contains a slash" do
      before { user.nickname = "food/enjoyer" }

      it_behaves_like "invalid character in nickname"
    end

    describe "normalization" do
      context "when it has spaces around it" do
        before { user.nickname = "  natas  " }

        it "strips them" do
          expect(user.nickname).to eq("natas")
        end
      end

      context "when it has an invisible zero-width space inside" do
        before { user.nickname = "na\u200Btas" }

        it "removes it" do
          expect(user.nickname).to eq("natas")
        end
      end

      context "when it has invalid UTF-8 bytes" do
        before { user.nickname = "na\xFFtas" }

        it "removes them" do
          expect(user.nickname).to eq("natas")
        end
      end
    end

    describe "uniqueness" do
      before { create(:user, nickname: "natas") }

      context "when the same nickname is taken" do
        before { user.nickname = "natas" }

        it "says it is taken" do
          user.valid?
          expect(user.errors).to be_of_kind(:nickname, :taken)
        end
      end

      context "when it differs only by case" do
        before { user.nickname = "NATAS" }

        it "says it is taken" do
          user.valid?
          expect(user.errors).to be_of_kind(:nickname, :taken)
        end
      end

      context "when validations are skipped" do
        before { user.nickname = "natas" }

        it "is still blocked by the database index" do
          expect { user.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
        end
      end
    end
  end

  describe "password" do
    context "when it is missing on a new user" do
      before { user.password = nil }

      it "says it can't be blank" do
        user.valid?
        expect(user.errors).to be_of_kind(:password, :blank)
      end
    end

    context "when it is 11 characters" do
      before { user.password = "a" * 11 }

      it "says it is too short" do
        user.valid?
        expect(user.errors).to be_of_kind(:password, :too_short)
      end
    end

    context "when it is exactly 12 characters" do
      before { user.password = "a" * 12 }

      it { is_expected.to be_valid }
    end

    context "when it is a passphrase with spaces and emoji" do
      before { user.password = "correct horse battery staple 😀" }

      it { is_expected.to be_valid }
    end

    context "when it is exactly 72 bytes (bcrypt's limit)" do
      before { user.password = "a" * 72 }

      it { is_expected.to be_valid }
    end

    context "when it is longer than 72 bytes" do
      before { user.password = "a" * 73 }

      it "says it is too long" do
        user.valid?
        expect(user.errors).to be_of_kind(:password, :password_too_long)
      end
    end

    it "is stored only as a hash" do
      user.save!
      expect(user.password_digest).not_to include(user.password)
    end
  end

  describe "saving" do
    it "creates a user" do
      expect { user.save! }.to change(described_class, :count).by(1)
    end

    context "when the user is invalid" do
      before { user.nickname = "a" }

      it "does not save it" do
        expect(user.save).to be(false)
        expect(described_class.count).to eq(0)
      end
    end

    context "when updating a saved user without changing the password" do
      it "does not require the password again" do
        user.save!
        reloaded = described_class.find(user.id)
        reloaded.nickname = "new-name"
        expect(reloaded).to be_valid
      end
    end
  end

  describe "#authenticate" do
    before do
      user.password = "superdupermegalong"
      user.save!
    end

    it "returns the user for the right password" do
      expect(user.authenticate("superdupermegalong")).to eq(user)
    end

    it "returns false for a wrong password" do
      expect(user.authenticate("wrong-password")).to be(false)
    end
  end

  describe "admin" do
    it "is false by default" do
      expect(user.admin).to be(false)
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:recipes) }
    it { is_expected.to have_many(:favorite_items) }
    it { is_expected.to have_many(:food_log_entries) }
    it { is_expected.to have_many(:created_items).class_name("Item").with_foreign_key(:creator_id).inverse_of(:creator) }
  end
end
