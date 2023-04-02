# frozen_string_literal: true

module RequestTimeout
  module Hooks
    class Curb < Base
      def initialize
        @klass = ::Curl::Multi if defined?(::Curl::Multi)
        @methods = [:perform]
      end
    end
  end
end
