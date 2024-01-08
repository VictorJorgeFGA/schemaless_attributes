# frozen_string_literal: true

require 'test_helper'

module SchemalessAttributes
  class Test < ActiveSupport::TestCase
    test 'schemaless attributes should be a rails concern' do
      assert_instance_of Module, SchemalessAttributes
      assert_instance_of Module, SchemalessAttributes::Support
      assert_includes SchemalessAttributes::Support.singleton_class, ActiveSupport::Concern
    end

    test 'dummy' do
      DummyModel
    end
  end
end
