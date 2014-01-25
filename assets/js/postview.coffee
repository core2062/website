Backbone = require 'backbone'

class PostView extends Backbone.View
  tagName: 'section'

  render: ->
    @el.innerHTML = """
      <h2 class="title">#{@model.get 'title'}</h2>
      <p class="post-info">
        Posted on <span class="date">#{@model.get 'date'}</span>
        by <span class="author">#{@model.get('author').get('name')}</span>
      </p>
      #{@model.get 'content'}
    """

  initialize: =>
    @model.view = @

    categories = []
    for category in @model.get('categories')
      categories.push category.get 'slug'
    @$el.attr(
      class: categories.join('-category ')
    )

    @model.on('change', @render)
    @render()

module.exports = PostView
