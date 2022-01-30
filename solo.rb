log_level       :info

cwd             = File.expand_path(File.dirname(__FILE__)) 

cookbook_path   ["#{cwd}/cookbooks", "#{cwd}/berkshelf"]

role_path       "#{cwd}/roles" 
data_bag_path   "#{cwd}/data_bags" 
file_cache_path "#{cwd}/cache"
checksum_path   "#{cwd}/checksums"
