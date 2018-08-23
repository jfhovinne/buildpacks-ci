class SourceInput
  attr_reader :url, :md5, :git_commit_sha
  attr_accessor :name, :version, :sha256

  def initialize(name, url, version, md5, sha256, git_commit_sha = nil)
    @name    = name
    @url     = url
    @version = version
    @md5     = md5
    @sha256  = sha256
    @git_commit_sha = git_commit_sha
  end

  def self.from_file(source_file)
    data = JSON.parse(open(source_file).read)
    SourceInput.new(
      data.dig('source', 'name') || '',
      data.dig('version', 'url') || '',
      data.dig('version', 'ref') || '',
      data.dig('version', 'md5_digest'),
      data.dig('version', 'sha256'),
      data.dig('version', 'git_commit_sha')
    )
  end

  def md5?
    !@md5.nil?
  end

  def sha256?
    !@sha256.nil?
  end
end