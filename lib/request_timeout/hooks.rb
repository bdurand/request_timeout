# frozen_string_literal: true

module RequestTimeout
  # Hooks into other classes from other libraries with timeout blocks. This allows
  # timeouts to be automatically checked before making requests to external services.
  module Hooks
    class << self
      # Apply all the bundled hooks.
      def auto_setup!
        ActiveRecord.new.tap { |instance| instance.add_timeout! if instance.valid? }
        Bunny.new.tap { |instance| instance.add_timeout! if instance.valid? }
        Cassandra.new.tap { |instance| instance.add_timeout! if instance.valid? }
        Curb.new.tap { |instance| instance.add_timeout! if instance.valid? }
        Dalli.new.tap { |instance| instance.add_timeout! if instance.valid? }
        Excon.new.tap { |instance| instance.add_timeout! if instance.valid? }
        HTTPClient.new.tap { |instance| instance.add_timeout! if instance.valid? }
        HTTP.new.tap { |instance| instance.add_timeout! if instance.valid? }
        NetHTTP.new.tap { |instance| instance.add_timeout! if instance.valid? }
        Redis.new.tap { |instance| instance.add_timeout! if instance.valid? }
        Typhoeus.new.tap { |instance| instance.add_timeout! if instance.valid? }
      end

      # Hooks into a class by surrounding specified instance methods with timeout checks.
      def add_timeout!(klass, methods, module_name = nil)
        # Create a module that will be prepended to the specified class.
        unless module_name
          camelized_name = name.to_s.gsub(/[^a-z0-9]+([a-z0-9])/i) { |m| m[m.length - 1, m.length].upcase }
          camelized_name = "#{camelized_name[0].upcase}#{camelized_name[1, camelized_name.length]}"
          module_name = "#{klass.name.split("::").join}#{camelized_name}Hooks"
        end

        if const_defined?(module_name)
          raise ArgumentError.new("Cannot create duplicate #{module_name} for hooking #{name} into #{klass.name}")
        end

        # The method of overriding kwargs changed in ruby 2.7
        ruby_major, ruby_minor, _ = RUBY_VERSION.split(".").collect(&:to_i)
        ruby_3_args = (ruby_major >= 3 || (ruby_major == 2 && ruby_minor >= 7))
        splat_args = (ruby_3_args ? "..." : "*args, &block")

        # Dark arts & witchery to dynamically generate the module methods.
        hooks_module = const_set(module_name, Module.new)
        Array(methods).each do |method_name|
          hooks_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{method_name}(#{splat_args})
              RequestTimeout.check_timeout!
              super(#{splat_args})
            end
          RUBY
        end

        klass.prepend(hooks_module)
      end
    end
  end
end

require_relative "hooks/base"
require_relative "hooks/active_record"
require_relative "hooks/bunny"
require_relative "hooks/cassandra"
require_relative "hooks/curb"
require_relative "hooks/dalli"
require_relative "hooks/excon"
require_relative "hooks/httpclient"
require_relative "hooks/http"
require_relative "hooks/net_http"
require_relative "hooks/redis"
require_relative "hooks/typhoeus"
