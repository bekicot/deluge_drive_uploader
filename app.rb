#! /home/bekicot/.rbenv/shims/ruby
require 'rubygems'
require 'bundler'
Bundler.require(:default)

require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'irb'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Drive API Ruby Quickstart'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "drive-ruby-quickstart.yaml")
SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_FILE

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(
    client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(
      base_url: OOB_URI)
    puts "Open the following URL in the browser and enter the " +
         "resulting code after authorization"
    puts url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI)
  end
  credentials
end

def create_file_recursive(service, dir, parent: )
  drive_folder = create_directory(service, dir, parent: parent)
  dir.each do |sub|
    next if sub == '.' || sub == '..'
    loc = File.join(dir, sub)
    if File.directory? loc
      create_file_recursive(service, Dir.new(loc), parent: drive_folder.id)
    else
      create_file(service, loc, parent: drive_folder.id)
    end
  end
end

def create_directory(service, dir, parent: )
  file_metadata = {
    name: File.basename(dir),
    parents: [parent],
    mime_type: 'application/vnd.google-apps.folder'
  }
  service.create_file(file_metadata, fields: 'id')
end

def create_file(service, file, parent: )
  file_metadata = {
    name: File.basename(file),
    parents: [parent]
  }
  service.create_file(file_metadata, fields: 'id', upload_source: file)
end
# Initialize the API
service = Google::Apis::DriveV3::DriveService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

# Buat Folder Di gDrive
dir = Dir.new(ARGV[2])
name = File.basename dir
create_file_recursive(service, dir, parent: '0B0iWtFv5fxG1OTBrdVdBbU1OU2s')