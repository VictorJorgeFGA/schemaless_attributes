# frozen_string_literal: true

class CreateDummyModels < ActiveRecord::Migration[6.0]
  def change
    create_table :dummy_models do |t|
      t.json :database_hash_source, default: {}
      t.text :serialized_hash_source
      t.string :fallback_source, default: ''

      t.timestamps
    end
  end
end
