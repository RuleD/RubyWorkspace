require_relative 'book_list'
class BookList
  include Enumerable
  def each
    @booklist.each do |book|
      yield(book)
    end
  end
end