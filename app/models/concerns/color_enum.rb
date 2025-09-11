module ColorEnum
  extend ActiveSupport::Concern

  included do
    # Color constants with CSS classes for Tailwind (only definitely supported colors)
    AVAILABLE_COLORS = {
      red: { name: 'Red', css_class: 'red' },
      blue: { name: 'Blue', css_class: 'blue' },
      green: { name: 'Green', css_class: 'green' },
      orange: { name: 'Orange', css_class: 'orange' },
      gray: { name: 'Gray', css_class: 'gray' },
      indigo: { name: 'Indigo', css_class: 'indigo' }
    }.freeze

    # Class methods
    class << self
      def available_colors
        AVAILABLE_COLORS
      end

      def color_values
        AVAILABLE_COLORS.keys.map(&:to_s)
      end

      def color_names
        AVAILABLE_COLORS.transform_values { |v| v[:name] }
      end

      def css_class_for_color(color_value)
        # Since all colors now have direct Tailwind support, return the color value directly
        color_value.to_s
      end

      def name_for_color(color_value)
        AVAILABLE_COLORS[color_value.to_sym]&.dig(:name) || color_value.humanize
      end

      def safe_color_info(color_value)
        # Return color info if available, otherwise return red as default
        color_value = color_value.to_s if color_value
        if color_value && AVAILABLE_COLORS[color_value.to_sym]
          AVAILABLE_COLORS[color_value.to_sym]
        else
          AVAILABLE_COLORS[:red] # Default to red
        end
      end

      def safe_color_name(color_value)
        # Return color name if available, otherwise return red
        safe_color_info(color_value)[:name]
      end

      def safe_css_class(color_value)
        # Return CSS class if available, otherwise return red
        safe_color_info(color_value)[:css_class]
      end
    end
  end

  # Instance methods
  def css_class_for_color(color_value)
    self.class.css_class_for_color(color_value)
  end

  def name_for_color(color_value)
    self.class.name_for_color(color_value)
  end

  def safe_color_info(color_value)
    self.class.safe_color_info(color_value)
  end

  def safe_color_name(color_value)
    self.class.safe_color_name(color_value)
  end

  def safe_css_class(color_value)
    self.class.safe_css_class(color_value)
  end

  # Convenience methods for current product color
  def safe_current_color_info
    safe_color_info(self.color)
  end

  def safe_current_color_name
    safe_color_name(self.color)
  end

  def safe_current_css_class
    safe_css_class(self.color)
  end
end
