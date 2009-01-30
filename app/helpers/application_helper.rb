module Merb
  module MerbAdmin
    module ApplicationHelper
      def model_title( obj )
        obj.try(:title) || obj.try(:name) || "#{ obj.class.to_s } ##{ obj.id }"
      end

      def object_link( obj, text = nil )
        <<-EOS
        <a href="#{ object_url( obj ) }">
          #{ text || model_title( obj ) }
        </a>
        EOS
      end

      def object_url( obj )
        slice_url(:model, obj.type.to_s.snake_case, 'show', obj.id)
      end

      def print_pages
        page  = params[:page].to_i
        pages = (1..3).to_a + (page-2..page+2).to_a + (@model.pages.last.number-2..@model.pages.last.number).to_a
        pages = pages.select{ |p| p > 0 && p <= @model.pages.number_of_pages }.uniq.sort
        prev  = 0
        out   = '<ul class="horizontal unlist pages"><li>Page:</li>'
        for p in pages
          out += '<li>&hellip;</li>' if prev+1 != p
          out += '<li><a href="?page=%s">%s</a></li>' % [p,p]
          prev = p
        end
        out += '</ul>'
        out
      end

      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def image_path(*segments)
        public_path_for(:image, *segments)
      end
      
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def javascript_path(*segments)
        public_path_for(:javascript, *segments)
      end
      
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def stylesheet_path(*segments)
        public_path_for(:stylesheet, *segments)
      end
      
      # Construct a path relative to the public directory
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def public_path_for(type, *segments)
        ::MerbAdmin.public_path_for(type, *segments)
      end
      
      # Construct an app-level path.
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path within the host application, with added segments.
      def app_path_for(type, *segments)
        ::MerbAdmin.app_path_for(type, *segments)
      end
      
      # Construct a slice-level path.
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path within the slice source (Gem), with added segments.
      def slice_path_for(type, *segments)
        ::MerbAdmin.slice_path_for(type, *segments)
      end
      
    end
  end
end