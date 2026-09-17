module Ai
  class ToolRegistry
    REGISTRIES = [
      Ai::EnemToolRegistry,
      Ai::CustomerServiceToolRegistry
    ].freeze

    def self.definitions
      REGISTRIES.flat_map(&:definitions)
    end

    def self.execute(name, arguments)
      registry =
        registry_for(name)

      unless registry
        raise ArgumentError,
              "Ferramenta não permitida: #{name}"
      end

      registry.execute(
        name,
        arguments
      )
    end

    def self.tool_names
      REGISTRIES.flat_map do |registry|
        registry::TOOL_NAMES
      end
    end

    def self.valid?(name)
      tool_names.include?(name.to_s)
    end

    def self.registry_for(name)
      normalized =
        name.to_s

      REGISTRIES.find do |registry|
        registry::TOOL_NAMES.include?(
          normalized
        )
      end
    end
  end
end