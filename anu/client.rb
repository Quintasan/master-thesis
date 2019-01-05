require "bundler"
Bundler.require

module QRandom
  ENDPOINT = "https://qrng.anu.edu.au/API/jsonI.php".freeze

  def self.url(options = {})
    type = options.fetch(:type) { raise KeyError, "Missing key: type. Valid types are: 'uint8', 'uint16', 'hex16'" }
    length = options.fetch(:length) { raise KeyError, "Missing key: length, Valid values are 1-1024" }
    size = options.fetch(:size) { raise KeyError, "Missing key: size. Valid values are 1-1024" } if type.eql?("hex16")
    return ENDPOINT + "?length=#{length}&type=#{type}&size=#{size}" if size

    ENDPOINT + "?length=#{length}&type=#{type}"
  end

  def self.get(type:, length:, size: 1)
    retries ||= 0
    response = HTTParty.get(url(type: type, length: length, size: size), followlocation: true)
    JSON.parse(response.body).dig("data")
  rescue HTTParty::Error
    retry if (retries += 1) < 3
  end

  UInt8 = Enumerator.new do |enumerator|
    length = 1024
    result = get(type: "uint8", length: length)
    loop do
      enumerator << result
      result = get(type: "uint8", length: length)
    end
  end

  UInt16 = Enumerator.new do |enumerator|
    length = 1024
    result = get(type: "uint16", length: length)
    loop do
      enumerator << result
      result = get(type: "uint16", length: length)
    end
  end

  Hex16 = Enumerator.new do |enumerator|
    length = 1024
    result = get(type: "hex16", length: length, size: 1024)
    loop do
      enumerator << result
      result = get(type: "uint16", length: length)
    end
  end
end

loop do
  puts QRandom::UInt16.next
end
