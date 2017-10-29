shared_context :with_real_indexes do
  before(:each) do
    # Real fixtured index directory (not to be overwritten)
    stub_const('Indago::INDEXES_DIR_PATH', WITHIN_TEST_DIR.call(%w[fixtures indexes]))
  end
end
