class String
  def split_by_last(char=" ")
    pos = self.rindex(char)
    pos != nil ? [self[0...pos], self[pos+1..-1]] : [self]
  end
end