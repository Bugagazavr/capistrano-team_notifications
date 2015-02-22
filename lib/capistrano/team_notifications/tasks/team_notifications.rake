require 'net/http'

namespace :team_notifications do
  task :started do
    team_notify "%{deployer} is deploying %{application}#{':'+branch if branch != 'master'}#{' to '+stage if stage != 'production'}"
  end

  task :finished do
    team_notify "%{deployer} successfully deployed %{application}#{':'+branch if branch != 'master'}#{' to '+stage if stage != 'production'}"
  end

  def team_notify(message)
    deployer = fetch(:deployer,  `git config user.name`.chomp)
    application = fetch(:application)

    message = message % {deployer: deployer, application: application}

    nc_notify(message)
  end

  def nc_notify(message)
    team_notifications_token = fetch(:team_notifications_token)
    team_notifications_host = fetch(:team_notifications_host) || 'space-notice.com'
    team_notifications_port = fetch(:team_notofications_port) || 443
    
    raise "Undefined capistrano-team_notifications token" if team_notifications_token.nil? || team_notifications_token.empty?

    http = Net::HTTP.new(team_notifications_host, team_notifications_port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.post("/p/#{team_notifications_token}", "message=#{message}")
  end

  def branch
    fetch(:branch).to_s
  end

  def stage
    fetch(:stage).to_s
  end
end

namespace :deploy do
  before 'deploy', 'team_notifications:started'
  after 'finished', 'team_notifications:finished'
end
