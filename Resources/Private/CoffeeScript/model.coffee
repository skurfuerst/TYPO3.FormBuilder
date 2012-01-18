TYPO3.FormBuilder.Model = {};

TYPO3.FormBuilder.Model.AvailableFormElements = Ember.ArrayController.create()



TYPO3.FormBuilder.Model.Renderable = Ember.Object.extend {

	parentRenderable: null,

	renderables: null,

	# You can observe this property to be notified every time a nested property changes.
	# Do not rely on the value of this property, though!
	__nestedPropertyChange: 0,

	init: ->
		@renderables = []
		@renderables.addArrayObserver(this)

	somePropertyChanged: (theInstance, propertyName) ->
		@set('__nestedPropertyChange', @get('__nestedPropertyChange') + 1);

		if (@parentRenderable)
			@parentRenderable.somePropertyChanged(@parentRenderable, "renderables.#{ @parentRenderable.get('renderables').indexOf(this) }.#{ propertyName }")

	arrayWillChange: (subArray, startIndex, removeCount, addCount) ->
		for i in [startIndex...startIndex+removeCount]
			subArray.objectAt(i).set('parentRenderable', null);

	arrayDidChange: (subArray, startIndex, removeCount, addCount) ->
		for i in [startIndex...startIndex+addCount]
			subArray.objectAt(i).set('parentRenderable', this);

		@set('__nestedPropertyChange', @get('__nestedPropertyChange') + 1);
		if (@parentRenderable)
			@parentRenderable.somePropertyChanged(@parentRenderable, "renderables")

	_path: (->
		if @parentRenderable
			"#{@parentRenderable.get('_path')}.renderables.#{@parentRenderable.get('renderables').indexOf(this)}"
		else
			''
	).property()
}

TYPO3.FormBuilder.Model.Renderable.reopenClass {
	create: (obj) ->
		childRenderables = obj.renderables
		delete obj.renderables

		renderable = Ember.Object.create.call(TYPO3.FormBuilder.Model.Renderable, obj)

		for k,v of obj
			renderable.addObserver(k, renderable, 'somePropertyChanged')

		if (childRenderables)
			for childRenderable in childRenderables
				renderable.get('renderables').pushObject(TYPO3.FormBuilder.Model.Renderable.create(childRenderable))

		return renderable
}

TYPO3.FormBuilder.Model.FormElementType = Ember.Object.extend {
	_isCompositeRenderable: false
}
TYPO3.FormBuilder.Model.FormElementTypes = Ember.Object.create {
	init: ->
		for typeName, typeConfiguration of TYPO3.FormBuilder.Configuration.formElementTypes
			@set(typeName, TYPO3.FormBuilder.Model.FormElementType.create(typeConfiguration))
}

TYPO3.FormBuilder.Model.Form = Ember.Object.create {
	formDefinition: null,
	currentlySelectedRenderable: null
}


#TYPO3.FormBuilder.Model.FormDefinition = TYPO3.FormBuilder.Model.Renderable.create {
#	registerEventHandlersWhenPagesChange: (->
#		console.log("pages change")
#		@get('pages')?.addArrayObserver(this)
#
#	).observes('pages')
#	arrayWillChange: (subArray, startIndex, removeCount, addCount) ->
#		# NOP
#	arrayDidChange: (subArray, startIndex, removeCount, addCount) ->
#		console.log("Sub-array did change", arguments)
#}