module RequestTracker
  class MailerPerformSubscriber
    def self.subscribe
      ActiveSupport::Notifications.subscribe("perform_start.active_job") do |*, payload|
        job = payload[:job]

        next if !job.is_a?(ActionMailer::MailDeliveryJob)
        next if !RequestTracker.config.enabled_environments.include?(Rails.env)

        RequestTracker::Current.executing_job_id = job.job_id
      end
    end
  end
end
