require 'wordnet'
require 'set'


def search(synset_id)
  lex = WordNet::Lexicon.new
  lex[synset_id].traverse(type).with_depth.each do |ss, depth|
    indent = '|' * (depth)
    word_str = ss.senses.map {|s| s.word.lemma }.join(',')
    puts "#{indent}[#{word_str}]#{ss.synsetid}"
  end
end


class SynsetFinder
  def initialize
    @lex = WordNet::Lexicon.new
    @included = Set.new
    @excluded = Set.new
  end

  def add(synsetid, distance)
   traverse(synsetid, distance) do |ss, depth|
    @included << ss.synsetid
    puts "#{depth} Adding: #{ss}"
   end
  end

  def remove(synsetid, distance)
    traverse(synsetid, distance) do |ss, depth|
      if @included.include?(ss.synsetid)
        puts "Removing #{ss} because of a #{depth} degree connection"
        @excluded << ss.synsetid
      end
    end
  end

  def resolve
    (@included - @excluded).map do |synsetid|
      synset = @lex[synsetid]
    end
  end

  def resolve_into_words
    resolve.map {|ss| ss.words.map(&:lemma) }.flatten
  end

  def ss_to_words(ss)
    ss.words.map(&:lemma)
  end

  def traverse(synsetid, max_depth, &block)
    synset = @lex[synsetid]

    traversed = Set.new
    _traverse(@lex[synsetid], traversed, 0, max_depth, block)

    traversed
  end

  def _traverse(synset, traversed, depth, max_depth, fn)
    return if depth > max_depth
    result = fn.call(synset, depth)
    return if not result

    traversed << synset.synsetid

    synset.semlinks.each do |semlink|
      target = semlink.target
      next if traversed.include?(target.synsetid)
      _traverse(target, traversed, depth + 1, max_depth, fn)
    end
  end

  def add_word(word, depth)
    @lex.lookup_synsets(word).each do |ss|
      add(ss.synsetid, depth)
      true
    end
  end

  def remove_word(word, depth)
    @lex.lookup_synsets(word).each do |ss|
      remove(ss.synsetid, depth)
      true
    end
  end

  def lookup(word, depth)
    if word.is_a?(Fixnum)
      synsets = [@lex[word]]
    else
      synsets = @lex.lookup_synsets(word)
    end

    visited = Set.new

    synsets.each do |ss|
      traverse(ss.synsetid, depth) do |ss, _depth|
        if visited.include?(ss.synsetid) || ss.semlinks.length > 50
          false
        else
          visited << ss.synsetid
          puts "#{'  ' * _depth}[#{_depth}] #{ss} -- [#{ss.synsetid}]"
          true
        end
      end
    end
    nil
  end
end

def test1
  finder = SynsetFinder.new
  finder.add(105611302, 2)
  finder.remove(105613794, 3)
  puts finder.resolve
  puts finder.resolve_into_words
end

def test2
  lex = WordNet::Lexicon.new

  finder = SynsetFinder.new
  finder.add(200025654, 2)

  #lex.lookup_synsets('death').each do |ss|
  #  finder.remove(ss.synsetid, 2)
  #end

  puts finder.resolve
  puts finder.resolve_into_words
end

#test2
finder = SynsetFinder.new
require 'pry'; binding.pry
