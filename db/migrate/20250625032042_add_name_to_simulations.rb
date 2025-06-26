class AddNameToSimulations < ActiveRecord::Migration[8.0]
  def change
    add_column :simulations, :name, :string
  end
end
