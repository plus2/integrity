require 'common_mob'
class Rake < AngryMob::Target
  include CommonMob::ShellHelper

  default_action
  def run
    sh("rake #{default_object} RAILS_ENV=#{args.rails_env}", :cwd => args.rails_root).run
  end
end
