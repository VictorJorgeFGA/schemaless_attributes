# frozen_string_literal: true

class DummyModel < ApplicationRecord
  include SchemalessAttributes::Support

  serialize :serialized_hash_source, Hash

  has_one_attached :attachment_source

  json_attributes json_attr_integer: { type: :integer },
                  json_attr_float: { type: :float },
                  json_attr_boolean: { type: :boolean }

  json_attribute :json_attr_date, type: :date
  json_attribute :json_attr_string, type: :string
  json_attribute :json_attr_text, type: :text
  json_attribute :json_attr_time, type: :time
  json_attribute :json_attr_datetime, type: :datetime
  json_attribute :json_attr_decimal, type: :decimal

  json_attributes serialized_hash_attr_integer: { type: :integer, source: :serialized_hash_source },
                  serialized_hash_attr_float: { type: :float, source: :serialized_hash_source },
                  serialized_hash_attr_boolean: { type: :boolean, source: :serialized_hash_source }

  json_attribute :serialized_hash_attr_string, type: :string, source: :serialized_hash_source
  json_attribute :serialized_hash_attr_datetime, type: :datetime, source: :serialized_hash_source
  json_attribute :serialized_hash_attr_text, type: :text, source: :serialized_hash_source
  json_attribute :serialized_hash_attr_time, type: :time, source: :serialized_hash_source

  attachment_attributes(
    attachment_attr_text: {
      source: :attachment_source,
      fallback_source: :fallback_source,
      fallback_read: ->(myself) { myself.use_fallback_read },
      fallback_write: ->(myself) { myself.use_fallback_write }
    }
  )

  attr_accessor :use_fallback_read, :use_fallback_write

  after_initialize do
    @use_fallback_read = false
    @use_fallback_write = false
  end

  def default_json_attributes_source
    database_hash_source
  end
end
