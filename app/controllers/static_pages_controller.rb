class StaticPagesController < ApplicationController
  def index
    if current_user
      @project_names = current_user.project_names
      @projects = current_user.project_labels
      @current_project = current_user.active_project
    end
  end

  def project_durations
    return unless current_user

    @project_durations = Rails.cache.fetch("user_#{current_user.id}_project_durations", expires_in: 1.minute) do
      project_times = current_user.heartbeats.group(:project).duration_seconds
      project_labels = current_user.project_labels

      project_times.map do |project, duration|
        {
          project: project_labels.find { |p| p.project_key == project }&.label || project || "Unknown",
          duration: duration
        }
      end.filter { |p| p[:duration].positive? }.sort_by { |p| p[:duration] }.reverse
    end

    render partial: "project_durations", locals: { project_durations: @project_durations }
  end

  def activity_graph
    return unless current_user

    @daily_durations = Heartbeat
      .where(user_id: current_user.slack_uid, time: 365.days.ago..)
      .group(Arel.sql("DATE_TRUNC('day', time)"))
      .duration_seconds
      .transform_keys(&:to_date)

    @length_of_busiest_day = @daily_durations.values.max

    render partial: "activity_graph", locals: {
      daily_durations: @daily_durations,
      length_of_busiest_day: @length_of_busiest_day
    }
  end
end
