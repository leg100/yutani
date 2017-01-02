require 'yutani'

describe Yutani::Utils do
  it "converts normal hashes to indifferent access hash" do
    # consider not using fixture here
    hiera_data = YAML.load_file('spec/fixtures/hiera/common.yaml')
    azs = hiera_data['availability_zones']

    indiff = Yutani::Utils.convert_nested_hash_to_indifferent_access(azs)

    expect(indiff['eu-west-1a'][:public]).to    eq '192.168.0.0/24'
    expect(indiff[:'eu-west-1b']['private']).to eq '192.168.4.0/24'
  end

  it "converts symbols in to strings in flat hashes" do
    h = {
      a: 1,
      b: :c
    }
    
    h2 = Yutani::Utils.convert_symbols_to_strings_in_flat_hash(h)

    expect(h2).to eq({
      'a' => 1,
      'b' => 'c'
    })
  end
end
