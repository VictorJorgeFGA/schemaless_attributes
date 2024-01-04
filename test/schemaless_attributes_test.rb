# frozen_string_literal: true

require 'test_helper'

module SchemalessAttributes
  class Test < ActiveSupport::TestCase
    test 'truth' do
      assert_kind_of Module, SchemalessAttributes
    end
  end
end
