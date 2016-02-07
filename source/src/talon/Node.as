package talon
{
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;

	import talon.layout.Layout;
	import talon.utils.Accessor;
	import talon.utils.AccessorGauge;
	import talon.utils.Trigger;

	/** Any attribute changed. */
	[Event(name="change")]
	/** Property 'bounds' changed. */
	[Event(name="resize")]
	/** Added to parent node. */
	[Event(name="added")]
	/** Removed from parent node. */
	[Event(name="removed")]

	public final class Node
	{
		//
		// Private properties
		//
		private var _attributes:Dictionary = new Dictionary();
		private var _accessor:Accessor;
		private var _style:StyleSheet;
		private var _resources:Object;
		private var _parent:Node;
		private var _children:Vector.<Node> = new Vector.<Node>();
		private var _bounds:Rectangle = new Rectangle();
		private var _triggers:Dictionary = new Dictionary();
		private var _ppdp:Number;
		private var _ppmm:Number;
		private var _invalidated:Boolean;

		/** @private */
		public function Node():void
		{
			_ppdp = 1;
			_ppmm = Capabilities.screenDPI / 25.4; // 25.4mm in 1 inch
			_invalidated = true;

			// Initialize all inheritable & composite attributes (initialize theirs listeners)
			var attributeName:String;
			for each (attributeName in Attribute.getInheritableAttributeNames()) getOrCreateAttribute(attributeName);
			for each (attributeName in Attribute.getCompositeAttributeNames())   getOrCreateAttribute(attributeName);

			// Listen attribute change
			addTriggerListener(Event.CHANGE, onSelfAttributeChange);

			// Setup width/height layout callbacks
			_accessor = new Accessor(this);
			_accessor.width.auto = measureAutoWidth;
			_accessor.height.auto = measureAutoHeight;
			_accessor.states.change.addListener(restyle);
			_accessor.classes.change.addListener(restyle);
		}

		//
		// Attributes
		//
		/** Set of often used strong-typed attributes accessors. */
		public function get accessor():Accessor { return _accessor; }

		/** Get attribute <strong>cached</strong> value. */
		public function getAttributeCache(name:String):* { return getOrCreateAttribute(name).valueCache; }

		/** Set attribute string <strong>setted</strong> value. */
		public function setAttribute(name:String, value:String):void { getOrCreateAttribute(name).setted = value; }

		/** @private Get (create if doesn't exists) attribute. */
		public function getOrCreateAttribute(name:String):Attribute
		{
			var result:Attribute = _attributes[name];
			if (result == null)
			{
				result = _attributes[name] = new Attribute(this, name);
				result.change.addListener(onAttributeChange);
			}

			return result;
		}

		private function onAttributeChange(attribute:Attribute):void
		{
			dispatch(Event.CHANGE, attribute)
		}

		//
		// Styling
		//
		public function setStyleSheet(style:StyleSheet):void
		{
			_style = style;
			restyle();
		}

		public function getStyle(node:Node):Object
		{
			if (_style == null && _parent != null) return _parent.getStyle(node);
			if (_style != null && _parent == null) return _style.getStyle(node);
			if (_style != null && _parent != null) return _style.getStyle(node, _parent.getStyle(node));
			return new Object();
		}

		/** Recursive apply style to current node. */
		private function restyle():void
		{
			var style:Object = getStyle(this);

			// Fill all the existing attributes
			for each (var attribute:Attribute in _attributes)
			{
				attribute.styled = style[attribute.name];
				delete style[attribute.name];
			}

			// Addition attributes defined by style
			for (var name:String in style)
			{
				attribute = getOrCreateAttribute(name);
				attribute.styled = style[name];
			}

			// Recursive children restyling
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:Node = getChildAt(i);
				child.restyle();
			}
		}

		//
		// Resource
		//
		/** Set current node resources (an object containing key-value pairs). */
		public function setResources(resources:Object):void
		{
			_resources = resources;
			resource();
		}

		/** Find resource in self or ancestors resources. */
		public function getResource(key:String):*
		{
			if (key == null) return null;
			// Find self resource
			if (_resources && _resources[key]) return _resources[key];
			// Find inherited resource
			if (_parent) return _parent.getResource(key);
			// Not found
			return null;
		}

		private function resource():void
		{
			// Notify resource change
			for each (var attribute:Attribute in _attributes)
				if (attribute.isResource) attribute.dispatchChange();

			// Recursive children notify resource change
			for (var i:int = 0; i < numChildren; i++)
				getChildAt(i).resource();
		}

		//
		// Layout
		//
		public function get isInvalidated():Boolean
		{
			return _invalidated;
		}

		/** Raise (only!) isInvalidated flag. */
		public function invalidate():void
		{
			if (_invalidated === false)
			{
				_invalidated = true;
				dispatch(Event.CHANGE);
			}
		}

		/** Commit node bounds (and validate node layout):
		 *
		 *  - Apply 'bounds' via dispatch RESIZE event.
		 *  - Arrange children with layout algorithm.
		 *  - Reset isInvalidated flag.
		 *
		 *  Call this method after manually change 'bounds' property to validate layout.
		 *  NB! Node layout will be validated independently isInvalidated flag is true or false. */
		public function commit():void
		{
			// Update self view object attached to node
			dispatch(Event.RESIZE);

			// Update children nodes
			layout.arrange(this, bounds.width, bounds.height);

			// Check validation complete
			_invalidated = false;
		}

		/** Actual node bounds in pixels. */
		public function get bounds():Rectangle { return _bounds; }

		/** Pixel per density-independent point (in Starling also known as content scale factor [csf]). */
		public function get ppdp():Number { return _ppdp; }

		/** @private */
		public function set ppdp(value:Number):void { _ppdp = value; }

		/** Pixels per millimeter (in current node). */
		public function get ppmm():Number { return _ppmm; }

		/** @private */
		public function set ppmm(value:Number):void { _ppmm = value; }

		/** Current node 'fontSize' expressed in pixels.*/
		public function get ppem():Number
		{
			// TODO: Optimize calculation (bubbling ppem method call is poor)
			var base:int = 12;
			var inherit:Number = parent ? parent.ppem : base;
			var attribute:Attribute = getOrCreateAttribute(Attribute.FONT_SIZE);
			if (attribute.isInheritable && attribute.basic == Attribute.INHERIT) return inherit;
			return AccessorGauge.toPixels(attribute.basic, ppmm, inherit, ppdp, inherit, 0, 0, 0);
		}

		/** This is default 'auto' callback for gauges: width, minWidth, maxWidth. */
		private function measureAutoWidth(height:Number):Number
		{
			return layout.measureAutoWidth(this, height);
		}

		/** This is default 'auto' callback for gauges: height, minHeight, maxHeight. */
		private function measureAutoHeight(width:Number):Number
		{
			return layout.measureAutoHeight(this, width);
		}

		/** Node layout strategy class. */
		private function get layout():Layout
		{
			var layoutAlias:String = getAttributeCache(Attribute.LAYOUT);
			return Layout.getLayoutByAlias(layoutAlias);
		}

		private function onSelfAttributeChange(attribute:Attribute):void
		{
			if (attribute == null) return;
			var layoutName:String = getAttributeCache(Attribute.LAYOUT);
			var layoutInvalidated:Boolean = Layout.isObservableSelfAttribute(layoutName, attribute.name);
			if (layoutInvalidated) invalidate();
		}

		private function onChildAttributeChange(attribute:Attribute):void
		{
			if (attribute == null) return;
			var layoutName:String = getAttributeCache(Attribute.LAYOUT);
			var layoutInvalidated:Boolean = Layout.isObservableChildAttribute(layoutName, attribute.name);
			if (layoutInvalidated) invalidate();
		}

		//
		// Complex pattern
		//
		/** The node that contains this node. */
		public function get parent():Node { return _parent; }

		/** The number of children of this node. */
		public function get numChildren():int { return _children.length; }

		/** Adds a child to the container. */
		public function addChild(child:Node):void
		{
			_children[_children.length] = child;
			child._parent = this;
            child.restyle();
            child.resource();
			child.addTriggerListener(Event.CHANGE, onChildAttributeChange);
			child.dispatch(Event.ADDED);
            invalidate();
		}

		/** Removes a child from the container. If the object is not a child throws ArgumentError. */
		public function removeChild(child:Node):void
		{
			var indexOf:int = _children.indexOf(child);
			if (indexOf == -1) throw new ArgumentError("Supplied node must be a child of the caller");
			_children.splice(indexOf, 1);
			child.removeTriggerListener(Event.CHANGE, onChildAttributeChange);
			child.dispatch(Event.REMOVED);
			child._parent = null;
			child.restyle();
			child.resource();
			invalidate();
		}

		/** Returns a child object at a certain index. */
		public function getChildAt(index:int):Node
		{
			if (index < 0 || index >= numChildren) new RangeError("Invalid child index");

			return _children[index];
		}

		/** Returns the index of a child within the node, or "-1" if it is not found. */
		public function getChildIndex(child:Node):int
		{
			return _children.indexOf(child);
		}

		//
		// Dispatcher pattern
		//
		public function addTriggerListener(type:String, listener:Function):void
		{
			var trigger:Trigger = _triggers[type];
			if (trigger == null)
				trigger = _triggers[type] = new Trigger();

			trigger.addListener(listener);
		}

		public function removeTriggerListener(type:String, listener:Function):void
		{
			var trigger:Trigger = _triggers[type];
			if (trigger != null)
				trigger.removeListener(listener);
		}

		public function dispatch(type:String, context:* = null):void
		{
			var trigger:Trigger = _triggers[type];
			if (trigger != null)
				trigger.dispatch(context);
		}

		//
		// Dispose
		//
		public function dispose():void
		{
			_style = null;
			_resources = null;

			for each (var child:Node in _children)
				child.dispose();

			for each (var trigger:Trigger in _triggers)
				trigger.removeListeners();

			for each (var attribute:Attribute in _attributes)
				attribute.dispose();
		}
	}
}
