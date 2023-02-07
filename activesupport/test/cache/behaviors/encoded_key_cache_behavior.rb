# frozen_string_literal: true

# https://rails.lighthouseapp.com/projects/8994/tickets/6225-memcachestore-cant-deal-with-umlauts-and-special-characters
# The error is caused by character encodings that can't be compared with ASCII-8BIT regular expressions and by special
# characters like the umlaut in UTF-8.
module EncodedKeyCacheBehavior
  DELAY_FOR_RACE_CONDITION = 0.5

  Encoding.list.each do |encoding|
    define_method "test_#{encoding.name.underscore}_encoded_values" do
      key = (+"foo_#{encoding.name.underscore}#{SecureRandom.uuid}").force_encoding(encoding)
      value = "1"
      assert @cache.write(key, value, raw: true)
      assert_equal value, @cache.read(key, raw: true)
      assert_equal value, @cache.fetch(key, raw: true)

      assert @cache.delete(key)
      assert_equal "2", @cache.fetch(key, raw: true) { "2" }
      current = @cache.fetch(key, raw: true).to_i
      incremented_value = @cache.increment(key)
      assert_equal current + 1, incremented_value
      current = @cache.fetch(key, raw: true).to_i
      decremented_value = @cache.decrement(key)
      assert_equal current - 1, decremented_value
    end
  end

  def test_common_utf8_values
    key = (+"\xC3\xBCmlaut").force_encoding(Encoding::UTF_8)
    assert @cache.write(key, "1", raw: true)
    assert_equal "1", @cache.read(key, raw: true)
    assert_equal "1", @cache.fetch(key, raw: true)
    assert @cache.delete(key)
    assert_equal "2", @cache.fetch(key, raw: true) { "2" }
    assert_equal 3, @cache.increment(key)
    assert_equal 2, @cache.decrement(key)
  end

  def test_retains_encoding
    key = (+"\xC3\xBCmlaut").force_encoding(Encoding::UTF_8)
    assert @cache.write(key, "1", raw: true)
    assert_equal Encoding::UTF_8, key.encoding
  end
end
