module RequestTracker
  class MailerEnqueueSubscriber
    def self.subscribe
      ActiveSupport::Notifications.subscribe("enqueue.active_job") do |*, payload|
        job = payload[:job]

        next if !job.is_a?(ActionMailer::MailDeliveryJob)
        next if !RequestTracker.config.enabled_environments.include?(Rails.env)
        next if !RequestTracker::Current.enqueued_mailers

        mailer_class, action, _delivery_method, args_hash = job.arguments
        args_hash = {} if !args_hash.is_a?(Hash)

        RequestTracker::Current.enqueued_mailers << {
          mailer_class: mailer_class,
          action: action,
          args: args_hash[:args] || args_hash["args"],
          queue: job.queue_name,
          job_id: job.job_id
        }
      end
    end
  end
end
