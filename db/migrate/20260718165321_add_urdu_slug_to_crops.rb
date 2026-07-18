class AddUrduSlugToCrops < ActiveRecord::Migration[8.0]
  def change
    add_column :crops, :urdu_slug, :string, null: false
  end
end
