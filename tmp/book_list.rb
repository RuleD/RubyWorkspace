require_relative 'book'
class BookList
  ##初始化
  def initialize
    @booklist = Array.new
  end
  ##新增书籍
  def add(book)
    @booklist.push(book)
  end
  ##返回书籍数量
  def length()
    @booklist.length
  end
  ##将第n本书改成其他书籍
  def []=(n,book)
    @booklist[n]=book
  end
  ##返回第n本书
  def [](n)
    @booklist[n]
  end
  ##从列表中删除书籍
  def delete(book)
    @booklist.delete(book)
  end

  def each
    @booklist.each{|book|
      yield(book)
    }
  end

  def each_title
    @booklist.each do |book|
      yield(book.title)
    end
  end

  def each_title_author
    @booklist.each do |book|
      yield(book.title, book.author)
    end
  end

  # def find_by_author(author)
  #   @booklist.each do |book|
  #     if author =~ book.author
  #       yield(book)
  #     end
  #   end
  # end

  def find_by_author(author)
    if block_given?
      @booklist.each do |book|
        if author =~ book.author
          yield(book)
        end
      end
    else
      result=[]
      @booklist.each do |book|
        if author =~ book.author
          result << book
        end
      end
      return result
    end
  end
end