require 'sinatra'
require 'httparty'
require 'json'

post '/gateway' do
  puts "PARAMS: #{params.inspect}"
  message = params[:text].gsub(params[:trigger_word], '').strip

  action, repo = message.split('_').map {|c| c.strip.downcase }
  repo_url = "https://api.github.com/repos/#{repo}"

  case action
    when 'issues'
      resp = HTTParty.get(repo_url)
      puts resp
      resp = JSON.parse resp.body
      respond_message "There are #{resp['open_issues_count']} open issues on #{repo}"
    when 'help'
      respond_message "Hi there my name is Kong Boy. I'm here to provide interesting and new boy functionality https:\/\/my.slack.com\/emoji\/bowtie\/46ec6f2bb0.png"
  end
end

def respond_message message
  content_type :json
  {:text => message}.to_json
end
