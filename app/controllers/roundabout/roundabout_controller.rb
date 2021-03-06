# frozen_string_literal: true

require 'roundabout/application_controller'
require 'graphviz'

module Roundabout
  class RoundaboutController < ::Roundabout::ApplicationController
    def index
      if (json = Rails.root.join('tmp/roundabout.json')).exist?
        transitions = ActiveSupport::JSON.decode json.read
        viz = GraphViz.new(:G, type: :digraph, rankdir: 'LR') do |g|
          transitions.each do |t|
            from = g.add_nodes t['from'].sub('#', "\n"), shape: 'box'
            to = g.add_nodes t['to'].sub('#', "\n"), shape: 'box'
            color = case t['type']
            when 'redirect'
              '#484848'
            when 'form'
              '#f83737'
            else
              if t['method'] != 'get'
                '#f83737'
              else
                '#f2cd01'
              end
            end
            g.add_edges from, to, color: color
          end
        end
        respond_to do |format|
          format.png do
            send_data viz.output(png: String), type: 'image/png', disposition: 'inline'
          end
          format.pdf do
            send_data viz.output(pdf: String), type: 'application/pdf', disposition: 'inline'
          end
          format.html do
            graph = GraphViz.parse_string(viz.output(dot: String))
            @nodes = graph.each_node.values
            @edges = graph.each_edge.map {|e| e[:pos].source.split(' ').take(2).map {|s| s.sub(/^e,/, '') }.reverse << e[:color].source << e.node_one << e.node_two }
            @graph_width, @graph_height = graph.graph.data['bb'].to_ruby.last(2)
          end
        end
      else
        render 'readme'
      end
    end
  end
end
