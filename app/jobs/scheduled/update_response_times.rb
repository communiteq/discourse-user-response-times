# frozen_string_literal: true

module Jobs
  class UpdateResponseTimes < Jobs::Scheduled
    every 24.hours

    def execute(_args)
      return unless SiteSetting.user_response_times_enabled

      ResponseTimeCalculator.update_response_times
    end
  end
end
