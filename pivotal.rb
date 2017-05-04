require 'rubygems'
require 'bundler/setup'
require 'dotenv'
Dotenv.load

require "table_print"
require 'virtus'
require 'active_support/all'
require 'tracker_api'


def format_date(date)
  zone = "Pacific Time (US & Canada)"
  date.in_time_zone(zone).strftime("%m/%d/%Y")
end

client = TrackerApi::Client.new(token: ENV["TRACKER_TOKEN"])
start_at = 35.days.ago

activities = client.activity(occurred_after: start_at.iso8601, fields: ":default,message,changes,primary_resources,occurred_at,kind")

parsed_activities = activities.map do |activity|
  result = {
    us_date: format_date(activity.occurred_at),
    raw_date: activity.occurred_at,
    kind: activity.kind,
    msg: activity.message,
  }
  if story_id = activity.try(:primary_resources).try(:first).try(:id)
    story = client.story(story_id)
    result.merge!({
      story_id: story_id,
      story_name: story.name
    })
  else
    result.merge!({ kind: "ERROR #{result[:kind]}"})
  end
  result
end

parsed_activities.sort_by! { |a| a[:raw_date] }

tp parsed_activities, :us_date, :story_id, :kind, :story_name, :msg
