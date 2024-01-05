# frozen_string_literal: true

require 'schemaless_attributes/type'
require 'active_support/concern'
require 'active_storage'

module SchemalessAttributes
  # This concern add the ability to define json_attributes and attachment_attributes inside of your model.
  # It saves the registered attributes and handle all the logic behind storing and converting data.
  #
  class Support
    include ActiveSupport::Concern

    @registered_schemaless_attributes = []

    class << self
      def registered_schemaless_attributes
        @registered_schemaless_attributes.dup
      end

      def json_attribute(name, type:, source: default_json_attributes_source)
        type = type.to_sym
        name = name.to_s

        check_and_register_attribute!(name, type, source, expected_source_type: Hash)

        define_method name do
          SchemalessAttributes::Type.handler(type).deserialize(source[name])
        end

        define_method "#{name}=" do |value|
          source[name] = SchemalessAttributes::Type.handler(type).cast(value)
        end
      end

      def attachment_attribute(name, source:, fallback_write: proc { false }, fallback_read: proc { false })
        name = name.to_s

        check_and_register_attribute!(name, :text, source, expected_source_type: ActiveStorage::Attached)

        define_method name do
          return super if fallback_read.call(self)

          return unless send(source).attached?

          send(source).download.force_encoding('UTF-8')
        end

        define_method "#{name}=" do |value|
          return super(value) if fallback_write.call(self)

          # TODO: verify if shadowing filename is happening
          blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(value), filename: "#{name}.txt")
          send("#{source}=", blob)
        end
      end

      private_class_method def check_and_register_attribute!(name, type, source, expected_source_type:)
        check_if_attribute_name_is_ambiguos!(name)
        check_if_source_exists_and_has_correct_type!(name, source, expected_type: expected_source_type)
        check_if_attribute_type_is_valid!(name, type)
        register_attribute(name)
      end

      private_class_method def check_if_attribute_name_is_ambiguos!(attribute_name)
        if instance_methods.include?(attribute_name.to_sym) || instance_methods.include?("#{attribute_name}=".to_sym)
          raise "Declaration of schemaless attribute with ambiguous name \"#{attribute_name}\" on #{self.class}!"
        end
      end

      private_class_method def check_if_source_exists_and_has_correct_type!(attribute_name, source, expected_type:)
        unless instance_methods.include?(source)
          raise "The provided source \"#{source}\" for schemaless attribute \"#{attribute_name}\" is not defined!"
        end

        return if send(source).is_a?(expected_type)

        raise "The provided source \"#{source}\" for schemaless attribute \"#{attribute_name}\" is a " \
              "#{send(source).class}, it was expected to be a #{expected_type}!"
      end

      private_class_method def check_if_attribute_type_is_valid!(attribute_name, type)
        return if SchemalessAttributes::Type.type_available?(type)

        raise "Schemaless attribute \"#{attribute_name}\" has unsupported type: #{type}!"
      end

      private_class_method def register_attribute(attribute_name)
        @registered_schemaless_attributes << attribute_name.to_s
      end
    end
  end
end
