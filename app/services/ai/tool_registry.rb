module Ai
  class ToolRegistry
    REGISTRIES = [
      Ai::EnemToolRegistry,
      Ai::CustomerServiceToolRegistry
    ].freeze

    def self.definitions(user: nil)
      definitions =
        REGISTRIES.flat_map(&:definitions)

      return definitions unless user

      definitions.select do |definition|
        name =
          definition[:name] ||
          definition["name"]

        Ai::ToolAuthorization.allowed?(
          user: user,
          tool_name: name
        )
      end
    end

    def self.execute(name, arguments, user: nil)
      registry =
        registry_for(name)

      unless registry
        raise ArgumentError,
              "Ferramenta não permitida: #{name}"
      end

      if user
        Ai::ToolAuthorization.authorize!(
          user: user,
          tool_name: name
        )
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