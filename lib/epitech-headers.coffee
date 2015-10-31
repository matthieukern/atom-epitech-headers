moment = require 'moment'
Dialog = require './dialog'

class EpitechHeaders
  config:
    owner:
      type: 'string'
      default: 'John Doe'
    login:
      type: 'string'
      default: 'login_x'
    domain:
      type: 'string'
      default: 'epitech.eu'

  activate: ->
    atom.workspace.observeTextEditors (editor) =>
      editor.getBuffer().onWillSave(() => @updateHeader(editor))

    atom.commands.add 'atom-workspace',
      'epitech-headers:insert': =>
        @insert()

  insert: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    if editor.getPath()
      @insertHeader(editor)
    else
      atom.confirm
        message: "Please save your file first."
        detailedMessage: ""
        buttons:
          Ok: ->

  update: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor
    @updateHeader(editor)

  getHeaderText: (editor) ->
    editor = atom.workspace.getActiveTextEditor()
    path = editor.getPath()
    tmp = path.split("/")
    fileName = tmp[tmp.length - 1]
    directory = path.split(fileName)[0];
    currentDay = moment().format("DD")
    currentDate = moment().format("ddd MMM " + currentDay.replace('0', ' ').replace('1 ', '10').replace('2 ', '20').replace('3 ', '30') + " HH:mm:ss YYYY")
    text = "%file for %projectName in %path\n\nMade by %owner\nLogin   <%login@%domain>\n\nStarted on  %cdate %creator\nLast update %udate %editor"
    text = text.replace('%owner', atom.config.get('epitech-headers.owner'))
    text = text.replace('%creator', atom.config.get('epitech-headers.owner'))
    text = text.replace('%editor', atom.config.get('epitech-headers.owner'))
    text = text.replace('%login', atom.config.get('epitech-headers.login'))
    text = text.replace('%domain', atom.config.get('epitech-headers.domain'))
    text = text.replace('%file', fileName)
    text = text.replace('%path', directory)
    text = text.replace('%cdate', currentDate)
    text = text.replace('%udate', currentDate)
    dialog = new Dialog (editor:editor, text:text, onConfirm:@onConfirm)
    dialog.attach()

  onConfirm: (editor, text, projectName, closeCallback) ->
    closeCallback()
    text = text.replace('%projectName', projectName)
    editor.setCursorBufferPosition([0, 0], autoscroll: false)
    if text.match(/.*\.[ch] for.*/)
      text = "/*\n" + text
      text = text.replace(/\n/g, "\n** ")
      text = text + "\n*/"
      editor.insertText(text, select: true)
    else if text.match(/.*Makefile for.*/)
      text = "##\n" + text
      text = text.replace(/\n/g, "\n## ")
      text = text + "\n##"
      editor.insertText(text, select: true)
    else
      text = "\n" + text + "\n\n"
      editor.insertText(text, select: true)
      editor.toggleLineCommentsInSelection()

    range = editor.getSelectedBufferRange()
    editor.setCursorBufferPosition(range.end)
    editor.insertText("\n")

  hasHeader: (obj) ->
    return @hasHeader(obj.buffer) if obj.buffer?

    @hasHeaderInText(obj.getTextInRange([[0, 0], [10, 0]]))

  hasHeaderInText: (text) ->
    text.match(/.* for .* in.*\r?\n.*\r?\n.*Made by .*\r?\n.*Login   <.*@.*>.*\r?\n.*\r?\n.*Started on  .*\r?\n.*Last update .*\r?\n/m)

  insertHeader: (editor) ->
    unless @hasHeader(editor)
      @restoreCursor editor, =>
        editor.transact =>
          @getHeaderText(editor)

  updateHeader: (editor) ->
    return unless editor.isModified()

    if @hasHeader(editor)
      editor.scanInBufferRange /Last update .*/, [[0, 0], [10, 0]], ({matchText, replace}) ->
        currentDay = moment().format("DD")
        currentDate = moment().format("ddd MMM " + currentDay.replace('0', ' ').replace('1 ', '10').replace('2 ', '20').replace('3 ', '30') + " HH:mm:ss YYYY")
        replace("Last update " + currentDate + " " + atom.config.get('epitech-headers.owner'))

  restoreCursor: (editor, callback) ->
    marker = editor.markBufferPosition(editor.getCursorBufferPosition(), persistent: false)

    callback()

    editor.setCursorBufferPosition(marker.getHeadBufferPosition())
    marker.destroy()

module.exports = new EpitechHeaders()
