class FavoriteItem < ApplicationRecord
  belongs_to :user
  belongs_to :item

  validates :item_id, uniqueness: { scope: :user_id, message: "is already favorited" }

  validate :item_not_deleted, if: :will_save_change_to_item_id?

  private

  def item_not_deleted
    errors.add(:item, :deleted, message: "has been deleted") if item&.deleted_at?
  end
end
