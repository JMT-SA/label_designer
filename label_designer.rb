require 'roda'
require 'crossbeams/label_designer'

Crossbeams::LabelDesigner::Config.configure do |config| # Set up configuration for label designer gem.
  config.json_load_path = '/load_label'
end

class LabelDesigner < Roda
  plugin :render
  plugin :assets, css: 'style.scss'
  plugin :public # serve assets from public folder.
  plugin :content_for, append: true
  plugin :indifferent_params

  route do |r|
    r.assets unless ENV['RACK_ENV'] == 'production'

    r.public

    r.root do
      view('home')
    end

    r.on 'label_designer' do
      r.is do
        view(inline: label_designer_page)
      end

      r.on :id do |id|
        view(inline: label_designer_page(id))
      end
    end
  end

  def label_designer_page(file_name = nil)
    page = Crossbeams::LabelDesigner::Page.new(file_name)
    # page.json_load_path = '/load_label_via_json' # Override config just before use.
    html = page.render
    css  = page.css
    js   = page.javascript

    <<-EOC
    #{html}
    <% content_for :late_style do %>
      #{css}
    <% end %>
    <% content_for :late_javascript do %>
      #{js}
    <% end %>
    EOC
  end
end
