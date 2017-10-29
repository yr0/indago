describe Indago::CLI do
  include_context :muted_output
  let(:options) { {} }
  let(:collection_name) { 'users' }

  subject do
    described_class.new([]).tap { |obj| obj.options = options }
  end

  describe '#index' do
    it 'creates dir indexer and calls #walk_and_index_data_dir! on it' do
      mock_dir_indexer = MockDirIndexer.new
      allow(mock_dir_indexer).to receive(:walk_and_index_data_dir!)
      allow(Indago::Indexing::DirIndexer).to receive(:new).and_return(mock_dir_indexer)
      subject.index
      expect(mock_dir_indexer).to have_received(:walk_and_index_data_dir!)
    end
  end

  describe '#search' do
    let(:field) { 'name' }
    let(:value) { 'Rust Cohle' }
    let(:options) { { 'collection' => collection_name, 'field' => field, 'value' => value } }

    it 'creates Searcher and instantiates it with collection name' do
      searcher_spy = spy(MockSearcher)
      stub_const('Indago::Searcher', searcher_spy)
      subject.search
      expect(searcher_spy).to have_received(:new).with(collection_name)
    end

    it 'calls Searcher with provided options' do
      searcher_spy = spy(MockSearcher)
      stub_const('Indago::Searcher', searcher_spy)
      subject.search
      expect(searcher_spy).to have_received(:call).with(field, value)
    end
  end

  describe '#list_fields' do
    let(:options) { { 'collection' => collection_name } }

    it 'creates Searcher and instantiates it with collection name' do
      searcher_spy = spy(MockSearcher)
      stub_const('Indago::Searcher', searcher_spy)
      subject.list_fields
      expect(searcher_spy).to have_received(:new).with(collection_name)
    end

    it 'calls list_fields on Searcher' do
      searcher_spy = spy(MockSearcher)
      stub_const('Indago::Searcher', searcher_spy)
      subject.list_fields
      expect(searcher_spy).to have_received(:list_fields)
    end
  end
end
