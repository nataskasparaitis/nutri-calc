require "rails_helper"

RSpec.describe FavoriteItem do
  subject(:favorite_item) { build(:favorite_item) }

  it { is_expected.to be_valid }

  describe "uniqueness" do
    let!(:existing) { create(:favorite_item) }

    context "when the same user favorites the same item again" do
      subject(:favorite_item) { build(:favorite_item, user: existing.user, item: existing.item) }

      it "says it is already favorited" do
        favorite_item.valid?
        expect(favorite_item.errors[:item_id]).to include("is already favorited")
      end

      it "is still blocked by the database index when validations are skipped" do
        expect { favorite_item.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context "when another user favorites the same item" do
      subject(:favorite_item) { build(:favorite_item, item: existing.item) }

      it { is_expected.to be_valid }
    end

    context "when the same user favorites another item" do
      subject(:favorite_item) { build(:favorite_item, user: existing.user) }

      it { is_expected.to be_valid }
    end
  end

  describe "item" do
    context "when item_id points to no item" do
      before { favorite_item.item_id = 0 }

      it "says once that the item must exist" do
        favorite_item.valid?
        expect(favorite_item.errors.full_messages).to eq([ "Item must exist" ])
      end
    end

    context "when the item is soft-deleted" do
      before { favorite_item.item = create(:item, :deleted) }

      it "says the item has been deleted" do
        favorite_item.valid?
        expect(favorite_item.errors).to be_of_kind(:item, :deleted)
        expect(favorite_item.errors.full_messages).to include("Item has been deleted")
      end
    end

    context "when a saved favorite is changed to a soft-deleted item" do
      before do
        favorite_item.save!
        favorite_item.item = create(:item, :deleted)
      end

      it "says the item has been deleted" do
        favorite_item.valid?
        expect(favorite_item.errors).to be_of_kind(:item, :deleted)
      end
    end

    context "when the item is soft-deleted after it was favorited" do
      before do
        favorite_item.save!
        favorite_item.item.update!(deleted_at: Time.current)
      end

      it "does not re-check the item when nothing about it changes" do
        favorite_item.updated_at = Time.current
        expect(favorite_item).to be_valid
      end
    end
  end

  describe "user" do
    context "when it is missing" do
      before { favorite_item.user = nil }

      it "says the user must exist" do
        favorite_item.valid?
        expect(favorite_item.errors).to be_of_kind(:user, :blank)
      end
    end
  end

  describe "deleting" do
    before { favorite_item.save! }

    it "is deleted with the user's account" do
      expect { favorite_item.user.destroy! }.to change(described_class, :count).by(-1)
    end

    it "is deleted when the item is hard-deleted" do
      expect { favorite_item.item.destroy! }.to change(described_class, :count).by(-1)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:item) }
  end
end
