namespace :deploy do
  after :finishing, :log_deploy_event do
    on roles(:app) do |server|
      within release_path do
        set(:current_revision, capture(:cat, 'REVISION'))
        set(:this_server, server.hostname)

        # release path may be resolved already or not
        resolved_release_path = capture(:pwd, '-P')
        set(:release_name, resolved_release_path.split('/').last)
      end
    end

    run_locally do
      user = capture(:git, 'config --get user.name')
      email = capture(:git, 'config --get user.email')

      hash = { app: fetch(:application),
               client: fetch(:stage),
               server: fetch(:this_server),
               release: fetch(:release_name),
               date: Time.now.strftime('%Y-%m-%d'),
               time: Time.now.strftime('%H:%M:%S'),
               git_repo: fetch(:repo_url),
               git_branch: fetch(:branch),
               git_commit: fetch(:current_revision),
               ruby_version: fetch(:chruby_ruby),
               deployed_by: user.strip,
               deployer_email: email.strip,
               deployed_to: fetch(:deploy_to) }

      puts("\n------------------------------------------------------------------------------------------------")
      puts('Log the deployment event: (Copy this command and run it against the deployment log application.)')
      puts("----------------------------------------------------------------------------------------\n\n")
      puts %(curl -d '#{hash.to_json}' -H 'Content-Type: application/json' http://localhost:9292/log_event)
      puts("------------------------------------------------------------------------------------------------\n\n")
    end
  end
end
