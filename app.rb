require 'sinatra'
require 'httparty'
require 'json'

# {"text"=>"kong activity_morphasis", "trigger_word"=>"kong"}

post '/gateway' do
  message = params[:text].gsub(params[:trigger_word], '').strip

  action, repo = message.split('_').map {|c| c.strip.downcase }
  repo_url = "https://api.github.com/repos/#{repo}"
  activity_url = "https://api.github.com/users/#{repo}/events"
  issues_url = "https://api.github.com/repos/#{repo}/issues/events"

  case action
    when 'pullrequest'
      resp = HTTParty.get(repo_url)
      resp = JSON.parse resp.body
      resp_issue = HTTParty.get(issues_url)
      resp_issue = JSON.parse resp_issue.body
      total_issue_summary = Array.new
      resp_issue.each { |x|
        total_issue_summary.push(x["issue"]["title"])
        total_issue_summary.push(x["actor"]["login"])
        total_issue_summary.push(x["issue"]["html_url"])
        total_issue_summary.push(x["created_at"])
      }
      respond_message "There are #{resp['open_issues_count']} open issues on #{repo} and here is a summary of all of them:
 '#{total_issue_summary.join("\n")}'"
    when 'issues'
      resp = HTTParty.get(repo_url)
      resp = JSON.parse resp.body
      respond_message "There are #{resp['open_issues_count']} open issues on #{repo}"
    when 'help'
      respond_message "Hi there my name is Kong Bot. I'm here to provide
 interesting and new bot functionality :bowtie: currently supported
 commands are issues_(repo) to get number of PR's, help, activity_(person), pullrequest_(repo)"
    when 'activity'
      resp = HTTParty.get(activity_url)
      resp = JSON.parse resp.body
      commit_messages = Array.new
      resp.each { |x|
        if (!x["payload"].nil? && !x["payload"]["commits"].nil?)
          commit_messages.push(x["payload"]["commits"][0]["message"])
        end
      }
      respond_message "Most recent commit (may not be work related)
 (currently in progress as it works per push requires more logic :robot_face:)
 Commit messages:
 '#{commit_messages.join("'\n'")}'"
  end
end

def respond_message message
  content_type :json
  {:text => message}.to_json
end
