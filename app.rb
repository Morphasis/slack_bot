require 'sinatra'
require 'httparty'
require 'json'

# {"text"=>"kong activity_morphasis", "trigger_word"=>"kong"}

class GitHubThingsBase

  def repository_url
    "https://api.github.com/repos/#{repository}"
  end

  def issues_url
    "https://api.github.com/repos/#{repository}/issues/events"
  end

  def repository_body
    JSON.parse(HTTParty.get(repository_url).body)
  end

  def issues_body
    JSON.parse(HTTParty.get(issues_url).body)
  end
end

class PullRequest < GitHubThingsBase

  attr_accessor :repository
  def initialize(repository)
    @repository = repository
  end

  def message_output
    total_issue_summary = []

    total_issue_summary = issues_body.map do |issue|
      {
        title: issue["issue"]["title"],
        login: issue["actor"]["login"],
        url: issue["issue"]["html_url"],
        created_at: issue["created_at"]
      }
    end

    issues = total_issue_summary.map do |issue|
      "".tap do |issue_string|
        issue_string << "Title: #{issue[:title]}\n"
        issue_string << "Login: #{issue[:login]}"
      end
    end

    "There are #{issues.count} open issues on #{repository} and here is a summary of all of them: #{issues.join("\n\n")}"
  end

end

post '/gateway' do
  message = params[:text].gsub(params[:trigger_word], '').strip

  action, repo = message.split('_').map {|c| c.strip.downcase }
  repo_url = "https://api.github.com/repos/#{repo}"
  activity_url = "https://api.github.com/users/#{repo}/events"
  issues_url = "https://api.github.com/repos/#{repo}/issues/events"

  case action
    when 'pullrequest'
      respond_message PullRequest.new(repo).message_output
    when 'issues'
      resp = JSON.parse HTTParty.get(repo_url).body
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
