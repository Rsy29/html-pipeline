require "cgi"

begin
  require "gemoji"
rescue LoadError => _
  abort "Missing dependency 'gemoji' for EmojiFilter. See README.md for details."
end

module HTML
  class Pipeline
    # HTML filter that replaces :emoji: with images.
    #
    # Context:
    #   :asset_root (required) - base url to link to emoji sprite
    #   :asset_path (optional) - url path to link to emoji sprite. :file_name can be used as a placeholder for the sprite file name. If no asset_path is set "emoji/:file_name" is used.
    class EmojiFilter < Filter
      # Build a regexp that matches all valid :emoji: names.
      EmojiPattern = /:(#{Emoji.names.map { |name| Regexp.escape(name) }.join('|')}):/

      def call
        doc.search('text()').each do |node|
          content = node.to_html
          next if !content.include?(':')
          next if has_ancestor?(node, %w(pre code))
          html = emoji_image_filter(content)
          next if html == content
          node.replace(html)
        end
        doc
      end
      
      # Implementation of validate hook.
      # Errors should raise exceptions or use an existing validator.
      def validate
        needs :asset_root
      end

      # Replace :emoji: with corresponding images.
      #
      # text - String text to replace :emoji: in.
      #
      # Returns a String with :emoji: replaced with images.
      def emoji_image_filter(text)
        return text unless text.include?(':')

        text.gsub EmojiPattern do |match|
          name = $1
          "<img class='emoji' title=':#{name}:' alt=':#{name}:' src='#{emoji_url(name)}' height='20' width='20' align='absmiddle' />"
        end
      end

      # The base url to link emoji sprites
      #
      # Raises ArgumentError if context option has not been provided.
      # Returns the context's asset_root.
      def asset_root
        context[:asset_root]
      end

      # The url path to link emoji sprites
      #
      # :file_name can be used in the asset_path as a placeholder for the sprite file name. If no asset_path is set in the context "emoji/:file_name" is used.
      # Returns the context's asset_path or the default path if no context asset_path is given.
      def asset_path(name)
        if context[:asset_path]
          context[:asset_path].gsub(":file_name", "#{::CGI.escape(name)}.png")
        else
          File.join("emoji", "#{::CGI.escape(name)}.png")
        end
      end

      private

      def emoji_url(name)
        File.join(asset_root, asset_path(name))
      end
    end
  end
end
