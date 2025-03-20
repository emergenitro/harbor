class OneTime::SetUserTimezoneFromSlackJob < ApplicationJob
  queue_as :default

  def perform
    User.where.not(slack_uid: nil).find_each(batch_size: 100) do |user|
      begin
        user.set_timezone_from_slack
        user.save!
      rescue => e
        Rails.logger.error "Failed to update timezone for user #{user.id}: #{e.message}"
      end
    end
  end
end
