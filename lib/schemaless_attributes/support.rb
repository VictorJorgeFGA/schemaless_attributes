# frozen_string_literal: true

require 'schemaless_attributes/type'
require 'active_support/concern'
require 'active_storage'

module SchemalessAttributes
  # This concern add the ability to define json_attributes and attachment_attributes inside of your model.
  # It saves the registered attributes and handle all the logic behind storing and converting data.
  #
  module Support
    extend ActiveSupport::Concern

    # Defines the default hash for json based attributes. It is recommended to be a jsonb/json column on database
    # It is going to be used whenever source is not explicitly provided for a json_attribute
    #
    def default_json_attributes_source
      raise 'Need to be implemented!'
    end

    class_methods do
      def registered_schemaless_attributes
        @registered_schemaless_attributes ||= []
      end

      # Define a new json based attribute with name `name` and type `type`. Source can be provided
      # but it can also be omitted in case your model defines a default_json_attributes_source
      # hash object.
      #
      # Available types are: float, decimal, boolean, date, datetime, time, string, text and integer.
      #
      # @param [String] name Attribute name
      # @param [Symbol] type Attribute type
      # @param [Symbol] source Attribute json source name, i.e. hash where attribute is going to be stored
      #
      # @raise [StandardError] if tries to create an attribute with taken name
      # @raise [StandardError] if tries to create an attribute with invalid data type
      #
      # @return [true] if succeed
      #
      def json_attribute(name, type:, source: nil)
        type = type.to_sym
        name = name.to_s
        source = source.to_sym if source

        check_and_register_attribute(name, type)

        define_method name do
          target_json = source.present? ? send(source) : default_json_attributes_source
          SchemalessAttributes::Type.handler(type).deserialize(target_json[name])
        end

        define_method "#{name}=" do |value|
          target_json = source.present? ? send(source) : default_json_attributes_source
          target_json[name] = SchemalessAttributes::Type.handler(type).cast(value)
        end

        true
      end

      # Define multiple json attributes at once. Attributes configuration must be especified in a hash as
      # following:
      #
      # json_attributes attribute_one: {type: :string, source: :json_source}
      #
      # @param [Hash] attribute The attribute information. Should be a hash where key is attribute name
      # @option attribute [Symbol] type Attribute type
      # @option attribute [Symbol] source Attribute source
      # @return [true] if succeed
      def json_attributes(**attributes)
        attributes.each do |name, options|
          raise "Expected options to be a hash in json attribute definition \"#{name}\"!" unless options.is_a?(Hash)

          json_attribute(name, **options)
        end

        true
      end

      # Create an attachment attribute with `name` coming from an attachment source `source`. You can also specify
      # a fallback attribute to write and read from a different location. It is expected attachment to have txt
      # content.
      #
      # @param [String] name Attribute name
      # @param [Symbol] source Source attachment name
      # @param [lambda] fallback_write A lambda function to determine if fallback source should be used to write
      #   instead of attachment
      # @param [lambda] fallback_read A lambda function to determine if fallback source should be used to read instead
      #   of attachment
      #
      # @raise [StandardError] if tries to create an attribute with taken name
      #
      # @return [true] if succeed
      def attachment_attribute(name, source:, fallback_source: nil, fallback_write: proc { false }, fallback_read: proc { false })
        name = name.to_s
        fallback_source = fallback_source.to_sym if fallback_source

        check_and_register_attribute(name, :text)

        define_method name do
          return send(fallback_source) if fallback_read.call(self)

          return unless send(source).attached?

          send(source).download.force_encoding('UTF-8')
        end

        define_method "#{name}=" do |value|
          return send("#{fallback_source}=", value) if fallback_write.call(self)

          blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(value), filename: "#{name}.txt")
          send("#{source}=", blob)
        end

        true
      end

      # Create multiple attachment attributes at once. Options should be given inside a hash as following:
      #
      # has_one_attached :attachment_source
      # attachment_attributes attachment_attribute_one:
      #                                             {
      #                                               source: :attachment_source,
      #                                               fallback_source: :text_attribute
      #                                             },
      #                       attachment_attribute_two:
      #                                             {
      #                                               source: :attachment_source,
      #                                               fallback_source: :text_attribute
      #                                             }
      #
      # @param [Hash] attribute The attribute information. Should be a hash where key is attribute name
      # @option attribute [Symbol] source Attachment source for the attribute
      # @option attribute [Symbol] fallback_source Fallback source for attribute
      # @option attribute [lambda] fallback_write A lambda function to determine if fallback source should be
      #   used to write instead of attachment
      # @option attribute [lambda] fallback_read A lambda function to determine if fallback source should be
      #   used to read instead of attachment
      #
      # @return [true] if succeed
      #
      def attachment_attributes(**attributes)
        attributes.each do |name, options|
          raise "Expected options to be a hash in json attribute definition \"#{name}\"!" unless options.is_a?(Hash)

          attachment_attribute(name, **options)
        end

        true
      end

      def check_and_register_attribute(name, type)
        check_if_attribute_name_is_ambiguos(name)
        check_if_attribute_type_is_valid(name, type)
        register_attribute(name)
      end

      def check_if_attribute_name_is_ambiguos(attribute_name)
        return unless instance_methods.include?(attribute_name.to_sym) || instance_methods.include?("#{attribute_name}=".to_sym)

        raise "Declaration of schemaless attribute with ambiguous name \"#{attribute_name}\" on #{self.class}!"
      end

      def check_if_attribute_type_is_valid(attribute_name, type)
        return if SchemalessAttributes::Type.type_available?(type)

        raise "Schemaless attribute \"#{attribute_name}\" has unsupported type: #{type}!"
      end

      def register_attribute(attribute_name)
        registered_schemaless_attributes << attribute_name.to_s
      end
    end
  end
end
