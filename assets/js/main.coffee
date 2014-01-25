# PhantomJS doesn't support bind yet
require 'functionbind'

p = (args...) ->
  console.log args...

window.$ = require 'jquery'
_ = require 'underscore'
Backbone = require 'backbone'
jsonp = require 'jsonp'

# these only need to be called... no init
require './flying-focus'
require './jquery.fancybox'
require './jquery.form'
require './contact-form'

# if a menu item doesn't have any children, we need this to prevent the arrow
# from being there
$('.menu li:not(:has(ul))').addClass 'no-children'

require './jquery.slicebox'
$('.sb-slider').slicebox(
  orientation: 'r'
  cuboidsRandom: true
  autoplay: true
  sequentialFactor: 200
)

require './jquery.hypher'
$('p').hyphenate 'en-us'

### Twitter Broke its API
require './jquery.tweet'
jQuery(function($){
  $("#twitter_box div").tweet({
    username: "core2062",
    count: 5,
    loading_text: "loading tweets..."
  });
});
###

WordPress = require './wordpress'
window.API = new WordPress('http://core2062.com')

PostView = require './postview'
API.cache.posts.on 'add', (model) ->
  #used to create the view for a post after it has been added
  new PostView(model: model)

window._wpcf7 =
  loaderUrl: API.backendURL + '/wp-content/plugins/contact-form-7/images/ajax-loader.gif',
  sending: "Sending ..."

###*
 * modify the navbar to highlight the correct current page.
 * this view just manages the navbar at the top of the page
###
class NavView extends Backbone.View
  el: $('nav')[0] # element already exists in markup

  render: =>
    page = @model.current_page()

    # set the title of the page
    document.title = "#{page.get('name')} | Chaz Southard"

    # ensure that the correct navbar button is selected... since it is
    # a radio button, it unselects anything else
    @$el.find("\##{page.get('slug')}_nav").prop "checked", true
    @$el.find('select').val('#' + page.get('slug'))

    p "(nav) page: #{page.get('name')}"

  added_page: (page_model) =>
    name = page_model.get('name')
    slug = page_model.get('slug')

    @$el.find('.buttonset').append("""
      <input type="radio" name="nav" value="#{slug}", id="#{slug}_nav")>
      <label for="#{slug}_nav">
        <a href="#!#{slug}">#{name}</a>
      </label>
    """)

    @$el.find('select').append("""
      <option value="##{slug}">#{name}</option>
    """)

  initialize: =>
    @model.on('change:selected', @render)
    @model.on('add', @added_page)


# the router makes the backbuttons work (since we're not really going to
# another page, we are just loading new content for the page we are on). also
# it deals with firing events when the url hash is changed
class Router extends Backbone.Router
  # forward changes in the route to the navigation view
  routes:
    "*page": "change_page"

  change_page: (page) ->
    if page? and page[0] is '!' then page = page[1..]
    if page isnt "" then @model.change_page(page)

  initialize: (options) ->
    # assign a model during init like in a view
    @model = options.model

# this is a model that represents a single page... it's basically just used to
# hold the slug, name, and if it is selected or not
class Page extends Backbone.Model
  defaults:
    name: ''
    slug: ''
    selected: false # value used by Pages for changing the active page
    categories: []
    content: ''

  # represents a page in the application
  sync: ->
    false # changes to Pages don't get stored anywhere

  initialize: =>
    @on('change:selected', @onchange)
    p "loaded page: #{@get 'name'}"

# this is a view that's connected to the page model... it just deals with
# hiding the content of pages that we are not on, and showing the content of
# the page that we are on
class PageView extends Backbone.View
  tagName: 'section'

  render: =>
    if @model.get('selected')
      @el.style.display = 'block' # show
    else
      @el.style.display = 'none' # hide

  #updateContent: =>
  #  @el.innerHTML = @model.get 'content'

  initialize: =>
    #@model.on('change:content', @updateContent)
    @model.on('change:selected', @render)
    @model.view = @

    slug = @model.get('slug')
    
    @$el.attr(
      id: "#{slug}-content"
      class: @model.get('categories').join('-category ')
    )

    @render()
    #@updateContent()

# this is a collection of all the pages in the application... it deals with
# changing the current page when the url changes
class PagesCollection extends Backbone.Collection
  # to determine what should be rendered in the navbar on any given page
  model: Page
  default_page: 'blog'

  added_page: (page_model) ->
    #used to create the view for a page after it has been added
    new PageView({model: page_model})

  change_page: (page_slug) ->
    # update the active page. this should only be called by the router
    page = @find(
      (page_obj) ->
        return page_obj.get('slug') is page_slug
    )

    try
      # deselect the current page (if it's set)
      @current_page().set(selected: false)

    if page?
      page.set(selected: true)
    else
      p "#{page_slug} doesn't exist, redirecting to #{@default_page}"

      router.navigate('!' + @default_page,
        trigger: true
        replace: true
      )

  ###*
   * @return Page the model of the active page
  ###
  current_page: ->
    return @where(selected: true)[0]

  initialize: =>
    @on("add", @added_page)

#create all the models & views in the application
window.pages = new PagesCollection()
window.router = new Router model: pages
window.navView = new NavView model: pages

###*
 * holds all the attachments that we find when adding pages. later used to add
   captions and titles n' stuff to the images because a lot of that isn't
   avaliable in the outputted html
 * all the keys are urls, so it's easy to lookup based on the images
 * @type {Object}
###
window.attachment_index = {}

blog = pages.create(
  slug: 'blog'
  name: 'Recent News'
)
$('.titleblock').after(blog.view.el)

API.cache.posts.on 'add', (model) ->
  blog.view.$el.append(model.view.el)

# get the 10 most recent posts
API.getPosts()

API.request 'get_page_index', {}, (err, data) ->
  # loop through the pages
  for page in data['pages']
    categories = []
    for category in page['categories']
      categories.push category['slug']
  
    pageModel = pages.create(
      slug: page['slug']
      name: page['title']
      categories: categories
      content: page['content']
    )
    $('.titleblock').after(pageModel.view.el)

  $('#loading').remove()

  Backbone.history.start()
  
  # change to default page at startup (if there is no hash fragment)
  if Backbone.history.fragment is ''
    App.Router.navigate('!' + pages.default_page,
      trigger: true
      replace: true
    )

  #make the contact form work
  form = $('.wpcf7 form')[0]
  $(form).attr('action', API.backendURL + $(form).attr('action'))
  $.wpcf7Init()

  p 'all loaded'
  window.prerenderReady = true

$("nav select").change( ->
  window.location = $(@).find("option:selected").val()
)
