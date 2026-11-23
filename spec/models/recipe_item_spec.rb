require "rails_helper"

RSpec.describe RecipeItem do
  subject(:recipe_item) { build(:recipe_item) }

  it { is_expected.to be_valid }

  describe "grams" do
    it do
      expect(recipe_item).to validate_numericality_of(:grams)
        .is_greater_than(0)
        .is_less_than_or_equal_to(described_class::MAX_GRAMS)
    end

    context "when it is missing" do
      before { recipe_item.grams = nil }

      it "says only that it is not a number" do
        recipe_item.valid?
        expect(recipe_item.errors[:grams]).to eq([ "is not a number" ])
      end
    end

    context "when it is the smallest amount the column can store" do
      before { recipe_item.grams = 0.01 }

      it { is_expected.to be_valid }
    end

    context "when it rounds to 0 in the column" do
      before { recipe_item.grams = 0.004 }

      it "says it must be greater than 0" do
        recipe_item.valid?
        expect(recipe_item.errors).to be_of_kind(:grams, :greater_than)
      end
    end

    context "when it is the maximum" do
      before { recipe_item.grams = described_class::MAX_GRAMS }

      it "can be saved" do
        expect { recipe_item.save! }.not_to raise_error
      end
    end

    context "when it has decimals" do
      before { recipe_item.grams = 0.5 }

      it "keeps them" do
        recipe_item.save!
        expect(recipe_item.reload.grams).to eq(BigDecimal("0.5"))
      end
    end

    context "when validations are skipped" do
      before { recipe_item.grams = 100_000 }

      it "is still limited by the column type decimal(7,2)" do
        expect { recipe_item.save!(validate: false) }.to raise_error(ActiveRecord::RangeError)
      end
    end
  end

  describe "the same item twice in one recipe" do
    let!(:existing) { create(:recipe_item) }

    context "when it is the same recipe" do
      subject(:recipe_item) { build(:recipe_item, recipe: existing.recipe, item: existing.item) }

      it "says the item is already in this recipe" do
        recipe_item.valid?
        expect(recipe_item.errors[:item_id]).to include("is already in this recipe")
      end

      it "is still blocked by the database index when validations are skipped" do
        expect { recipe_item.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context "when it is another recipe" do
      subject(:recipe_item) { build(:recipe_item, item: existing.item) }

      it { is_expected.to be_valid }
    end
  end

  describe "missing item or recipe" do
    context "when item_id points to no item" do
      before { recipe_item.item_id = 0 }

      it "says the item must exist" do
        recipe_item.valid?
        expect(recipe_item.errors).to be_of_kind(:item, :blank)
      end
    end

    context "when recipe_id points to no recipe" do
      before { recipe_item.recipe_id = 0 }

      it "says the recipe must exist" do
        recipe_item.valid?
        expect(recipe_item.errors).to be_of_kind(:recipe, :blank)
      end
    end
  end

  describe "soft-deleted item or recipe" do
    context "when adding a soft-deleted item" do
      before { recipe_item.item = create(:item, :deleted) }

      it "says the item has been deleted" do
        recipe_item.valid?
        expect(recipe_item.errors).to be_of_kind(:item, :deleted)
      end
    end

    context "when adding to a soft-deleted recipe" do
      before { recipe_item.recipe = create(:recipe, :deleted) }

      it "says the recipe has been deleted" do
        recipe_item.valid?
        expect(recipe_item.errors).to be_of_kind(:recipe, :deleted)
      end
    end

    context "when the item is soft-deleted after it was added" do
      before do
        recipe_item.save!
        recipe_item.item.update!(deleted_at: Time.current)
      end

      it "keeps the recipe item" do
        expect(described_class.exists?(recipe_item.id)).to be(true)
      end

      it "can still change its grams" do
        recipe_item.grams = 250
        expect(recipe_item).to be_valid
      end
    end

    context "when the recipe is soft-deleted after the item was added" do
      before do
        recipe_item.save!
        recipe_item.recipe.update!(deleted_at: Time.current)
      end

      it "keeps the recipe item" do
        expect(described_class.exists?(recipe_item.id)).to be(true)
      end

      it "can still change its grams" do
        recipe_item.grams = 250
        expect(recipe_item).to be_valid
      end
    end
  end

  describe "changing a saved recipe item" do
    before { recipe_item.save! }

    context "when it is moved to a soft-deleted item" do
      before { recipe_item.item = create(:item, :deleted) }

      it "says the item has been deleted" do
        recipe_item.valid?
        expect(recipe_item.errors).to be_of_kind(:item, :deleted)
      end
    end

    context "when it is moved to an item already in the recipe" do
      before do
        other = create(:recipe_item, recipe: recipe_item.recipe)
        recipe_item.item = other.item
      end

      it "says the item is already in this recipe" do
        recipe_item.valid?
        expect(recipe_item.errors[:item_id]).to include("is already in this recipe")
      end
    end
  end

  describe "deleting" do
    before { recipe_item.save! }

    it "is deleted with the user's account" do
      expect { recipe_item.recipe.user.destroy! }.to change(described_class, :count).by(-1)
    end

    it "blocks hard-deleting an item that is used in a recipe" do
      expect { recipe_item.item.destroy! }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:recipe) }
    it { is_expected.to belong_to(:item) }
  end
end
