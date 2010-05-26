consolidate_node do |node,defaults|
  %w[home current_path].each {|k| node.attributes[k] = Pathname(node.attributes[k])}
end

act 'yesmaster/prepare_app' do
  dir(node.home+'bin')
  dir(node.home+'scripts')

  git(node.home+'scripts/integrity-build-wrapper', :repo => 'git://github.com/plustwo/integrity-build-wrapper.git')
  symlink(node.home+'bin/plus2build', :to => node.home+'scripts/integrity-build-wrapper/integrity_build_wrapper.rb')

  template(node.current_path+'init.rb', :src => 'init.rb.erb')

  act_now 'ping github'
end

act 'yesmaster/before_restart' do
  if node.rake_db?
    rake 'db', :rails_env => node.rails_env, :rails_root => node.current_path
  end
end

act 'ping github' do
  dot_ssh    = ENV['HOME'].pathname + '.ssh'
  id_dsa     = dot_ssh+'id_dsa-github'
  id_dsa_pub = dot_ssh+'id_dsa-github.pub'

  # Generate a key.
  sh( "echo | ssh-keygen -t dsa -f #{id_dsa}", :creates => id_dsa ).changed? &&

  # Use the github API to register the key.
  sh( "curl -v -F 'login=plus2deployer' -F 'token=#{node.integrity.github_api_token}' -F 'key=#{id_dsa_pub.read.chomp}' " \
      "'https://github.com/api/v2/json/user/key/add' -H 'Accept: text/json'"
  ).changed? &&

  # ssh to github with `StrictHostKeyChecking no`. This stops us having to manually agreeing to add the key to our known_hosts.
  # This is probably a gaping security hole, mind.
  sh("ssh -o'StrictHostKeyChecking no' git@github.com; exit 0")

  file(node.home+".ssh/config", :string => "Host github.com\n  IdentityFile #{id_dsa}", :mode => 0600)
end
