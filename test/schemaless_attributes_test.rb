# frozen_string_literal: true

require 'test_helper'

module SchemalessAttributes
  class Test < ActiveSupport::TestCase
    test 'schemaless attributes should be a rails concern' do
      assert_instance_of Module, SchemalessAttributes
      assert_instance_of Module, SchemalessAttributes::Support
      assert_includes SchemalessAttributes::Support.singleton_class, ActiveSupport::Concern
    end

    test 'should not allow creation of schemaless attributes if same name' do
      # rubocop:disable Lint/ConstantDefinitionInBlock
      combinations = [:json_attribute, :json_attribute, :attachment_attribute, :attachment_attribute].permutation(2).uniq

      combinations.each do |config|
        assert_raises(StandardError,
                      match: 'Declaration of schemaless attribute with ambiguous name "attribute_one" on DummyClass!') do
          class DummyClass
            include SchemalessAttributes::Support

            send(config.first)
            send(config.second)
          end
        end
      end
      # rubocop:enable Lint/ConstantDefinitionInBlock
    end

    test 'should not allow creation of json attribute with invalid data type' do
      # rubocop:disable Lint/ConstantDefinitionInBlock
      assert_raises(StandardError, match: 'Schemaless attribute "attribute_one" has unsupported type: file!') do
        class DummyClass
          include SchemalessAttributes::Support

          json_attribute :attribute_one, type: :file
        end
      end
      # rubocop:enable Lint/ConstantDefinitionInBlock
    end

    test 'should define dummy model with no errors' do
      DummyModel
    end
  end
end
