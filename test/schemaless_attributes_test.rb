# frozen_string_literal: true

require 'test_helper'

module SchemalessAttributes
  class Test < ActiveSupport::TestCase
    setup do
      @lorem_ipsum = File.read(Rails.root.join('test', 'files', 'lorem_ipsum.txt'))
    end

    test 'schemaless attributes should be a rails concern' do
      assert_instance_of Module, SchemalessAttributes
      assert_instance_of Module, SchemalessAttributes::Support
      assert_includes SchemalessAttributes::Support.singleton_class, ActiveSupport::Concern
    end

    test 'should not allow creation of schemaless attributes if same name' do
      # rubocop:disable Lint/ConstantDefinitionInBlock
      combinations = %i[
        json_attribute
        json_attribute
        attachment_attribute
        attachment_attribute
      ].permutation(2).uniq

      combinations.each do |_config|
        assert_raises(StandardError,
                      match: 'Declaration of schemaless attribute with ambiguous name "attribute_one" on DummyClassJson!') do
          class DummyClassJsonWithAmbiguousName
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
        class DummyClassJsonWithUnsupportedType
          include SchemalessAttributes::Support

          json_attribute :attribute_one, type: :file
        end
      end
      # rubocop:enable Lint/ConstantDefinitionInBlock
    end

    test 'should define dummy model with no errors' do
      DummyModel
    end

    test 'should be able to define multiple json attributes at once' do
      # rubocop:disable Lint/ConstantDefinitionInBlock
      class DummyClassJsonWithMultipleJsonAttributes
        include SchemalessAttributes::Support

        json_attributes attribute_one: { type: :string },
                        attribute_two: { type: :integer, source: :json_source }

        json_attribute :attribute_three, type: :text
        json_attribute :attribute_four, type: :date, source: :json_source

        attr_accessor :json_source, :default_json_attributes_source

        def initialize
          @json_source = {}
          @default_json_attributes_source = {}
        end
      end
      # rubocop:enable Lint/ConstantDefinitionInBlock

      dummy_class = DummyClassJsonWithMultipleJsonAttributes.new
      dummy_class.attribute_one = 'attribute_one'
      dummy_class.attribute_two = 42
      dummy_class.attribute_three = 'attribute_three'
      dummy_class.attribute_four = '2024-01-01'

      assert_equal 'attribute_one', dummy_class.attribute_one
      assert_equal 42, dummy_class.attribute_two
      assert_equal 'attribute_three', dummy_class.attribute_three
      assert_equal Date.new(2024, 1, 1), dummy_class.attribute_four

      expected_json_source = { 'attribute_two' => 42, 'attribute_four' => Date.new(2024, 1, 1) }
      assert_equal expected_json_source, dummy_class.json_source

      expected_default_json_attributes_source = { 'attribute_one' => 'attribute_one',
                                                  'attribute_three' => 'attribute_three' }
      assert_equal expected_default_json_attributes_source, dummy_class.default_json_attributes_source
    end

    test 'should raise exception if options does not follow valid syntax in json attributes definition' do
      # rubocop:disable Lint/ConstantDefinitionInBlock
      assert_raises StandardError, match: 'Expected options to be a hash in json attribute definition "syntax_bad"!' do
        class DummyClassInvalidJsonOptions
          include SchemalessAttributes::Support

          json_attributes syntax_ok: { type: :string, source: :json_source },
                          syntax_bad: :string
        end
      end
      # rubocop:enable Lint/ConstantDefinitionInBlock
    end

    test 'should save json data in database and retrieve it in proper format' do
      lorem_ipsum = @lorem_ipsum.dup

      dummy_model = DummyModel.new

      dummy_model.json_attr_integer = '42'
      dummy_model.json_attr_float = '3.14'
      dummy_model.json_attr_decimal = '3.141592'
      dummy_model.json_attr_boolean = 'false'
      dummy_model.json_attr_date = '2024-01-01'
      dummy_model.json_attr_string = 'foo'
      dummy_model.json_attr_text = lorem_ipsum
      dummy_model.json_attr_time = '12:00:00.0'
      dummy_model.json_attr_datetime = '2024-01-01 12:00:00.0 UTC'

      dummy_model.serialized_hash_attr_integer = '42'
      dummy_model.serialized_hash_attr_float = '3.14'
      dummy_model.serialized_hash_attr_boolean = 'false'
      dummy_model.serialized_hash_attr_string = 'foo'
      dummy_model.serialized_hash_attr_text = lorem_ipsum

      dummy_model.save!
      dummy_model.reload

      assert_equal 42, dummy_model.json_attr_integer
      assert_equal 3.14, dummy_model.json_attr_float
      assert_equal false, dummy_model.json_attr_boolean
      assert_equal Date.new(2024, 1, 1), dummy_model.json_attr_date
      assert_equal 'foo', dummy_model.json_attr_string
      assert_equal lorem_ipsum, dummy_model.json_attr_text
      assert_equal Time.new(2000, 1, 1, 12, 0, 0, 'UTC'), dummy_model.json_attr_time
      assert_equal DateTime.new(2024, 1, 1, 12, 0, 0, 'UTC'), dummy_model.json_attr_datetime

      assert_equal 42, dummy_model.serialized_hash_attr_integer
      assert_equal 3.14, dummy_model.serialized_hash_attr_float
      assert_equal false, dummy_model.serialized_hash_attr_boolean
      assert_equal 'foo', dummy_model.serialized_hash_attr_string
      assert_equal lorem_ipsum, dummy_model.serialized_hash_attr_text
    end

    test 'should not be able to edit registered schemaless attributes array from instances' do
      # rubocop:disable Lint/ConstantDefinitionInBlock
      class DummyClassUnableToEditSchemalessAttributes
        include SchemalessAttributes::Support

        json_attribute :foo, type: :string

        def registered_schemaless_attributes_from_object_perspective
          @registered_schemaless_attributes
        end
      end
      # rubocop:enable Lint/ConstantDefinitionInBlock

      assert_includes DummyClassUnableToEditSchemalessAttributes.registered_schemaless_attributes, 'foo'

      dm = DummyClassUnableToEditSchemalessAttributes.new

      refute dm.registered_schemaless_attributes_from_object_perspective

      assert_raises NameError do
        dm.registered_schemaless_attributes
      end
    end

    test 'should no allow creation with implict json source without defining default_json_attributes_source' do
      # rubocop:disable Lint/ConstantDefinitionInBlock
      assert_raises StandardError, match: 'Need to be implemented!' do
        class DummyClassImplicitJsonSource
          include SchemalessAttributes::Support

          json_attribute :attribute_one, type: :string
        end

        dummy_class = DummyClassImplicitJsonSource.new
        dummy_class.attribute_one = 'foo'
      end
      # rubocop:enable Lint/ConstantDefinitionInBlock
    end

    test 'should not allow creation of attachment attribute with ambiguous name' do
      # rubocop:disable Lint/ConstantDefinitionInBlock
      assert_raises(
        StandardError,
        match: 'Declaration of schemaless attribute with ambiguous name "attribute_one" on DummyClassJson'
      ) do
        class DummyClassAttachmentWithAmbigousName
          include SchemalessAttributes::Support

          attachment_attribute :attribute_one, source: :document_attached
          attachment_attribute :attribute_one, source: :document_attached
        end
      end
      # rubocop:enable Lint/ConstantDefinitionInBlock
    end

    test 'should use fallback read if specified' do
      dummy_model = DummyModel.new
      dummy_model.use_fallback_read = true

      dummy_model.fallback_source = 'attachment attr text'

      dummy_model.save!

      assert_equal 'attachment attr text', dummy_model.attachment_attr_text
    end

    test 'should use fallback write if specified' do
      dummy_model = DummyModel.new
      dummy_model.use_fallback_write = true

      dummy_model.attachment_attr_text = 'foo bar'

      dummy_model.save!

      assert_equal 'foo bar', dummy_model.fallback_source
    end

    test 'should write correctly on attachment' do
      lorem_ipsum = @lorem_ipsum
      dummy_model = DummyModel.new
      dummy_model.attachment_attr_text = lorem_ipsum

      dummy_model.save!

      assert_equal lorem_ipsum, dummy_model.attachment_source.download.force_encoding('UTF-8')
    end

    test 'should read correctly from attachment' do
      lorem_ipsum = @lorem_ipsum

      dummy_model = DummyModel.new
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(lorem_ipsum), filename: "#{name}.txt")
      dummy_model.attachment_source = blob

      assert_equal lorem_ipsum, dummy_model.attachment_attr_text
    end
  end
end
