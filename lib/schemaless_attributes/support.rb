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

    class_methods do
      def registered_schemaless_attributes
        @registered_schemaless_attributes ||= []
      end

      def json_attribute(name, type:)
        type = type.to_sym
        name = name.to_s

        check_and_register_attribute(name, type)

        define_method name do
          SchemalessAttributes::Type.handler(type).deserialize(json_attributes_source[name])
        end

        define_method "#{name}=" do |value|
          json_attributes_source[name] = SchemalessAttributes::Type.handler(type).cast(value)
        end
      end

      def attachment_attribute(name, source:, fallback_write: proc { false }, fallback_read: proc { false })
        name = name.to_s

        check_and_register_attribute(name, :text)

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

      def check_and_register_attribute(name, type)
        check_if_attribute_name_is_ambiguos(name)
        check_if_attribute_type_is_valid(name, type)
        register_attribute(name)
      end

      def check_if_attribute_name_is_ambiguos(attribute_name)
        if instance_methods.include?(attribute_name.to_sym) || instance_methods.include?("#{attribute_name}=".to_sym)
          raise "Declaration of schemaless attribute with ambiguous name \"#{attribute_name}\" on #{self.class}!"
        end
      end

      def check_if_attribute_type_is_valid(attribute_name, type)
        return if SchemalessAttributes::Type.type_available?(type)

        raise "Schemaless attribute \"#{attribute_name}\" has unsupported type: #{type}!"
      end

      def register_attribute(attribute_name)
        registered_schemaless_attributes << attribute_name.to_s
      end
    end

    def default_json_attributes_source
      raise 'Need to be implemented!'
    end
  end
end
