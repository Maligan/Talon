package talon
{
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;

	import talon.layout.Layout;
	import talon.utils.Accessor;
	import talon.utils.Gauge;
	import talon.utils.ITalonElement;
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

		private var _touches:Dictionary = new Dictionary();
		private var _touch:int = -1;

		/** @private */
		public function Node():void
		{
			_ppdp = 1;
			_ppmm = Capabilities.screenDPI / 25.4; // 25.4mm in 1 inch
			_invalidated = true;

			// Initialize all inheritable attributes (initialize theirs listeners)
			for each (var attributeName:String in Attribute.getInheritableAttributeNames())
				getOrCreateAttribute(attributeName);

			// Listen attribute change
			addTriggerListener(Event.CHANGE, onSelfAttributeChange);

			// Setup width/height layout callbacks
			_accessor = new Accessor(this);
			_accessor.width.auto = measureAutoWidth;
			_accessor.height.auto = measureAutoHeight;
			_accessor.states.change.addListener(refreshStyle);
			_accessor.classes.change.addListener(refreshStyle);
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
			refreshStyle();
		}

		public function getStyle(node:Node):Object
		{
			if (_style == null && _parent != null) return _parent.getStyle(node);
			if (_style != null && _parent == null) return _style.getStyle(node);
			if (_style != null && _parent != null) return _style.getStyle(node, _parent.getStyle(node));
			return new Object();
		}

		/** Recursive apply style to current node. */
		private function refreshStyle():void
		{
			var style:Object = getStyle(this);

			_touch++;

			// Set styled values (NB! Order is important)
			for (var name:String in style)
			{
				getOrCreateAttribute(name).styled = style[name];
				_touches[name] = _touch;
			}

			// Clear all previous styles
			for each (var attribute:Attribute in _attributes)
			{
				if (_touches[attribute.name] != _touch)
					attribute.styled = null;
			}

			// Recursive children restyling
			for (var i:int = 0; i < numChildren; i++)
				getChildAt(i).refreshStyle();
		}

		//
		// Resource
		//
		/** Set current node resources (an object containing key-value pairs). */
		public function setResources(resources:Object):void
		{
			_resources = resources;
			refreshResource();
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

		private function refreshResource():void
		{
			// Notify resource change
			for each (var attribute:Attribute in _attributes)
				if (attribute.isResource) attribute.dispatchChange();

			// Recursive children notify resource change
			for (var i:int = 0; i < numChildren; i++)
				getChildAt(i).refreshResource();
		}

		//
		// Layout
		//
		public function get invalidated():Boolean
		{
			return _invalidated;
		}

		/** Raise (only!) invalidated flag. */
		public function invalidate():void
		{
			if (_invalidated === false)
			{
				_invalidated = true;
				dispatch(Event.CHANGE); // FIXME: Change event type (CHANGE used for attribute changing)
			}
		}

		/** Commit node bounds (and validate node layout):
		 *
		 *  1) Dispatch RESIZE event.
		 *  2) Arrange children with layout algorithm & commit them.
		 *  3) Reset invalidated flag.
		 *
		 *  Call this method after manually change 'bounds' property to validate layout.
		 *  NB! Node layout will be validated independently invalidated flag is true or false. */
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
			const BASE:int = 12;

			// If fontSize is inherit:
			var attribute:Attribute = getOrCreateAttribute(Attribute.FONT_SIZE);
			if (attribute.isInherit) return parent.ppem;

			// If it is root node and fontSize is not setted:
			if (attribute.valueCache == "inherit") return BASE;

			// Else calculate via parent and self values:
			var relative:int = parent ? parent.ppem : BASE;
			return Gauge.toPixels(attribute.value, ppmm, relative, ppdp, relative);
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
            child.refreshStyle();
            child.refreshResource();
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
			child.refreshStyle();
			child.refreshResource();
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
