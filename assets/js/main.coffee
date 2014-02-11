# PhantomJS doesn't support bind yet
require 'functionbind'

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
    document.title = "#{page.get('name')} | C.O.R.E. 2062"

    # ensure that the correct navbar button is selected... since it is a radio
    # button, it unselects anything else
    @$el.find("\##{page.get('slug')}_nav").prop "checked", true
    @$el.find('select').val('#' + page.get('slug'))

    console.log "(nav) page: #{page.get('name')}"

  initialize: =>
    @model.on('change:selected', @render)

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
    console.log "loaded page: #{@get 'name'}"

# this is a view that's connected to the page model... it just deals with
# hiding the content of pages that we are not on, and showing the content of
# the page that we are on
class PageView extends Backbone.View
  tagName: 'section'

  render: =>
    console.log 'render page', @el
    if @model.get('selected')
      @el.style.display = 'block' # show
    else
      @el.style.display = 'none' # hide

  initialize: =>
    @model.on('change:selected', @render)
    @model.view = @

    slug = @model.get('slug')

    @$el.attr(
      id: "#{slug}-content"
      class: @model.get('categories').join('-category ')
    )

    @render()

# this is a collection of all the pages in the application... it deals with
# changing the current page when the url changes
class PagesCollection extends Backbone.Collection
  # to determine what should be rendered in the navbar on any given page
  model: Page
  default_page: 'blog'

  constructor: ->
    super()
    @on("add", @added_page)

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
      console.log "#{page_slug} doesn't exist, redirecting to #{@default_page}"

      router.navigate('!' + @default_page,
        trigger: true
        replace: true
      )

  ###*
   * @return Page the model of the active page
  ###
  current_page: ->
    return @where(selected: true)[0]

#create all the models & views in the application
window.pages = new PagesCollection()
window.router = new Router model: pages
window.navView = new NavView model: pages

blog = pages.create(
  slug: 'blog'
  name: 'Recent News'
)
# bleh, manual render
blog.view.el.innerHTML = """
  <h1>#{blog.get 'name'}</h1>
"""
$('.box.more-posts').before(blog.view.el)

API.cache.posts.on 'add', (model) ->
  blog.view.$el.append(model.view.el)

API.cache.pages.on 'add', (model) ->
  categories = []
  for category in model.get 'categories'
    categories.push category['slug']

  pageModel = pages.create(
    slug: model.get 'slug'
    name: model.get 'title'
    categories: categories
    content: model.get 'content'
  )
  $('.box.more-posts').before(pageModel.view.el)

  # ugh, just manually render
  pageModel.view.el.innerHTML = """
    <h1>#{pageModel.get 'name'}</h1>
    #{pageModel.get 'content'}
  """

  if model.get 'slug' is 'contact'
    #make the contact form work
    form = $('.wpcf7 form')[0]
    $(form).attr('action', API.backendURL + $(form).attr('action'))
    $.wpcf7Init()

MenuView = require './menuview'
API.getMenu('main', (menu) ->
  view = new MenuView(model: menu)
  $('[for="nav-wrapper"]').append view.el
)

API.getPosts()
API.getPages()

Backbone.history.start()

# change to default page at startup (if there is no hash fragment)
if Backbone.history.fragment is ''
  App.Router.navigate('!' + pages.default_page,
    trigger: true
    replace: true
  )
