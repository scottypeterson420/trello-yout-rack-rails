class BasicError < StandardError
  attr_reader :details

  def initialize(details = {})
    @details = details
  end

  def as_json
    {error: self.class.name}.merge(details).stringify_keys
  end
end
