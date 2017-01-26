namespace :sync do
  
  require 'digest/sha1'
  
  # bundle exec rake sync:validate_json_manifest --trace
  desc "validate json manifest"
  task :validate_json_manifest do
    json_file = File.join(Rails.root, "config/sync_manifest.json")
    begin
      errors = JSON.parse(File.read(json_file))
      puts "All good -- proceed to SyncTown!"
    rescue StandardError => e
      puts "Hit error #{e}"
    end
  end
  
  #
  # Make the decision whether or not to copy the sync'd file
  #
  def should_copy?(source, target)
    return true
    return true if !File.exists?(target)

    source_sha = Digest::SHA1.hexdigest(File.read(source))
    target_sha = Digest::SHA1.hexdigest(File.read(target))
    
    debugger if source_sha != target_sha
    
    return true if source_sha == target_sha
    
    return false
  end
  
  # bundle exec rake sync:copy --trace
  desc 'Copy common models, lib files, shared views, helpers, etc from one repo to another'
  task :copy do
    json_file = File.join(Rails.root, "config/sync_manifest.json")
    sync_manifest = JSON.parse(File.read(json_file))

    # boolean var for generating debugging output
    do_copy = true
    
    sync_manifest["files"].each do |json_source, json_targets|
      json_targets.each do |json_target|
        source = File.join(Rails.root, json_source)
        target = File.join(json_target, json_source)
        cp_command = "cp #{source} #{target}"
        if 3 == 3 #should_copy?(source, target)
          puts "  #{cp_command}"
          `#{cp_command}`
        else
          puts "\n\nThere are local changes to: #{target} so NO SYNC was made; please investigate"
        end
      end
    end
  end
end