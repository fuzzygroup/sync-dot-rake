namespace :sync do
  
  require 'digest/sha1'
  

  
  # bundle exec rake sync:list_manifests --trace
  desc "List all manifests"
  task :list_manifests do
    manifests = get_manifests
    
    puts "Manifests exist here:"
    puts "==============================================================="
    manifests.each do |manifest|
      puts manifest
    end
  end
  
  # bundle exec rake sync:search_manifests search=user.rb
  desc "Search manifests"
  task :search_manifests do
    search_q = ENV['search']
    manifests = get_manifests
    
    search_hits = []
    
    manifests.each do |manifest|
      json_manifest = File.read(manifest)
      json = JSON.parse(json_manifest)
      
      files_to_sync = json["files"]
      
      files_to_sync.keys.each do |file_to_sync_key|
        #debugger
        #if search_q =~ /#{file_to_sync_key}/
        if file_to_sync_key.include?(search_q)
          search_hits << manifest
        end
      end
    end
    
    if search_hits.empty?
      puts "There are no results for: #{search_q} in any manifest"
    else
      puts "The file: #{search_q} is found in the following manifests:"

      search_hits.each do |search_hit|
        puts search_hit
      end
    end
  end
  
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
        original_json_source = json_source
        source_file = File.join(Rails.root, json_source)
        #
        # Extension for handling wildcards 
        #
        if json_source =~ /\*/
          #
          # Example:
          # app/models/page_*.rb
          #
          parts = original_json_source.split(/\/[^\/]*$/)
          # generates a command like this
          # cp /Users/sjohnson/Dropbox/fuzzygroup/hyde/hyde_web/app/models/page_*.rb ../hyde_page_parser/app/models
          
          target = File.join(json_target, parts[0])
          #debugger
        else
          target = File.join(json_target, json_source)
        end
        cp_command = "cp #{source_file} #{target}"
        if 3 == 3 #should_copy?(source, target)
          puts "  #{cp_command}"
          `#{cp_command}`
        else
          puts "\n\nThere are local changes to: #{target} so NO SYNC was made; please investigate"
        end
      end
    end
  end
  
  def get_manifests
    current_path = Rails.root
    parts = current_path.to_s.split("/")
    base_path = []
    parts.each_with_index do |part, ctr|
      next if ctr == parts.size - 1
      base_path << part
    end
    base_dir_path = base_path.join('/')
    
    #sub_directories = 
    
    sub_directories=Dir["#{base_dir_path}/*"].reject{|o| not File.directory?(o)}
    #debugger
    manifests = []
    sub_directories.each do |sub_directory|
      possible_manifest_file = File.join(sub_directory, "config/sync_manifest.json")
      #debugger
      if File.exists?(possible_manifest_file)
        manifests << possible_manifest_file
      end 
    end
    return manifests
  end
end