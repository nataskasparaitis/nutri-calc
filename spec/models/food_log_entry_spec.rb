require "rails_helper"

RSpec.describe FoodLogEntry do
  subject(:entry) { build(:food_log_entry) }

  it { is_expected.to be_valid }

  context "when it is for a recipe" do
    subject(:entry) { build(:food_log_entry, :for_recipe) }

    it { is_expected.to be_valid }
  end

  describe "grams" do
    it do
      expect(entry).to validate_numericality_of(:grams)
        .is_greater_than(0)
        .is_less_than_or_equal_to(described_class::MAX_GRAMS)
    end

    context "when it is missing" do
      before { entry.grams = nil }

      it "says only that it is not a number" do
        entry.valid?
        expect(entry.errors[:grams]).to eq([ "is not a number" ])
      end
    end

    context "when it is the maximum" do
      before { entry.grams = described_class::MAX_GRAMS }

      it "can be saved" do
        expect { entry.save! }.not_to raise_error
      end
    end

    context "when it has decimals" do
      before { entry.grams = 12.5 }

      it "keeps them" do
        entry.save!
        expect(entry.reload.grams).to eq(BigDecimal("12.5"))
      end
    end

    context "when validations are skipped" do
      before { entry.grams = 100_000 }

      it "is still limited by the column type decimal(7,2)" do
        expect { entry.save!(validate: false) }.to raise_error(ActiveRecord::RangeError)
      end
    end
  end

  describe "eaten_on" do
    context "when it is missing" do
      before { entry.eaten_on = nil }

      it "says it can't be blank" do
        entry.valid?
        expect(entry.errors).to be_of_kind(:eaten_on, :blank)
      end

      it "is still required by the database when validations are skipped" do
        expect { entry.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
      end
    end

    context "when it is in the past" do
      before { entry.eaten_on = Date.new(2020, 1, 1) }

      it { is_expected.to be_valid }
    end

    context "when it is in the future" do
      before { entry.eaten_on = Date.current + 7 }

      it { is_expected.to be_valid }
    end
  end

  describe "item or recipe" do
    context "when it has neither" do
      before { entry.item = nil }

      it "asks to choose one" do
        entry.valid?
        expect(entry.errors).to be_of_kind(:base, :item_or_recipe_missing)
        expect(entry.errors.full_messages).to include("Choose an item or a recipe")
      end
    end

    context "when it has both" do
      before { entry.recipe = create(:recipe, user: entry.user) }

      it "says to choose only one" do
        entry.valid?
        expect(entry.errors).to be_of_kind(:base, :item_and_recipe)
      end
    end

    context "when item_id points to no item" do
      before { entry.item_id = 0 }

      it "says the item must exist" do
        entry.valid?
        expect(entry.errors).to be_of_kind(:item, :blank)
        expect(entry.errors.full_messages).to include("Item must exist")
      end
    end

    context "when recipe_id points to no recipe" do
      before do
        entry.item = nil
        entry.recipe_id = 0
      end

      it "says the recipe must exist" do
        entry.valid?
        expect(entry.errors).to be_of_kind(:recipe, :blank)
        expect(entry.errors.full_messages).to include("Recipe must exist")
      end
    end

    context "when a wrong id is sent together with a valid choice" do
      before do
        entry.item_id = 0
        entry.recipe = create(:recipe, user: entry.user)
      end

      it "is rejected by the validation instead of the foreign key" do
        expect { entry.save! }.to raise_error(ActiveRecord::RecordInvalid, /Item must exist/)
      end
    end
  end

  describe "recipe owner" do
    let(:user) { create(:user) }

    context "when the recipe belongs to the same user" do
      subject(:entry) { build(:food_log_entry, :for_recipe, user: user, recipe: create(:recipe, user: user)) }

      it { is_expected.to be_valid }
    end

    context "when the recipe belongs to another user" do
      subject(:entry) { build(:food_log_entry, :for_recipe, user: user, recipe: create(:recipe)) }

      it "says it must be one of the user's recipes" do
        entry.valid?
        expect(entry.errors).to be_of_kind(:recipe, :not_owned)
      end
    end
  end

  describe "soft-deleted item or recipe" do
    context "when logging a soft-deleted item" do
      before { entry.item = create(:item, :deleted) }

      it "says the item has been deleted" do
        entry.valid?
        expect(entry.errors).to be_of_kind(:item, :deleted)
      end
    end

    context "when logging a soft-deleted recipe" do
      before do
        entry.item = nil
        entry.recipe = create(:recipe, :deleted, user: entry.user)
      end

      it "says the recipe has been deleted" do
        entry.valid?
        expect(entry.errors).to be_of_kind(:recipe, :deleted)
      end
    end

    context "when the item is soft-deleted after it was logged" do
      before do
        entry.save!
        entry.item.update!(deleted_at: Time.current)
      end

      it "keeps the entry" do
        expect(described_class.exists?(entry.id)).to be(true)
      end

      it "can still change its grams" do
        entry.grams = 250
        expect(entry).to be_valid
      end
    end

    context "when the recipe is soft-deleted after it was logged" do
      subject(:entry) { build(:food_log_entry, :for_recipe) }

      before do
        entry.save!
        entry.recipe.update!(deleted_at: Time.current)
      end

      it "keeps the entry" do
        expect(described_class.exists?(entry.id)).to be(true)
      end

      it "can still change its grams" do
        entry.grams = 250
        expect(entry).to be_valid
      end
    end

    context "when a saved entry is changed to a soft-deleted item" do
      before do
        entry.save!
        entry.item = create(:item, :deleted)
      end

      it "says the item has been deleted" do
        entry.valid?
        expect(entry.errors).to be_of_kind(:item, :deleted)
      end
    end
  end

  describe "deleting" do
    it "is deleted with the user's account" do
      entry.save!
      expect { entry.user.destroy! }.to change(described_class, :count).by(-1)
    end

    it "blocks hard-deleting an item that has been logged" do
      entry.save!
      expect { entry.item.destroy! }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:item).optional }
    it { is_expected.to belong_to(:recipe).optional }
  end
end
