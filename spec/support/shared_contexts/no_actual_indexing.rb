shared_context :no_actual_indexing do |level = 'dir'|
  before(:each) do
    if level == 'json'
      allow_any_instance_of(Indago::Indexing::JsonIndexer).to receive(:prepare_index_directory)
      allow_any_instance_of(Indago::Indexing::JsonIndexer).to receive(:dump_to_index_file)
    else
      allow_any_instance_of(Indago::Indexing::DirIndexer).to receive(:pass_contents_to_indexer)
    end
  end
end
