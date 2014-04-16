require 'fog'
require "colorize"

Fog.credentials = { path_style: true }

# A FogSite represents a site to be deployed to S3 and CloudFront. This object
# is a simple data structure, which is deployed with a `FogSite::Deployer`
#
class FogSite
  attr_reader :domain_name
  attr_writer :access_key_id, :secret_key, :fog_options
  attr_accessor :path, :destroy_old_files, :distribution_id, :headers

  def initialize( domain_name, attributes_map = {})
    @domain_name = domain_name
    attributes_map.each do |name, val|
      setter = (name.to_s + "=").to_sym
      self.send(setter, val)
    end
  end

  def fog_options
    @fog_options || {}
  end

  def access_key_id
    @access_key_id || ENV["AWSAccessKeyId"]
  end

  def secret_key
    @secret_key || ENV["AWSSecretKey"]
  end

  def deploy!
    Deployer.run(self)
  end

  # Used to actually execute a deploy. This object is not safe for reuse - the
  # `@index` and `@updated_paths` stay dirty after a deploy to allow debugging
  # and inspection by client scripts.
  class Deployer
    attr_reader :index, :updated_paths
    class UsageError < StandardError ; end

    # Run a single deploy. Creates a new `Deployer` and calls `run`.
    def self.run( site, options = {} )
      deployer = Deployer.new( site )
      deployer.run
    end

    def initialize( site )
      @site = site
      @index = {}
      @updated_paths = []
    end

    # Validate our `Site`, create a and configure a bucket, build the index,
    # sync the files and (finally) invalidate all paths which have been updated
    # on the content distribution network.
    def run
      validate
      make_directory
      Dir.chdir @site.path do
        build_index
        sync_remote
        if( @site.distribution_id )
          invalidate_cache(@site.distribution_id)
        end
      end
    end

    def validate
      assert_not_nil @site.access_key_id, "No AccessKeyId specified"
      assert_not_nil @site.secret_key, "No SecretKey specified"
    end

    # Creates an S3 bucket for web site serving, using `index.html` and
    # `404.html` as our special pages.
    def make_directory
      domain = @site.domain_name
      puts "Using bucket: #{domain}".blue
      @directory = connection.directories.get domain
      unless @directory
        puts "Creating nw bucket.".red
        @directory = connection.directories.create :key => domain,
                                                  :public => true
      end
      connection.put_bucket_website(domain, 'index.html', :key => "404.html")
    end

    # Build an index of all the local files and their md5 sums. This will be
    # used to decide what needs to be deployed.
    def build_index
      Dir["**/*"].each do |path|
        unless File.directory?( path )
          @index[path] = Digest::MD5.file(path).to_s
        end
      end
    end

    # Synchronize our local copy of the site with the remote one. This uses the
    # index to detect what has been changed and upload only new/updated files.
    # Helpful debugging information is emitted, and we're left with a populated
    # `updated_paths` instance variable which can be used to invalidate cached
    # content.
    def sync_remote
      @directory.files.each do |remote_file|
        path = remote_file.key
        local_file_md5 = @index[path]

        if local_file_md5.nil? and @site.destroy_old_files
          puts "#{path}: deleted".red
          remote_file.destroy
          mark_updated( "/#{path}" )
        elsif local_file_md5 == remote_file.etag
          puts "#{path}: unchanged".white
          @index.delete( path )
        else
          puts "#{path}: updated".green
          write_file( path )
          @index.delete( path )
          mark_updated( "/#{path}" )
        end
      end

      @index.each do |path, md5|
        puts "#{path}: new".green
        write_file( path )
      end
    end

    def mark_updated( path )
      @updated_paths << path
      if path =~ /\/index\.html$/
        @updated_paths << path.sub( /index\.html$/, '' )
      end
    end

    # Push a single file out to S3.
    def write_file( path )
      opts = {
        :key => path,
        :body => File.open( path ),
        :public => true
      }

      opts[:metadata] = @site.headers if @site.headers

      @directory.files.create opts
    end

    # Compose and post a cache invalidation request to CloudFront. This will
    # ensure that all CloudFront distributions get the latest content quickly.
    def invalidate_cache( distribution_id )
      unless @updated_paths.empty?
        cdn.post_invalidation distribution_id, @updated_paths
      end
    end

    def cdn
      @cdn ||= Fog::CDN.new( cdn_credentials )
    end

    def connection
      @connection ||= Fog::Storage.new( credentials )
    end

    def credentials
      {
        :provider              => 'AWS',
        :aws_access_key_id     => @site.access_key_id,
        :aws_secret_access_key => @site.secret_key
      }.merge @site.fog_options
    end

    def cdn_credentials
      credentials.delete_if { |k, v| k == :region }
    end

    def assert_not_nil( value, error )
      raise UsageError.new( error ) unless value
    end
  end
end
