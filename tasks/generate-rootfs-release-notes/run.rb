#!/usr/bin/env ruby

require 'octokit'
require 'open-uri'
require_relative '../../lib/release-notes-creator'
require_relative '../../lib/git-client'


previous_version = File.read('previous-rootfs-release/.git/ref').strip
new_version = File.read('version/number').strip
stack = ENV.fetch('STACK')
ubuntu_version = {
  'cflinuxfs3' => '18.04',
  'cflinuxfs4' => '22.04',
}.fetch(stack) or raise "Unsupported stack: #{stack}"

receipt_file_name = "receipt.#{stack}.x86_64"
old_receipt_uri = "https://raw.githubusercontent.com/cloudfoundry/#{stack}/#{previous_version}/#{receipt_file_name}"

cve_yaml_file = "new-cves/new-cve-notifications/ubuntu#{ubuntu_version}.yml"
cves_dir = 'new-cve-notifications'

new_receipt_file = "rootfs/#{receipt_file_name}"
old_receipt = Tempfile.new('old-receipt')
File.write(old_receipt.path, open(old_receipt_uri).read)

body_file = 'release-body/body'
notes = RootfsReleaseNotesCreator.new(cve_yaml_file, old_receipt.path, new_receipt_file).release_notes
puts notes
File.write(body_file, notes)
old_receipt.unlink

cves = YAML.load_file(cve_yaml_file)

updated_cves = cves.map do |cve|
  if cve['stack_release'] == 'unreleased'
    cve['stack_release'] = new_version
  end
  cve
end

File.write(cve_yaml_file, updated_cves.to_yaml)


robots_cve_dir = File.join('new-cves', cves_dir)
Dir.chdir(robots_cve_dir) do
  GitClient.add_file("ubuntu#{ubuntu_version}.yml")
  commit_message = "Updating CVEs for #{stack} release #{new_version}\n\n"
  GitClient.safe_commit(commit_message)
end

system "rsync -a new-cves/ new-cves-artifacts"
