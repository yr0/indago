describe Indago::Indexing::DirIndexer do
  subject { described_class.new }

  describe '#walk_and_index_data_dir!' do
    include_context :no_actual_indexing

    context 'with stubbed data directory' do
      include_context :tmp_dirs, 'data'

      it 'logs a warning message about directory not containing data' do
        with_stubbed_logger do |logger|
          subject.walk_and_index_data_dir!
          expect(logger).to have_received(:warn).with(/#{Indago::DATA_DIR_PATH}/)
        end
      end
    end
  end

  describe '#json_files_from_dir' do
    it 'returns files from data dir as an array' do
      result = subject.send(:json_files_from_dir)
      expect(result.map { |path| File.basename(path, '.json') }).to match_array available_collections
    end
  end

  describe '#pass_contents_to_indexer' do
    include_context :no_actual_indexing, 'json'
    let(:file_path) { File.join(Indago::DATA_DIR_PATH, 'organizations.json') }

    it 'strips dir data from path, reads it, and passes to JsonIndexer' do
      json_indexer_spy = spy(MockJsonIndexer)
      stub_const('Indago::Indexing::JsonIndexer', json_indexer_spy)
      subject.send(:pass_contents_to_indexer, file_path)
      expect(json_indexer_spy).to have_received(:new).with('organizations', File.open(file_path, &:read))
    end
  end
end
