{$, TextEditorView, View} = require 'atom-space-pen-views'

module.exports =
class Dialog extends View
  constructor: ({editor, text, onConfirm} = {}) ->
    @editor = editor
    @text = text
    @onConfirm = onConfirm
    super

  @content: () ->
    @div class: 'tree-view-dialog', =>
      @label "Enter project name:", class: 'icon', outlet: 'promptText'
      @subview 'miniEditor', new TextEditorView(mini: true)
      @div class: 'error-message', outlet: 'errorMessage'

  initialize: () ->
    atom.commands.add @element,
      'core:confirm': => @onConfirm(@editor, @text, @miniEditor.getText(), @close)
      'core:cancel': => @cancel()
    @miniEditor.on 'blur', => @close()
    @miniEditor.getModel().onDidChange => @showError()

  attach: (onSuccess) ->
    @panel = atom.workspace.addModalPanel(item: this.element)
    @miniEditor.focus()
    @miniEditor.getModel().scrollToCursorPosition()

  close: ->
    panelToDestroy = @panel
    @panel = null
    panelToDestroy?.destroy()
    atom.workspace.getActivePane().activate()

  cancel: ->
    @close()
    $('.tree-view').focus()

  showError: (message='') ->
    @errorMessage.text(message)
    @flashError() if message
