require 'csv'
require 'open3'

require_relative '../models/android_variant_model'

class AndroidUtils 
    def self.filter_estimated_sizes(path, screen_densities, languages)
        filtered_sizes = []
        CSV.foreach(path, headers: true) { |row|
            sdk = row[AndroidVariant::PARSING_KEYS[:sdk]]
            abi = row[AndroidVariant::PARSING_KEYS[:abi]]
            screen_density = row[AndroidVariant::PARSING_KEYS[:screen_density]]
            language = row[AndroidVariant::PARSING_KEYS[:language]]
            texture_compression_format = row[AndroidVariant::PARSING_KEYS[:texture_compression_format]]
            device_tire = row[AndroidVariant::PARSING_KEYS[:device_tire]]
            min = row[AndroidVariant::PARSING_KEYS[:min]]
            max = row[AndroidVariant::PARSING_KEYS[:max]]
            
            if (screen_densities.include? screen_density and languages.include? language)
                filtered_sizes << AndroidVariant.new(sdk, abi, screen_density, language, texture_compression_format, device_tire, min, max)
            end
        }
        filtered_sizes
    end

    def self.sort_estimated_sizes(size_arr) 
        size_arr.sort{|o1, o2| o2.max <=> o1.max} 
    end

    def self.violations_count(sortedArr, limit)
        lb = -1; ub = sortedArr.length
        while ub - lb > 1
            mid = (lb + ub) / 2
            if sortedArr[mid].max >= limit
                lb = mid
            else
                ub = mid
            end
        end
        ub
    end

    def self.generate_apks(aab_path, ks_path, ks_alias, ks_password, build_type, apks_path, bundletool_path) # TODO: add key alias password
        keystore_params = "--ks=\"#{ks_path}\" --ks-key-alias=\"#{ks_alias}\" --ks-pass=\"pass:#{ks_password}\""
        cmd = "java -jar #{bundletool_path} build-apks --bundle=\"#{aab_path}\" --output=\"#{apks_path}\" #{keystore_params}"
        if(build_type == "Instant") 
            cmd += " --instant"
        end
        Open3.popen3(cmd) do |_, _, stderr, wait_thr|
            exit_status = wait_thr.value
            raise stderr.read unless exit_status.success?
        end
    end
    
    def self.generate_estimated_sizes(apks_path, size_csv_path, bundletool_path)
        cmd = "java -jar #{bundletool_path} get-size total --apks=\"#{apks_path}\" --dimensions=ALL > #{size_csv_path}"
        Open3.popen3(cmd) do |_, _, stderr, wait_thr|
            exit_status = wait_thr.value
            raise stderr.read unless exit_status.success?
        end
    end

    def self.download_bundletool(version, bundletool_path)       
        URI.open("https://github.com/google/bundletool/releases/download/#{version}/bundletool-all-#{version}.jar") do |bundletool|
              File.open(bundletool_path, 'wb') do |file|
                file.write(bundletool.read)
            end
        end
      rescue OpenURI::HTTPError => e
        false
      end
    
end