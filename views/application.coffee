Parse.$ = jQuery

Parse.initialize("applicationId", "javaScriptKey");

window.App = {}

App.Language = Parse.Object.extend("Language", {})
App.Languages = Parse.Collection.extend(
  comparator: (object) -> object.get("name")
)

App.Code = Parse.Object.extend("Code", {})
App.Codes = Parse.Collection.extend({})


class App.LoadingView extends Backbone.View
  template: -> _.template($('#loading').text())

  render: ->
    @$el.html(@template())
    @

class App.SubmitView extends Backbone.View
  template: -> _.template($('#submit-form').text())

  events:
    'submit form': 'submit'
    'fileselect #file': 'selectedFile'

  render: ->
    @$el.html(@template())
    selectEl = @languageSelect()
    @disableButton()
    @collection.forEach (language) ->
      optionEl = $("<option>")
      optionEl.val(language.id)
      optionEl.text(language.get('name'))
      selectEl.append(optionEl)
    @

  selectedFile: (ev, numFiles, label) ->
    @$el.find('.filenames').val(label)
    fileEl = @fileInput().get(0)
    if fileEl.files.length > 0
      file = fileEl.files[0]
      parseFile = new Parse.File('code.zip', file)
      @model.set('zipfile', parseFile)
      @enableButton()

  submit: (ev)->
    ev.preventDefault()
    id = @languageSelect().val()
    language = @collection.get(id)
    @model.set('language', language)
    @model.set('author', @authorSelect().val())

    @disableButton()
    @showSavingLabel()
    @model.save({},
      success: =>
        @showSavedLabel()
        @enableButton()
    )


  authorSelect: ->
    @$el.find('#author')

  languageSelect: ->
    @$el.find('#language')

  fileInput: ->
    @$el.find('#file')

  button: ->
    @$el.find('button')

  disableButton: ->
    @button().attr('disabled','disabled')

  enableButton: ->
    @button().attr('disabled', false)

  showSavingLabel: ->
    @$('.saving-label').removeClass('hidden')
    @$('.saved-label').addClass('hidden')

  showSavedLabel: ->
    @$('.saving-label').addClass('hidden')
    @$('.saved-label').removeClass('hidden')

class Layout
  constructor: ->
    @$el = $('.body')

  show: (view) ->
    @currentView.remove() if @currentView
    @$el.html(view.render().$el)
    @currentView = view

class SubmitController
  constructor: ->
    @languages = new App.Languages()
    @languages.query = new Parse.Query(App.Language);

    @model = new App.Code()

    @languages.fetch(
      success: =>
        view = new App.SubmitView(
          model: @model,
          collection: @languages
        )
        App.layout.show(view)
    )
class App.OnboardingView extends Backbone.View
  template: -> _.template($('#onboarding').text())

  events:
    'submit form': 'submit'

  render: ->
    @$el.html(@template())
    selectEl = @languageSelect()
    @collection.forEach (language) ->
      optionEl = $("<option>")
      optionEl.val(language.id)
      optionEl.text(language.get('name'))
      selectEl.append(optionEl)
    @

  submit: (ev) ->
    ev.preventDefault()
    key = @languageSelect().val()
    lang = _.find(@collection, (c) -> c.id == key)
    console.log(key, lang)
    @trigger('choose', key, lang)

  languageSelect: ->
    @$el.find('#language')

class App.DownloadView extends Backbone.View
  template: -> _.template($('#download').text())

  render: ->
    attributes = @model.attributes
    attributes.language = attributes.language.get('name')
    attributes.fileurl = attributes.zipfile.url()
    @$el.html(@template()(attributes))
    @

class OnboardingController
  constructor: ->
    @codes = new App.Codes()
    @codes.query = new Parse.Query(App.Code);
    @codes.query.include('language')

    @codes.fetch(
      success: @showOnboarding
    )

  showOnboarding: =>
    @languagesToCodes = {}
    @languages = []

    @codes.forEach (code) =>
      lang = code.get('language')
      key = lang.id
      unless key of @languagesToCodes
        @languagesToCodes[key] = []
        @languages.push(lang)

      @languagesToCodes[key].push(code)

    @languages = _.sortBy(@languages, (l) -> l.get('name'))

    view = new App.OnboardingView(
      collection: @languages
    )
    view.on 'choose', (key, lang) =>
      @downloadCode(lang)
    App.layout.show(view)


  downloadCode: (language) ->
    codes = @languagesToCodes[language.id]
    code = _.sample(codes)
    view = new App.DownloadView(
      model: code
    )
    App.layout.show(view)

$(document).on 'ready', ->
  App.layout = new Layout()
  App.layout.show(new App.LoadingView())
  if location.pathname.indexOf("onboarding") > 0
    controller = new OnboardingController()
  else
    controller = new SubmitController()
