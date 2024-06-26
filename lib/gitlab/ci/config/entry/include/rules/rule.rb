# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Include
          class Rules::Rule < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Attributable

            ALLOWED_KEYS = %i[if exists when].freeze
            ALLOWED_WHEN = %w[never always].freeze

            attributes :if, :exists, :when

            validations do
              validates :config, presence: true
              validates :config, type: { with: Hash }
              validates :config, allowed_keys: ALLOWED_KEYS

              with_options allow_nil: true do
                validates :if, expression: true
                validates :exists, array_of_strings_or_string: true, allow_blank: true
                validates :when, allowed_values: { in: ALLOWED_WHEN }
              end
            end

            def value
              config.compact
            end
          end
        end
      end
    end
  end
end
