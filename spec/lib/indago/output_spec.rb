describe Indago::Output do
  let(:collection_name) { 'tickets' }

  subject { described_class.new(collection_name) }

  describe '#table_print' do
    include_context :muted_output
    let(:terminal_table_spy) { spy(Terminal::Table) }
    let(:item) { { '_id' => 5, 'subject' => 'IE not working properly' } }
    let(:expected_title) { "#{collection_name.singularize.capitalize} ##{item[Indago::PRIMARY_FIELD_NAME]}" }

    before(:each) do
      stub_const('Terminal::Table', terminal_table_spy)
    end

    it 'outputs no results found if result is empty' do
      subject.table_print
      expect(terminal_table_spy).to have_received(:new).with(rows: [['No results found']])
    end

    it 'outputs results with title if they are present' do
      allow(subject).to receive(:wrap_values).and_return([item])
      subject.result = [item]
      subject.table_print
      expect(terminal_table_spy).to have_received(:new).with(rows: [item], title: expected_title)
    end
  end

  describe 'wraps' do
    let(:small_table_width) { 10 }

    before(:each) do
      stub_const('Indago::OUTPUT_TABLE_MAX_WIDTH', small_table_width)
    end

    describe '#wrap_values' do
      let(:value_to_wrap) { 'A' * (small_table_width + 1) }
      let(:normal_value) { 'Short' }
      let(:item) { { a: value_to_wrap, b: value_to_wrap, c: normal_value } }

      it 'calls #wrap for every item value that exceeds OUTPUT_TABLE_MAX_WIDTH' do
        allow(subject).to receive(:wrap)
        subject.send(:wrap_values, item)
        expect(subject).to have_received(:wrap).with(value_to_wrap).twice
      end
    end

    describe 'wrap' do
      let(:exceeding_factor) { 4 }
      let(:value_to_wrap) { 'A' * (small_table_width * exceeding_factor) }
      let(:wrapped_value) { Array.new(exceeding_factor) { 'A' * small_table_width }.join("\n") }

      it 'wraps the value correctly' do
        expect(subject.send(:wrap, value_to_wrap)).to eq wrapped_value
      end
    end
  end
end
