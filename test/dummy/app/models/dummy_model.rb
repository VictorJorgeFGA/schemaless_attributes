# frozen_string_literal: true

class DummyModel < ApplicationRecord
  include SchemalessAttributes::Support

  serialize :serialized_hash_source, Hash

  has_one_attached :attachment_source

  json_attribute :json_attr_integer, type: :string
  json_attribute :json_attr_float, type: :integer
  json_attribute :json_attr_boolean, type: :boolean
  json_attribute :json_attr_date, type: :date
  json_attribute :json_attr_string, type: :string

  def json_attributes_source
    :serialized_hash_source
  end
end
