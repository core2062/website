Backbone = require 'backbone'

class MenuView extends Backbone.View
  tagName: 'ul'
  className: 'menu'

  render: ->
    for item in @model.where('is_root_level': true)
      @$el.append @renderMenuItem item, 0

  renderMenuItem: (item, depth) ->
    id = item.get 'ID'
    output = """
      <li>
        <a href="#{item.get 'url'}">#{item.get 'title'}</a>
        <input id="#{id}_nav" type="radio" name="group-#{depth}">
    """
    children = item.get('children')
    if children.length
      output += """
        <label for="#{id}_nav">▼</label>
        <div>
          <input id="close-#{depth}" type="radio" name="group-#{depth}">
          <label for="close-#{depth}">▲</label>
        </div>
        <ul>
      """
      for child in children
        output += @renderMenuItem child, depth + 1
      output += '</ul>'

    output += '</li>'
    return output

  initialize: =>
    @model.view = @
    @model.on('change', @render)
    @render()

module.exports = MenuView
