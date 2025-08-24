module HomeHelper
  def get_badge_color(badge)
    case badge&.downcase
    when 'popular'
      'green'
    when 'new'
      'blue'
    when 'best seller'
      'orange'
    when 'hot'
      'red'
    when 'trending'
      'blue'
    when 'featured'
      'yellow'
    when 'limited time'
      'pink'
    when 'sale'
      'teal'
    else
      'gray'
    end
  end
end
