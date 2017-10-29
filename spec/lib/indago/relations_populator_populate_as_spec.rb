# actual populating according to item specifications
describe Indago::RelationsPopulator do
  include_context(:relations_populating)

  subject { described_class.new(collection_name) }

  describe '#populate' do
    before(:each) do
      stub_const('Indago::RELATIONS', relations)
      allow(subject).to receive(:basic_data_for).and_return(collection_data)
      allow(subject).to receive(:populate_as_child)
      allow(subject).to receive(:populate_as_parent)
    end

    it 'processes options provided in relations and calls #populate_as_child for child relation' do
      subject.populate(item)
      expect(subject).to have_received(:populate_as_child).with(item, collection_data, relations[:users][0])
    end

    it 'processes options provided in relations and calls #populate_as_parent for parent relation' do
      subject.populate(item)
      expect(subject).to have_received(:populate_as_parent).with(item, collection_data, relations[:users][1])
    end

    it 'calls #basic_data_for to retrieve values from related collection' do
      subject.populate(item)
      expect(subject).to have_received(:basic_data_for).with('organizations')
      expect(subject).to have_received(:basic_data_for).with('tickets')
    end

    it 'does not proceed to populate_as... if collection data is empty' do
      allow(subject).to receive(:basic_data_for).and_return({})
      subject.populate(item)
      expect(subject).to_not have_received(:populate_as_parent)
      expect(subject).to_not have_received(:populate_as_child)
    end
  end

  describe '#populate_as_child' do
    let(:parent_name) { 'EvilCorp' }
    let(:collection_data) { { '2' => parent_name } }
    let(:parent_field_name) { organizations_options[:as] }

    it 'populates item with parent field if it is found in collection data' do
      expect { subject.send(:populate_as_child, item, collection_data, organizations_options) }
        .to(change { item[parent_field_name] }.from(nil).to(parent_name))
    end

    it 'does not change item if parent data is not found within collection data' do
      expect { subject.send(:populate_as_child, item, {}, organizations_options) }.to_not(change { item.keys })
    end
  end

  describe '#populate_as_parent' do
    let(:related_children_ids) { %w[2 4] }
    let(:collection_data) { Array.new(5) { |n| [n.to_s, "Ticket #{n}"] }.to_h }
    let(:expected_found_children_hash) do
      related_children_ids.map.with_index { |id, i| ["#{tickets_options[:as]}_#{i + 1}", "Ticket #{id}"] }.to_h
    end

    before(:each) do
      allow(subject).to receive(:values_from_field).and_return(related_children_ids)
    end

    it 'adds related children to item as iterative keys' do
      existing_keys = item.keys
      expect { subject.send(:populate_as_parent, item, collection_data, tickets_options) }
        .to(change { item.except(*existing_keys) }.from({}).to(expected_found_children_hash))
    end

    it 'calls #values_from_field to retrieve necessary data' do
      subject.send(:populate_as_parent, item, collection_data, tickets_options)
      expect(subject).to have_received(:values_from_field).with(tickets_options[:collection], tickets_options[:key],
                                                                item[Indago::PRIMARY_FIELD_NAME])
    end

    it 'does not fail on NoIndexError, but logs it on debug level' do
      allow(subject).to receive(:values_from_field) { raise Indago::Searcher::NoIndexError }
      with_stubbed_logger do |logger|
        subject.send(:populate_as_parent, item, collection_data, tickets_options)
        expect(logger).to have_received(:debug).with(/related field.+#{tickets_options[:key]}/)
      end
    end
  end

  describe '#values_from_field' do
    let(:field) { 'shared' }
    let(:value) { false }

    it 'returns results from searcher method #ids_from_tree_for' do
      searcher_spy = MockSearcher.new(collection_name)
      allow(subject).to receive(:searcher_for).with(collection_name).and_return searcher_spy
      allow(searcher_spy).to receive(:ids_from_tree_for)
      subject.send(:values_from_field, collection_name, field, value)
      expect(searcher_spy).to have_received(:ids_from_tree_for).with(field, value)
    end
  end
end
