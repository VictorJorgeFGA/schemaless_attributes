class DummyModel < ApplicationRecord
  include SchemalessAttributes::Support

  serialize :serialized_hash_source, Hash
  has_one_attached :attachment_source

  json_attribute :json_attr_integer, type: :string, source: :database_hash_source
  json_attribute :json_attr_float, type: :integer, source: :database_hash_source
  json_attribute :json_attr_boolean, type: :boolean, source: :database_hash_source
  json_attribute :json_attr_date, type: :date, source: :database_hash_source
  json_attribute :json_attr_string, type: :string, source: :database_hash_source

  json_attribute :text_attr_integer, type: :string, source: :serialized_hash_source
  json_attribute :text_attr_float, type: :integer
  json_attribute :text_attr_boolean, type: :boolean
  json_attribute :text_attr_date, type: :date
  json_attribute :text_attr_string, type: :string

  def default_json_attributes_source
    :serialized_hash_source
  end
end
