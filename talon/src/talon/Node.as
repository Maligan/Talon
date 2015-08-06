package talon
{
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	import flash.events.Event;

	import talon.layout.Layout;
	import talon.utils.Binding;
	import talon.utils.Gauge;
	import talon.utils.GaugePair;
	import talon.utils.GaugeQuad;
	import talon.utils.StringSet;
	import talon.utils.Trigger;

	[Event(name="change")]
	[Event(name="resize")]
	[Event(name="added")]
	[Event(name="removed")]
	public final class Node
	{
		//
		// Strong typed attributes accessors
		//
		public const width:Gauge = new Gauge();
		public const minWidth:Gauge = new Gauge();
		public const maxWidth:Gauge = new Gauge();

		public const height:Gauge = new Gauge();
		public const minHeight:Gauge = new Gauge();
		public const maxHeight:Gauge = new Gauge();

		public const margin:GaugeQuad = new GaugeQuad();
		public const padding:GaugeQuad = new GaugeQuad();
		public const anchor:GaugeQuad = new GaugeQuad();

		public const position:GaugePair = new GaugePair();
		public const origin:GaugePair = new GaugePair();
		public const pivot:GaugePair = new GaugePair();

		/** CCS classes which determine node style. */
		public const classes:StringSet = new StringSet();

		/** Current active states (aka CSS pseudoClasses: hover, active, checked etc.). */
		public const states:StringSet = new StringSet();

		//
		// Private properties
		//
		private var _attributes:Dictionary = new Dictionary();
		private var _style:StyleSheet;
		private var _resources:Object;
		private var _parent:Node;
		private var _children:Vector.<Node> = new Vector.<Node>();
		private var _bounds:Rectangle = new Rectangle();
		private var _triggers:Dictionary = new Dictionary();
		private var _bindings:Dictionary = new Dictionary();
		private var _ppdp:Number;
		private var _ppmm:Number;
		private var _invalidated:Boolean;

		/** @private */
		public function Node():void
		{
			// Setup width/height layout callbacks
			width.auto = measureAutoWidth;
			height.auto = measureAutoHeight;

			states.change.addListener(restyle);
			classes.change.addListener(restyle);

			initializeBindings();

			// Initialize all inheritable attributes (for inherit listeners)
			var inheritable:Vector.<String> = Attribute.getInheritableAttributeNames();
			for each (var attributeName:String in inheritable) getOrCreateAttribute(attributeName);

			// Listen attribute change
			addListener(Event.CHANGE, onSelfAttributeChange);

			_ppdp = 1;
			_ppmm = Capabilities.screenDPI / 25.4; // 25.4mm in 1 inch
			_invalidated = true;
		}

		//
		// Bindings initialization
		//
		private function initializeBindings():void
		{
			bind(width, Attribute.WIDTH);
			bind(minWidth, Attribute.MIN_WIDTH);
			bind(maxWidth, Attribute.MAX_WIDTH);

			bind(height, Attribute.HEIGHT);
			bind(minHeight, Attribute.MIN_HEIGHT);
			bind(maxHeight, Attribute.MAX_HEIGHT);

			bindQuad(margin, Attribute.MARGIN, Attribute.MARGIN_TOP, Attribute.MARGIN_RIGHT, Attribute.MARGIN_BOTTOM, Attribute.MARGIN_LEFT);
			bindQuad(padding, Attribute.PADDING, Attribute.PADDING_TOP, Attribute.PADDING_RIGHT, Attribute.PADDING_BOTTOM, Attribute.PADDING_LEFT);
			bindQuad(anchor, Attribute.ANCHOR, Attribute.ANCHOR_TOP, Attribute.ANCHOR_RIGHT, Attribute.ANCHOR_BOTTOM, Attribute.ANCHOR_LEFT);

			bindPair(position, Attribute.POSITION, Attribute.X, Attribute.Y);
			bindPair(origin, Attribute.ORIGIN, Attribute.ORIGIN_X, Attribute.ORIGIN_Y);
			bindPair(pivot, Attribute.PIVOT, Attribute.PIVOT_X, Attribute.PIVOT_Y);

			bind(classes, Attribute.CLASS);
			bind(states, Attribute.STATE);
		}

		private function bindPair(pair:GaugePair, name:String, x:String, y:String):void
		{
			bind(pair, name);
			bind(pair.x, x);
			bind(pair.y, y);
		}

		private function bindQuad(quad:GaugeQuad, name:String, top:String, right:String, bottom:String, left:String):void
		{
			bind(quad, name);
			bind(quad.top, top);
			bind(quad.right, right);
			bind(quad.bottom, bottom);
			bind(quad.left, left);
		}

		private function bind(source:*, name:String):void
		{
			var attribute:Attribute = getOrCreateAttribute(name);

			var fromAttribute:Binding = Binding.bind(attribute.change, attribute, "value", source, "parse");
			fromAttribute.trigger();
			addBinding(fromAttribute);

			var toAttribute:Binding = Binding.bind(source.change, source, "toString", attribute, "setted");
			addBinding(toAttribute);
		}

		//
		// Bindings
		//
		/** Add attached binding (for dispose with node). */
		public function addBinding(binding:Binding):void
		{
			_bindings[binding] = binding;
		}

		/** Remove attached binding. */
		public function removeBinding(binding:Binding, dispose:Boolean = false):void
		{
			if (_bindings[binding] != null)
			{
				if (dispose) binding.dispose();
				delete _bindings[binding];
			}
		}

		//
		// Attributes
		//
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

		/** Raise isInvalidated flag. */
		public function invalidate():void
		{
			if (_invalidated === false)
			{
				_invalidated = true;
				dispatch(Event.CHANGE);
			}
		}

		/** Validate node layout:
		 *  - Apply 'bounds' via dispatch RESIZE event
		 *  - Arrange children
		 *  Call this method after manually change 'bounds' property to validate layout.
		 *  NB! Node layout will be validated independently isInvalidated flag is true or false. */
		public function validate():void
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
			return Gauge.toPixels(attribute.basic, ppmm, inherit, ppdp, inherit, 0, 0, 0);
		}

		/** This is 'auto' callback for gauges: width, minWidth, maxWidth. */
		private function measureAutoWidth(height:Number):Number
		{
			return layout.measureAutoWidth(this, height);
		}

		/** This is 'auto' callback for gauges: height, minHeight, maxHeight. */
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
		// Complex
		//
		/** The node that contains this node. */
		public function get parent():Node { return _parent; }

		/** The number of children of this node. */
		public function get numChildren():int { return _children.length; }

		/** Adds a child to the container. It will be at the frontmost position. */
		public function addChild(child:Node):void
		{
			_children.push(child);
			child._parent = this;
			child.restyle();
			child.resource();
			child.addListener(Event.CHANGE, onChildAttributeChange);
			child.dispatch(Event.ADDED);
			invalidate();
		}

		/** Removes a child from the container. If the object is not a child throws ArgumentError. */
		public function removeChild(child:Node):void
		{
			var indexOf:int = _children.indexOf(child);
			if (indexOf == -1) throw new ArgumentError("Supplied node must be a child of the caller");
			_children.splice(indexOf, 1);
			child.removeListener(Event.CHANGE, onChildAttributeChange);
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

		//
		// Dispatcher
		//
		public function addListener(type:String, listener:Function):void
		{
			var trigger:Trigger = _triggers[type];
			if (trigger == null)
				trigger = _triggers[type] = new Trigger();

			trigger.addListener(listener);
		}

		public function removeListener(type:String, listener:Function):void
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

			for each (var binding:Binding in _bindings)
				binding.dispose();
		}
	}
}