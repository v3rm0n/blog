# Use the maintained system encoder instead of jekyll-webp's bundled binaries.
require 'jekyll-webp'
require 'open3'
require 'shellwords'

module Jekyll
  module Webp
    class WebpExec
      def self.run(quality, flags, input_file, output_file)
        output, error, status = Open3.capture3(
          'cwebp', '-quiet', '-mt', '-q', quality.to_s,
          *Shellwords.split(flags.to_s), input_file, '-o', output_file
        )
        unless status.success?
          raise Jekyll::Errors::FatalException, "WebP conversion failed for #{input_file}: #{error}"
        end
        [output, error]
      rescue Errno::ENOENT
        raise Jekyll::Errors::FatalException, 'Install cwebp (brew install webp or apt-get install webp) before building.'
      end
    end
  end
end
