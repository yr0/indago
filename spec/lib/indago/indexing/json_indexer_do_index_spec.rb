# do_index dependent invocations
describe Indago::Indexing::JsonIndexer do
  include_context :json_indexing
  subject { described_class.new(collection_name, raw_json) }

  describe '#do_index' do
    include_context :no_actual_indexing, 'json'

    %i[prepare_index_directory store_basic_data store_search_tree].each do |meth|
      it "calls ##{meth}" do
        stub_const('Indago::Indexing::SearchTreePopulator', MockSearchTreePopulator)
        allow(subject).to receive(meth)
        subject.send(:do_index)
        expect(subject).to have_received(meth)
      end
    end

    it 'instantiates SearchTreePopulator for every value within @array_from_json' do
      populator_spy = spy(MockSearchTreePopulator)
      stub_const('Indago::Indexing::SearchTreePopulator', populator_spy)
      first_element_in_collection = parsed_json.first
      subject.send(:parse_and_check_raw!)
      subject.send(:do_index)
      expect(populator_spy).to have_received(:new).with(item: first_element_in_collection, search_tree: {},
                                                        basic_data: {}, collection_name: collection_name)
    end
  end

  describe '#prepare_index_directory' do
    include_context :tmp_dirs, 'indexes'

    it 'creates index directory for collection and another directory for basic values within it' do
      subject.send(:prepare_index_directory)
      expect(Dir.exist?(File.join(@indexes_tmp_dir_path, collection_name, 'basic'))).to eq true
    end

    it 'does not fail if directory already exists' do
      subject.send(:prepare_index_directory)
      expect { subject.send(:prepare_index_directory) }.not_to raise_error
    end
  end

  describe '#dump_to_index_file' do
    include_context :tmp_dirs, 'indexes'
    let(:dumped_data) { { 'hello' => 'world' } }

    it 'dumps provided contents to a JSON file within index directory' do
      subject.send(:prepare_index_directory)
      subject.send(:dump_to_index_file, dumped_data, 'basic', 'test.json')
      result = File.read(File.join(Indago::INDEXES_DIR_PATH, collection_name, 'basic', 'test.json'))
      expect(result).to eq dumped_data.to_json
    end
  end

  describe '#store_search_tree' do
    let(:search_tree) { { 'subject' => { 'None' => [1, 2, 3] } } }

    it 'calls #dump_to_index_file for each element of search tree hash' do
      allow(subject).to receive(:dump_to_index_file)
      subject.instance_variable_set('@values_search_tree', search_tree)
      subject.send(:store_search_tree)
      expect(subject).to have_received(:dump_to_index_file).with(search_tree['subject'],
                                                                 "subject#{Indago::INDEX_FILE_EXTENSION}")
    end
  end

  describe '#store_basic_data' do
    it 'calls #dump_to_index_file with arguments for basic values index' do
      allow(subject).to receive(:dump_to_index_file)
      subject.send(:store_basic_data)
      basic_data = subject.instance_variable_get('@basic_data')
      expect(subject).to have_received(:dump_to_index_file).with(basic_data, 'basic',
                                                                 "basic#{Indago::INDEX_FILE_EXTENSION}")
    end
  end
end
