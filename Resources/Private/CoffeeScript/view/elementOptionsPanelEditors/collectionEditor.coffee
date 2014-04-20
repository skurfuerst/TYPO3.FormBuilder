# <!--
# This script belongs to the FLOW3 package "TYPO3.FormBuilder".
#
# It is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License, either version 3
#  of the License, or (at your option) any later version.
#
# The TYPO3 project - inspiring people to share!
# -->


# #Namespace `TYPO3.FormBuilder.View.ElementOptionsPanel.Editor`#
#
# This file contains a generic collection editor, which is used as common
# base class for Validator and Finisher editors.
#
# **Internal**.

# ## Class AbstractCollectionEditor
#
TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractCollectionEditor = TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.AbstractPropertyEditor.extend {
	# ###Public Properties###
	# * `availableCollectionElements`: JSON object of available sub elements, where each element has the following options:
	#
	#    * `label`: human-readable label of the validator
	#    * `sorting`: sorting index to be used for the validator
	#    * `name`: Validator class name, if not specified the `TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor` is used.
	#    * `options`: Validator options to be set (JSON object)
	#    * `required`: (boolean) if TRUE; it is required validator which is not de-selectable
	availableCollectionElements: null,


	# ***
	# ###Private###
	defaultValue: (-> []).property().cacheable()

	# we only show the validators view if there are validators available or already shown
	isVisible: (->
		collectionElementsAvailable = !@get('noCollectionElementsAvailable')
		collectionEditorViewsFound = @get('collectionEditorViews').length > 0
		return collectionElementsAvailable or collectionEditorViewsFound
	).property('collectionEditorViews', 'noCollectionElementsAvailable').cacheable()

	# list of initialized views, one for each collection editor
	collectionEditorViews: null

	prompt: Ember.required()

	# initializer.
	init: ->
		@_super()
		@set('collectionEditorViews', [])

		@updateCollectionEditorViews()

	# sort the available collection elements based on their sorting property
	sortedAvailableCollectionElements: (->
		sortedCollectionElements = []
		for identifier, collectionElementTemplate of @get('availableCollectionElements')
			continue if @isCollectionElementTemplateFoundInCollection(identifier)
			sortedCollectionElements.push($.extend({identifier}, collectionElementTemplate))

		sortedCollectionElements.sort((a, b) -> a.sorting - b.sorting)
		return sortedCollectionElements
	).property('availableCollectionElements', 'formElement.__nestedPropertyChange').cacheable()

	# if TRUE, no collection elements are available.
	noCollectionElementsAvailable: ( ->
		@get('sortedAvailableCollectionElements').length == 0
	).property('sortedAvailableCollectionElements').cacheable()

	# this property needs to be bound to the current selection, of the "collection element"
	# select field, such that we can observe this value for changes.
	addCollectionElementSelection: null

	# helper function which adds a new collection element
	addCollectionElement: (->
		collectionElementToBeAdded = @get('addCollectionElementSelection')
		return unless collectionElementToBeAdded

		@get('value').push {
			identifier: collectionElementToBeAdded.identifier
			options: collectionElementToBeAdded.options || {}
		}

		@updateCollectionEditorViews()
		@valueChanged()

		if jQuery.browser.msie
			# HACK for IE8: Somehow, it seems that IE8 messes up the select
			# dropdown ("Select a validator / finisher to add..."), adding
			# sometimes double entries etc.
			# Thus, we have to redraw the *complete* dropdown.
			window.setTimeout(=>
				viewId = @$().find('.typo3-formbuilder-addFinisher select, .typo3-formbuilder-addValidator select').attr('id')
				Ember.View.views[viewId].rerender()
			, 100)

		# reset the "addCollectionElement" dropdown
		@set('addCollectionElementSelection', null)
	).observes('addCollectionElementSelection')

	# helper function which updates the collection editor views.
	updateCollectionEditorViews: (->
		@addRequiredCollectionElementsIfNeeded()

		collection = @get('value')

		availableCollectionElements = @get('availableCollectionElements')
		return unless availableCollectionElements

		collectionEditorViews = []

		for collectionElement, i in collection
			collectionElementTemplate = availableCollectionElements[collectionElement.identifier]
			continue if !collectionElementTemplate # not every collection element has view settings (f.e. NotEmpty validator)

			# we found the correct collectionElementTemplate for the current collectionElement
			# thus we can output label and determine the view to be used.
			collectionElementEditor = Ember.getPath(collectionElementTemplate.viewName || 'TYPO3.FormBuilder.View.ElementOptionsPanel.Editor.ValidatorEditor.DefaultValidatorEditor')
			throw "Collection Editor class '#{collectionElementTemplate.viewName}' not found" if !collectionElementEditor
			collectionElementEditorOptions = $.extend({
				attributeBindings: ['elementIndex']
				elementIndex: i
				valueChanged: =>
					@valueChanged()
				updateCollectionEditorViews: =>
					@updateCollectionEditorViews()
				collection: @get('value')
			}, collectionElementTemplate)
			collectionEditorViews.push(collectionElementEditor.create(collectionElementEditorOptions))

		@set('collectionEditorViews', collectionEditorViews)
	).observes('value', 'availableCollectionElements')

	# add the required collection elements if needed to the collection
	addRequiredCollectionElementsIfNeeded: ->
		collection = @get('value')
		availableCollectionElements = @get('availableCollectionElements')

		requiredAndMissingCollectionElements = []

		for identifier, availableCollectionElementTemplate of availableCollectionElements
			continue unless availableCollectionElementTemplate.required # continue if current element is not required
			if !@isCollectionElementTemplateFoundInCollection(identifier)
				requiredAndMissingCollectionElements.push(identifier)

		for collectionElementName in requiredAndMissingCollectionElements
			collection.push({
				identifier: collectionElementName
				options: $.extend({}, availableCollectionElements[collectionElementName].options)
			})

	# is a collection element template found in the list of validators?
	isCollectionElementTemplateFoundInCollection: (collectionElementTemplateIdentifier) ->
		collection = @get('value')
		for collectionElement in collection
			if collectionElementTemplateIdentifier == collectionElement.identifier
				return true

		return false

}