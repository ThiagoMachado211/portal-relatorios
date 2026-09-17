module Ai
  class ToolAuthorization
    PUBLIC_ANALYTICAL_TOOLS = %w[
      enem_metric
      enem_comparison
      enem_evolution
      enem_ranking
    ].freeze

    RESTRICTED_ANALYTICAL_TOOLS = %w[
      customer_service_metric
      customer_service_evolution
    ].freeze

    ALL_TOOLS = (
      PUBLIC_ANALYTICAL_TOOLS +
      RESTRICTED_ANALYTICAL_TOOLS
    ).freeze

    def self.allowed?(user:, tool_name:)
      new(
        user: user,
        tool_name: tool_name
      ).allowed?
    end

    def self.authorize!(user:, tool_name:)
      new(
        user: user,
        tool_name: tool_name
      ).authorize!
    end

    def initialize(user:, tool_name:)
      @user = user
      @tool_name = tool_name.to_s
    end

    def allowed?
      return false unless @user
      return false unless ALL_TOOLS.include?(@tool_name)

      return true if @user.admin?

      if PUBLIC_ANALYTICAL_TOOLS.include?(@tool_name)
        return true
      end

      if RESTRICTED_ANALYTICAL_TOOLS.include?(@tool_name)
        return @user.manager?
      end

      false
    end

    def authorize!
      return true if allowed?

      raise NotAuthorizedError,
            "Você não possui permissão para consultar esses dados."
    end

    class NotAuthorizedError < StandardError
    end
  end
end