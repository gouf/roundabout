# frozen_string_literal: true

require 'capybara'

module Roundabout
  module Capybara
    module Node
      module Element
        def click(*)
          path_from = session.current_path
          case tag_name
          when 'input'
            type = :form
            begin
              form = ancestor 'form'
              path_to = form[:action]
              method = form[:method]
              begin
                if (hidden = form.first('input[type=hidden][name=_method]', visible: false))
                  method = hidden.value
                end
              rescue ::Capybara::ExpectationNotMet
              end
            rescue ::Capybara::ElementNotFound
            end
          when 'a'
            if (method = self[:'data-method'])
              type = :form
            else
              method = :get
              type = :link
            end
            path_to = self[:href]
          end

          ret = super

          if path_from && path_to && (path_from != path_to)
            begin
              Roundabout.record_transition Roundabout.normalize_url(path_from), Roundabout.normalize_url(path_to, method), method.to_sym, type
            rescue => e
              p e
            end
          end
          ret
        end
      end
    end
  end
end

::Capybara::Node::Element.prepend Roundabout::Capybara::Node::Element
