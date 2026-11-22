require "rails_helper"

RSpec.describe Item do
  subject(:item) { build(:item) }

  shared_examples "invalid image url" do
    it { is_expected.not_to be_valid }

    it "explains what is allowed" do
      item.valid?
      expect(item.errors[:image_url]).to include("must be an http or https URL")
    end
  end

  it { is_expected.to be_valid }

  describe "name" do
    context "when it is missing" do
      [ nil, "", "   " ].each do |blank|
        context "when it is #{blank.inspect}" do
          before { item.name = blank }

          it "says it can't be blank" do
            item.valid?
            expect(item.errors).to be_of_kind(:name, :blank)
          end
        end
      end
    end

    context "when it is exactly the maximum length" do
      before { item.name = "a" * described_class::NAME_MAX_LENGTH }

      it { is_expected.to be_valid }

      it "can be saved" do
        expect { item.save! }.not_to raise_error
      end
    end

    context "when it is one character too long" do
      before { item.name = "a" * (described_class::NAME_MAX_LENGTH + 1) }

      it "says it is too long" do
        item.valid?
        expect(item.errors).to be_of_kind(:name, :too_long)
      end
    end

    describe "normalization" do
      it "strips spaces around it" do
        item.name = "  Apple  "
        expect(item.name).to eq("Apple")
      end

      it "removes invisible characters" do
        item.name = "Ap​ple"
        expect(item.name).to eq("Apple")
      end
    end

    describe "uniqueness" do
      let!(:apple) { create(:item, name: "Apple") }

      context "when an active item has the same name" do
        before { item.name = "Apple" }

        it "says it is taken" do
          item.valid?
          expect(item.errors).to be_of_kind(:name, :taken)
        end
      end

      context "when an active item has the same name in a different case" do
        before { item.name = "APPLE" }

        it "says it is taken" do
          item.valid?
          expect(item.errors).to be_of_kind(:name, :taken)
        end
      end

      context "when the item with the same name is soft-deleted" do
        before do
          apple.update!(deleted_at: Time.current)
          item.name = "Apple"
        end

        it { is_expected.to be_valid }

        it "can be saved" do
          expect { item.save! }.to change(described_class, :count).by(1)
        end
      end

      context "when validations are skipped" do
        before { item.name = "Apple" }

        it "is still blocked by the database index" do
          expect { item.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
        end
      end

      context "when several soft-deleted items have the same name" do
        it "allows all of them in the database" do
          apple.update!(deleted_at: Time.current)

          expect { create(:item, :deleted, name: "Apple") }.not_to raise_error
        end
      end
    end
  end

  describe "image_url" do
    context "when it is missing" do
      [ nil, "", "   " ].each do |empty|
        context "when it is #{empty.inspect}" do
          before { item.image_url = empty }

          it { is_expected.to be_valid }

          it "is stored as nil" do
            expect(item.image_url).to be_nil
          end
        end
      end
    end

    context "when it has spaces around it" do
      before { item.image_url = "  https://example.com/apple.jpg  " }

      it "strips them" do
        expect(item.image_url).to eq("https://example.com/apple.jpg")
      end
    end

    %w[https://example.com/apple.jpg http://example.com/images/a.png?size=2].each do |good|
      context "when it is #{good}" do
        before { item.image_url = good }

        it { is_expected.to be_valid }
      end
    end

    [
      "not a url",
      "example.com/apple.jpg",
      "ftp://example.com/apple.jpg",
      "hello https://example.com world",
      "javascript:alert(1)//http://example.com"
    ].each do |bad|
      context "when it is #{bad.inspect}" do
        before { item.image_url = bad }

        it_behaves_like "invalid image url"
      end
    end

    context "when it is exactly the maximum length" do
      before { item.image_url = url_with_length(described_class::IMAGE_URL_MAX_LENGTH) }

      it { is_expected.to be_valid }
    end

    context "when it is one character too long" do
      before { item.image_url = url_with_length(described_class::IMAGE_URL_MAX_LENGTH + 1) }

      it "says it is too long" do
        item.valid?
        expect(item.errors).to be_of_kind(:image_url, :too_long)
      end
    end

    def url_with_length(length)
      prefix = "https://example.com/"
      prefix + ("a" * (length - prefix.length))
    end
  end

  describe "nutrients" do
    it do
      expect(item).to validate_numericality_of(:calories_per_100g)
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(described_class::MAX_CALORIES_PER_100G)
    end

    described_class::GRAMS_PER_100G.each do |nutrient|
      it do
        expect(item).to validate_numericality_of(nutrient)
          .is_greater_than_or_equal_to(0)
          .is_less_than_or_equal_to(100)
      end
    end

    context "when every nutrient is 0" do
      before do
        item.calories_per_100g = 0
        described_class::GRAMS_PER_100G.each { |nutrient| item[nutrient] = 0 }
      end

      it { is_expected.to be_valid }
    end

    context "when every nutrient is at its maximum" do
      before do
        item.calories_per_100g = described_class::MAX_CALORIES_PER_100G
        described_class::GRAMS_PER_100G.each { |nutrient| item[nutrient] = 100 }
      end

      it { is_expected.to be_valid }

      it "can be saved" do
        expect { item.save! }.not_to raise_error
      end
    end

    context "when a nutrient is missing" do
      before { item.fat_per_100g = nil }

      it "says it is not a number" do
        item.valid?
        expect(item.errors).to be_of_kind(:fat_per_100g, :not_a_number)
      end
    end

    context "when a nutrient is text" do
      before { item.calories_per_100g = "abc" }

      it "says it is not a number" do
        item.valid?
        expect(item.errors).to be_of_kind(:calories_per_100g, :not_a_number)
      end
    end

    context "when it has more than 2 decimal places" do
      before { item.salt_per_100g = 0.126 }

      it "is rounded to 2 by the database" do
        item.save!
        expect(item.reload.salt_per_100g).to eq(BigDecimal("0.13"))
      end
    end

    context "when validations are skipped" do
      before { item.calories_per_100g = 1000 }

      it "is still limited by the column type decimal(5,2)" do
        expect { item.save!(validate: false) }.to raise_error(ActiveRecord::RangeError)
      end
    end
  end

  describe ".active" do
    it "returns only items that are not soft-deleted" do
      kept = create(:item)
      create(:item, :deleted)

      expect(described_class.active).to contain_exactly(kept)
    end
  end

  describe "creator" do
    context "when the item has no creator" do
      before { item.creator = nil }

      it { is_expected.to be_valid }
    end

    context "when the creator deletes their account" do
      let(:user) { create(:user) }
      let!(:item) { create(:item, creator: user) }

      it "keeps the item" do
        expect { user.destroy! }.not_to change(described_class, :count)
      end

      it "forgets who created it" do
        user.destroy!
        expect(item.reload.creator_id).to be_nil
      end
    end
  end

  describe "#inspect" do
    it "shows salt_per_100g instead of [FILTERED]" do
      item.salt_per_100g = 0.01
      expect(item.inspect).to include("salt_per_100g: 0.1e-1")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:creator).class_name("User").optional.inverse_of(:created_items) }
    it { is_expected.to have_many(:recipe_items) }
    it { is_expected.to have_many(:favorite_items) }
    it { is_expected.to have_many(:food_log_entries) }
  end
end
