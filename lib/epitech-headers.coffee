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
    template:
      type: 'string'
      default: '%file for %projectName in %path\n\nMade by %owner\nLogin   <%login@epitech.eu>\n\nStarted on  %cdate %creator\nLast update %udate %editor'

  activate: ->
    atom.workspace.eachEditor (editor) =>
      editor.buffer.on 'will-be-saved', =>
       @updateHeader(editor)

    atom.commands.add 'atom-workspace',
      'epitech-headers:insert': =>
        @insert()

  insert: ->
    editor = atom.workspace.getActiveEditor()
    return unless editor?

    @insertHeader(editor)

  update: ->
    @updateHeader(atom.workspace.getActiveEditor())

  getHeaderText: (editor) ->
    editor = atom.workspace.getActiveTextEditor()
    path = editor.getPath()
    tmp = path.split("/")
    fileName = tmp[tmp.length - 1]
    directory = path.split(fileName)[0];
    currentDay = moment().format("DD")
    currentDate = moment().format("ddd MMM " + currentDay.replace('0', ' ') + " hh:mm:ss YYYY")
    text = "#{atom.config.get('epitech-headers.template')}\n"
    text = text.replace('%owner', atom.config.get('epitech-headers.owner'))
    text = text.replace('%creator', atom.config.get('epitech-headers.owner'))
    text = text.replace('%editor', atom.config.get('epitech-headers.owner'))
    text = text.replace('%login', atom.config.get('epitech-headers.login'))
    text = text.replace('%file', fileName)
    text = text.replace('%path', directory)
    text = text.replace('%cdate', currentDate)
    text = text.replace('%udate', currentDate)
    dialog = new Dialog (editor:editor, text:text, onConfirm:@onConfirm)
    dialog.attach()

  onConfirm: (editor, text, projectName, closeCallback) ->
    closeCallback()
    text = text.replace('%projectName', projectName)
    text = "\n" + text + "\n"
    editor.setCursorBufferPosition([0, 0], autoscroll: false)
    editor.insertText(text, select: true)
    editor.toggleLineCommentsInSelection()

    range = editor.getSelectedBufferRange()
    editor.setCursorBufferPosition(range.end)
    editor.insertText("\n")

  hasHeader: (obj) ->
    return @hasHeader(obj.buffer) if obj.buffer?

    @hasHeaderInText(obj.getTextInRange([[0, 0], [10, 0]]))

  hasHeaderInText: (text) ->
    text.match(/.* for .* in .*\n.*\n.*Made by .*\n.*Login   <.*@epitech.eu>.*\n.*\n.*Started on  .*\n.*Last update .*\n/m)

  insertHeader: (editor) ->
    unless @hasHeader(editor)
      @restoreCursor editor, =>
        editor.transact =>
          @getHeaderText(editor)

  updateHeader: (editor) ->
    if @hasHeader(editor)
      editor.scanInBufferRange /Last update .*/, [[0, 0], [10, 0]], ({matchText, replace}) ->
        currentDay = moment().format("DD")
        currentDate = moment().format("ddd MMM " + currentDay.replace('0', ' ') + " hh:mm:ss YYYY")
        replace("Last update " + currentDate + " " + atom.config.get('epitech-headers.owner'))

  multiplyText: (text, count) ->
    Array(count + 1).join(text)

  restoreCursor: (editor, callback) ->
    marker = editor.markBufferPosition(editor.getCursorBufferPosition(), persistent: false)

    callback()

    editor.setCursorBufferPosition(marker.getHeadBufferPosition())
    marker.destroy()

  wrap: (text, buffer) ->
    prebuffer = @multiplyText("\n", buffer)
    postbuffer = @multiplyText("\n", buffer)
    prebuffer + text + postbuffer

module.exports = new EpitechHeaders()
