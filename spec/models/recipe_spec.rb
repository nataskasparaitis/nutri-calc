require "rails_helper"

RSpec.describe Recipe do
  subject(:recipe) { build(:recipe, user: user) }

  let(:user) { create(:user) }

  it { is_expected.to be_valid }

  describe "name" do
    context "when it is missing" do
      [ nil, "", "   " ].each do |blank|
        context "when it is #{blank.inspect}" do
          before { recipe.name = blank }

          it "says it can't be blank" do
            recipe.valid?
            expect(recipe.errors).to be_of_kind(:name, :blank)
          end
        end
      end
    end

    context "when it is exactly the maximum length" do
      before { recipe.name = "a" * described_class::NAME_MAX_LENGTH }

      it { is_expected.to be_valid }

      it "can be saved" do
        expect { recipe.save! }.not_to raise_error
      end
    end

    context "when it is one character too long" do
      before { recipe.name = "a" * (described_class::NAME_MAX_LENGTH + 1) }

      it "says it is too long" do
        recipe.valid?
        expect(recipe.errors).to be_of_kind(:name, :too_long)
      end
    end

    describe "normalization" do
      it "strips spaces around it" do
        recipe.name = "  Pancakes  "
        expect(recipe.name).to eq("Pancakes")
      end

      it "removes invisible characters" do
        recipe.name = "Pan\u200Bcakes"
        expect(recipe.name).to eq("Pancakes")
      end
    end

    describe "uniqueness" do
      let!(:pancakes) { create(:recipe, user: user, name: "Pancakes") }

      context "when the same user already has a recipe with this name" do
        before { recipe.name = "Pancakes" }

        it "says it is taken" do
          recipe.valid?
          expect(recipe.errors).to be_of_kind(:name, :taken)
        end
      end

      context "when the same user has it in a different case" do
        before { recipe.name = "PANCAKES" }

        it "says it is taken" do
          recipe.valid?
          expect(recipe.errors).to be_of_kind(:name, :taken)
        end
      end

      context "when another user has a recipe with this name" do
        subject(:recipe) { build(:recipe, name: "Pancakes") }

        it { is_expected.to be_valid }

        it "can be saved" do
          expect { recipe.save! }.to change(described_class, :count).by(1)
        end
      end

      context "when the recipe with this name is soft-deleted" do
        before do
          pancakes.update!(deleted_at: Time.current)
          recipe.name = "Pancakes"
        end

        it { is_expected.to be_valid }

        it "can be saved" do
          expect { recipe.save! }.to change(described_class, :count).by(1)
        end
      end

      context "when validations are skipped" do
        before { recipe.name = "Pancakes" }

        it "is still blocked by the database index" do
          expect { recipe.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
        end
      end

      context "when several soft-deleted recipes have the same name" do
        it "allows all of them in the database" do
          pancakes.update!(deleted_at: Time.current)

          expect { create(:recipe, :deleted, user: user, name: "Pancakes") }.not_to raise_error
        end
      end
    end
  end

  describe "user" do
    context "when it is missing" do
      before { recipe.user = nil }

      it "says it must exist" do
        recipe.valid?
        expect(recipe.errors).to be_of_kind(:user, :blank)
      end
    end
  end

  describe ".active" do
    it "returns only recipes that are not soft-deleted" do
      kept = create(:recipe)
      create(:recipe, :deleted)

      expect(described_class.active).to contain_exactly(kept)
    end
  end

  describe "#items" do
    it "returns the items through recipe_items" do
      recipe.save!
      apple = create(:item)
      banana = create(:item)
      create(:recipe_item, recipe: recipe, item: apple)
      create(:recipe_item, recipe: recipe, item: banana)

      expect(recipe.items).to contain_exactly(apple, banana)
    end
  end

  describe "when it is soft-deleted" do
    let!(:recipe_item) { create(:recipe_item, recipe: create(:recipe, user: user)) }
    let!(:food_log_entry) { create(:food_log_entry, :for_recipe, user: user, recipe: recipe_item.recipe) }

    it "keeps its recipe items and food log entries" do
      expect { recipe_item.recipe.update!(deleted_at: Time.current) }
        .to change(RecipeItem, :count).by(0)
        .and change(FoodLogEntry, :count).by(0)
    end
  end

  describe "when the user deletes their account" do
    let!(:recipe_item) { create(:recipe_item, recipe: create(:recipe, user: user)) }
    let!(:food_log_entry) { create(:food_log_entry, :for_recipe, user: user, recipe: recipe_item.recipe) }

    it "deletes their recipes, recipe items and food log entries" do
      expect { user.destroy! }
        .to change(described_class, :count).by(-1)
        .and change(RecipeItem, :count).by(-1)
        .and change(FoodLogEntry, :count).by(-1)
    end

    it "keeps the items" do
      expect { user.destroy! }.not_to change(Item, :count)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:recipe_items) }
    it { is_expected.to have_many(:items).through(:recipe_items) }
    it { is_expected.to have_many(:food_log_entries) }
  end
end
