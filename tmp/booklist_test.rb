require_relative 'book'
require_relative 'book_list'

booklist = BookList.new

b1 = Book.new("iPod玩拆解", "三浦一则")
b2 = Book.new("How Objects Work", "平泽章")
b3 = Book.new("How Work", "高桥")

booklist.add(b1)
booklist.add(b2)
booklist.add(b3)

print booklist[0].title, "\n"
print booklist[1].title, "\n"

booklist.each { |book|
  print book.title, "\n"
}

booklist.each_title do |title|
  print title, "\n"
end

booklist.each_title_author do |title, author|
  print "『", title, "』", author, "\n"
end
print "#############\n"
booklist.find_by_author(/高桥/) do |book|
  print book.title, "\n"
end
print "#############\n"
result = booklist.find_by_author(/高桥/)
result.each do |book|
  print book.author, "\n"
end