class MockSearcher < Indago::Searcher
  def call(*); end

  def list_fields
    []
  end
end
