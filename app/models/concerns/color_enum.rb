module ColorEnum
  extend ActiveSupport::Concern

  included do
    # Color constants with CSS classes for Tailwind (only definitely supported colors)
    AVAILABLE_COLORS = {
      red: { name: 'Red', css_class: 'red' },
      blue: { name: 'Blue', css_class: 'blue' },
      green: { name: 'Green', css_class: 'green' },
      orange: { name: 'Orange', css_class: 'orange' },
      purple: { name: 'Purple', css_class: 'purple' },
      pink: { name: 'Pink', css_class: 'pink' },
      gray: { name: 'Gray', css_class: 'gray' },
      teal: { name: 'Teal', css_class: 'teal' },
      cyan: { name: 'Cyan', css_class: 'cyan' },
      indigo: { name: 'Indigo', css_class: 'indigo' },
      emerald: { name: 'Emerald', css_class: 'emerald' },
      rose: { name: 'Rose', css_class: 'rose' },
      amber: { name: 'Amber', css_class: 'amber' },
      lime: { name: 'Lime', css_class: 'lime' },
      sky: { name: 'Sky', css_class: 'sky' },
      violet: { name: 'Violet', css_class: 'violet' },
      fuchsia: { name: 'Fuchsia', css_class: 'fuchsia' },
      slate: { name: 'Slate', css_class: 'slate' },
      zinc: { name: 'Zinc', css_class: 'zinc' },
      neutral: { name: 'Neutral', css_class: 'neutral' },
      stone: { name: 'Stone', css_class: 'stone' }
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
    end
  end

  # Instance methods
  def css_class_for_color(color_value)
    self.class.css_class_for_color(color_value)
  end

  def name_for_color(color_value)
    self.class.name_for_color(color_value)
  end
end
