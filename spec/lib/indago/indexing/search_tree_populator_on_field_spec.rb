# For actions performed on key-value pairs
describe Indago::Indexing::SearchTreePopulator do
  include_context :json_indexing

  let(:search_tree) { {} }
  let(:basic_data) { {} }
  let(:item) { parsed_json.first }
  let(:item_id) { item['_id'] }

  subject do
    populator = described_class.new(search_tree: search_tree, item: item, basic_data: basic_data,
                                    collection_name: collection_name)
    populator.instance_variable_set('@item_id', item_id)
    populator
  end

  describe '#populate_tree_with' do
    let(:primary_key) { Indago::PRIMARY_FIELD_NAME }
    let(:key) { 'name' }
    let(:value) { 'Jon Snow' }

    before(:each) do
      allow(subject).to receive(:populate_primary_field)
      allow(subject).to receive(:populate_by_value_type)
    end

    it 'sets value of key within search tree to empty hash' do
      subject.send(:populate_tree_with, key, value)
      expect(subject.instance_variable_get('@search_tree')).to eq(key => {})
    end

    it 'sets basic value of field if it is within basic data fields' do
      stub_const('Indago::BASIC_DATA_FIELDS', users: key)
      subject.send(:populate_tree_with, key, value)
      expect(subject.instance_variable_get('@basic_data')).to eq(item_id => value)
    end

    it 'calls #populate_primary_field if key is primary' do
      subject.send(:populate_tree_with, primary_key, value)
      expect(subject).to have_received(:populate_primary_field)
      expect(subject).to_not have_received(:populate_by_value_type)
    end

    it 'calls #populate_by_value_type if key is not primary' do
      subject.send(:populate_tree_with, key, value)
      expect(subject).to have_received(:populate_by_value_type)
      expect(subject).to_not have_received(:populate_primary_field)
    end
  end

  describe '#populate_primary_field' do
    let(:search_tree) { { Indago::PRIMARY_FIELD_NAME => {} } }

    it 'populates search tree with whole item if value does not exist yet' do
      subject.send(:populate_primary_field, item_id)
      expect(subject.instance_variable_get('@search_tree')).to eq(Indago::PRIMARY_FIELD_NAME => { item_id => item })
    end

    context 'with value already existing' do
      let(:search_tree) { { Indago::PRIMARY_FIELD_NAME => { item_id => '' } } }

      it 'does not populate search tree if the value already exists' do
        subject
        expect do
          subject.send(:populate_primary_field, item_id)
        end.to_not(change { subject.instance_variable_get('@search_tree') })
      end

      it 'provides a warning for duplicate value' do
        with_stubbed_logger do |logger|
          subject.send(:populate_primary_field, item_id)
          expect(logger).to have_received(:warn).with(/Duplicate #{Indago::PRIMARY_FIELD_NAME}.+#{item_id}/)
        end
      end
    end
  end

  describe '#populate_by_value_type' do
    let(:key) { 'subject' }
    let(:search_tree) { { key => {} } }
    let(:allowed_values) { ['string', 1, 1.5, true, false, nil] }
    let(:unallowed_value) { {} }
    let(:the_array) { %w[one two three] }
    let(:nested_array) { [1, [2, 3, [4]]] }
    let(:expected_tree_with_allowed) { { key => allowed_values.map { |v| [v, [item_id]] }.to_h } }
    let(:expected_tree_with_array) { { key => the_array.map { |v| [v, [item_id]] }.to_h } }

    it 'stores valid data types in search tree' do
      allowed_values.each do |value|
        subject.send(:populate_by_value_type, key, value)
      end
      expect(subject.instance_variable_get('@search_tree')).to eq expected_tree_with_allowed
    end

    it 'stores an array by splitting it into elements' do
      subject.send(:populate_by_value_type, key, the_array)
      expect(subject.instance_variable_get('@search_tree')).to eq expected_tree_with_array
    end

    it 'does not store nested arrays' do
      expect do
        subject.send(:populate_by_value_type, key, nested_array)
      end.to_not(change { subject.instance_variable_get('@search_tree') })
    end

    it 'does not store a value of unallowed type' do
      expect do
        subject.send(:populate_by_value_type, key, unallowed_value)
      end.to_not(change { subject.instance_variable_get('@search_tree') })
    end

    it 'logs a warning if a value of unallowed type is reached' do
      with_stubbed_logger do |logger|
        subject.send(:populate_by_value_type, key, unallowed_value)
        expect(logger).to have_received(:warn).with(/#{unallowed_value}.+#{item_id}.+unsupported format/)
      end
    end
  end
end
