require 'sinatra'
require 'httparty'
require 'json'

post '/gateway' do
  puts "PARAMS: #{params.inspect}"
  message = params[:text].gsub(params[:trigger_word], '').strip

  action, repo = message.split('_').map {|c| c.strip.downcase }
  repo_url = "https://api.github.com/repos/#{repo}"
  activity_url = "https://api.github.com/users/#{repo}/events"

  case action
    when 'issues'
      resp = HTTParty.get(repo_url)
      resp = JSON.parse resp.body
      puts resp
      respond_message "There are #{resp['open_issues_count']} open issues on #{repo}"
    when 'help'
      respond_message "Hi there my name is Kong Bot. I'm here to provide
 interesting and new bot functionality :bowtie: currently supported
 commands are issues_(repo) to get number of PR's, help and activity_(person)"
    when 'activity'
      resp = HTTParty.get(activity_url)
      resp = JSON.parse resp.body
      respond_message "Most recent commit (may not be work related)
      (currently in progress as it works per push requires more logic :robot_face:)
      #{resp[0]["payload"]["commits"][0]["message"]}"
  end
end

def respond_message message
  content_type :json
  {:text => message}.to_json
end
