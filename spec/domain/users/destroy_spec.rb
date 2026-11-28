require "rails_helper"

RSpec.describe Users::Destroy do
  let!(:user) { create(:user) }

  def destroy(id: user.id)
    described_class.for(user: user, id: id)
  end

  context "when the id is the user's own" do
    it "deletes the user" do
      expect { destroy }.to change(User, :count).by(-1)
      expect(User.exists?(user.id)).to be(false)
    end

    it "also works when the id comes as text, like from a URL" do
      expect { destroy(id: user.id.to_s) }.to change(User, :count).by(-1)
    end

    it "deletes the user's sessions, recipes, favorites and food log" do
      create(:session, user: user)
      create(:recipe, user: user)
      create(:favorite_item, user: user)
      create(:food_log_entry, user: user)

      destroy

      expect([ Session, Recipe, FavoriteItem, FoodLogEntry ].map { |model| model.where(user_id: user.id).count })
        .to eq([ 0, 0, 0, 0 ])
    end

    it "keeps the items the user created, without a creator" do
      item = create(:item, creator: user)
      destroy
      expect(item.reload.creator).to be_nil
    end
  end

  context "when the id is someone else's" do
    let!(:other_user) { create(:user) }

    it "raises AccessDenied and deletes no one" do
      expect { destroy(id: other_user.id) }.to raise_error(Users::Errors::AccessDenied)
      expect(User.count).to eq(2)
    end
  end
end
