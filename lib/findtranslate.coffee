FindtranslateView = require './findtranslate-view'
{CompositeDisposable, Point, Range} = require 'atom'

'WELCOME'

module.exports = Findtranslate =
  subscriptions: null
  options:
    wordRegex: new RegExp("('[A-Z\._]+|[A-Z\._]+')")

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'findtranslate:findEn': => @find('en')
    @subscriptions.add atom.commands.add 'atom-workspace', 'findtranslate:findSv': => @find('sv')

  deactivate: ->
    @subscriptions.dispose()

  find: (lang) ->
    @lang = lang

    texteditor = atom.workspace.getActiveTextEditor()
    console.log texteditor.getTitle()

    if texteditor.getTitle().indexOf('translation-') != -1
      pos = texteditor.getCursorBufferPosition()
      @open(pos)
    else
      @find_selected_words(texteditor)
      if @words && @words.length > 0
        @open()

  find_selected_words: (texteditor) ->
    cursor = texteditor.getLastCursor()
    range = cursor.getCurrentWordBufferRange(@options)

    selection = texteditor.getTextInBufferRange(range)
    if selection && selection.length > 1
      selection = selection.substring(1, selection.length - 1);
      @words = selection.split '.'

  open: (pos) ->
    atom.workspace.open "angular/app/scripts/translation/translations/translation-#{@lang}.js"
    #atom.workspace.open "testtrans.js"
    subscription = atom.workspace.onDidStopChangingActivePaneItem (pane) =>
      @texteditor = atom.workspace.getActiveTextEditor()
      if pos
        @texteditor.setCursorBufferPosition(pos)
      else
        range = @traverse(0, [0, 0], [@texteditor.getLastBufferRow(), 0])
        @select(range)
      subscription.dispose()

  traverse: (index, start, end, range) ->
    isFirst = index == 0
    @texteditor.scanInBufferRange @getRegexp(@words[index], isFirst), new Range(start, end), (match) =>
      match.stop()
      if match
        range = match.range
        if index + 1 < @words.length
          range = @traverse(index+1, match.range.start, end, match.range)
    return range

  select: (range) ->
    @texteditor.setCursorBufferPosition(range.end)
    @texteditor.scrollToCursorPosition()

  getRegexp: (word, isFirst) ->
    if isFirst
      new RegExp "(#{word}:\ \{)" # "SOME_WORD: {"
    else
      new RegExp "(#{word}:)"     # "SOME_WORD:"
