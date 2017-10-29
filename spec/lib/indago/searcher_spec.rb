describe Indago::Searcher do
  let(:collection_name) { 'users' }
  let(:field) { 'name' }
  let(:value) { 'Dale Cooper' }

  subject { described_class.new(collection_name) }

  describe '#initialize' do
    it 'stores initial values in instance variables' do
      expect(subject.collection_name).to eq collection_name
      expect(subject.instance_variable_get('@stored_fields_data')).to eq({})
    end

    it 'initializes with an instance of relations populator' do
      expect(subject.instance_variable_get('@relations_populator')).to be_a Indago::RelationsPopulator
    end
  end

  describe '#call' do
    it 'accepts field and value and passes them to #load_and_process_result' do
      allow(subject).to receive(:load_and_process_result)
      subject.call(field, value)
      expect(subject).to have_received(:load_and_process_result).with(field, value)
    end

    context 'with NoIndexError raised on result load' do
      include_context :tmp_dirs, 'indexes'

      it 'returns empty array if error has been raised' do
        expect(subject.call(field, value)).to eq []
      end

      it 'logs error if NoIndexError has been raised' do
        with_stubbed_logger do |logger|
          subject.call(Indago::PRIMARY_FIELD_NAME, 1)
          expect(logger).to have_received(:fatal).with(/#{Indago::PRIMARY_FIELD_NAME}.+could not be searched.+index/)
        end
      end
    end
  end

  describe '#list_fields' do
    include_context :with_real_indexes

    let(:collection_name) { 'organizations' }
    let(:organization_fields) { %w[_id created_at details domain_names external_id name shared_tickets tags url] }

    it 'lists all available fields for collection by accessing the directory and showing the files' do
      expect(subject.list_fields).to eq organization_fields
    end
  end

  describe '#ids_from_tree_for' do
    let(:field_branch) { { value => value_leaf } }
    let(:field_leaf) { {} }
    let(:value_leaf) { [1, 2, 3] }
    let(:value_leaf_clean) { value_leaf.map(&:to_s) } # transformed to string

    before(:each) do
      allow(subject).to receive(:load_data_for).with(field).and_return(field_branch)
    end

    it 'invokes #load_data_for with field' do
      subject.send(:ids_from_tree_for, field, value)
      expect(subject).to have_received(:load_data_for).with(field)
    end

    it 'returns the contents of tree with path field -> value' do
      result = subject.send(:ids_from_tree_for, field, value)
      expect(result).to eq value_leaf_clean
    end

    it 'returns empty array if value leaf does not exist' do
      allow(subject).to receive(:load_data_for).with(field).and_return(field_leaf)
      result = subject.send(:ids_from_tree_for, field, value)
      expect(result).to eq []
    end
  end
end
