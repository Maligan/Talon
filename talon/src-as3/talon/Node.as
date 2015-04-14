package talon
{
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;

	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.EventDispatcher;

	import talon.Attribute;

	import talon.layout.Layout;
	import talon.types.Gauge;
	import talon.types.GaugePair;
	import talon.types.GaugeQuad;

	public final class Node extends EventDispatcher
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

		//
		// Private properties
		//
		private var _attributes:Dictionary = new Dictionary();
		private var _style:StyleSheet;
		private var _resources:Object;
		private var _parent:Node;
		private var _children:Vector.<Node> = new Vector.<Node>();
		private var _bounds:Rectangle = new Rectangle();

		/** @private */
		public function Node():void
		{
			// Setup width/height layout callbacks
			width.auto = minWidth.auto = maxWidth.auto = measureAutoWidth;
			height.auto = minHeight.auto = maxHeight.auto = measureAutoHeight;

			// Bindings to strong typed accessors
			bindGauge(width, Attribute.WIDTH);
			bindGauge(minWidth, Attribute.MIN_WIDTH);
			bindGauge(maxWidth, Attribute.MAX_WIDTH);

			bindGauge(height, Attribute.HEIGHT);
			bindGauge(minHeight, Attribute.MIN_HEIGHT);
			bindGauge(maxHeight, Attribute.MAX_HEIGHT);

			bindQuad(margin, Attribute.MARGIN, Attribute.MARGIN_TOP, Attribute.MARGIN_RIGHT, Attribute.MARGIN_BOTTOM, Attribute.MARGIN_LEFT);
			bindQuad(padding, Attribute.PADDING, Attribute.PADDING_TOP, Attribute.PADDING_RIGHT, Attribute.PADDING_BOTTOM, Attribute.PADDING_LEFT);
			bindQuad(anchor, Attribute.ANCHOR, Attribute.ANCHOR_TOP, Attribute.ANCHOR_RIGHT, Attribute.ANCHOR_BOTTOM, Attribute.ANCHOR_LEFT);

			bindPair(position, Attribute.POSITION, Attribute.X, Attribute.Y);
			bindPair(origin, Attribute.ORIGIN, Attribute.ORIGIN_X, Attribute.ORIGIN_Y);
			bindPair(pivot, Attribute.PIVOT, Attribute.PIVOT_X, Attribute.PIVOT_Y);

			// Need initialize all inheritable attributes (for inherit listeners)
			getOrCreateAttribute(Attribute.FONT_COLOR);
			getOrCreateAttribute(Attribute.FONT_NAME);
			getOrCreateAttribute(Attribute.FONT_SIZE);

			// Listen attribute change
			addEventListener(Event.CHANGE, onSelfAttributeChange);
		}

		//
		// Bindings
		//
		private function bindGauge(gauge:Gauge, name:String):void
		{
			bind(gauge, name);
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
			var setter:Function = source["parse"];
			var getter:Function = source["toString"];
			var dispatcher:EventDispatcher = source;

			var attribute:Attribute = getOrCreateAttribute(name);
			setter(attribute.value);
			attribute.bind(dispatcher, getter, setter);
		}

		//
		// Attributes
		//
		/** Get attribute <strong>expanded</strong> value. */
		public function getAttribute(name:String):* { return getOrCreateAttribute(name).expanded; }

		/** Set attribute string <strong>assigned</strong> value. */
		public function setAttribute(name:String, value:String):void { getOrCreateAttribute(name).assigned = value; }

		/** @private Get (create if doesn't exists) attribute. */
		public function getOrCreateAttribute(name:String):Attribute
		{
			var result:Attribute = _attributes[name];
			if (result == null)
			{
				result = _attributes[name] = new Attribute(this, name);
				result.addEventListener(Event.CHANGE, onAttributeChange);
			}

			return result;
		}

		private function onAttributeChange(e:Event):void
		{
			var attribute:Attribute = Attribute(e.target);
			dispatchEventWith(Event.CHANGE, false, attribute.name)
		}

		//
		// Styling
		//
		public function setStyleSheet(style:StyleSheet):void
		{
			_style = style;
			restyle();
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

		public function getStyle(node:Node):Object
		{
			if (_style == null && _parent != null) return _parent.getStyle(node);
			if (_style != null && _parent == null) return _style.getStyle(node);
			if (_style != null && _parent != null) return _style.getStyle(node, _parent.getStyle(node));
			return new Object();
		}

		/** CCS classes which determine node style. TODO: Optimize. */
		public function get classes():Vector.<String> { return Vector.<String>(getAttribute(Attribute.CLASS) ? getAttribute(Attribute.CLASS).split(" ") : []) }
		public function set classes(value:Vector.<String>):void { setAttribute(Attribute.CLASS, value.join(" ")); restyle(); }

		/** Current active states (aka CSS pseudoClasses: hover, active, checked etc.). TODO: Optimize. */
		public function get states():Vector.<String> { return Vector.<String>(getAttribute(Attribute.STATE) ? getAttribute(Attribute.STATE).split(" ") : []) }
		public function set states(value:Vector.<String>):void { setAttribute(Attribute.STATE, value.join(" ")); restyle(); }

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
			{
				if (attribute.isResource) attribute.dispatchChange();
			}

			// Recursive children notify resource change
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:Node = getChildAt(i);
				child.resource();
			}
		}

		//
		// Layout
		//
		/** Apply bounds changes: dispatch RESIZE event, arrange children. */
		public function commit():void
		{
			// Update self view object attached to node
			dispatchEventWith(Event.RESIZE);

			// Update children nodes
			layout.arrange(this, bounds.width, bounds.height);
		}

		/** Actual node bounds in pixels. */
		public function get bounds():Rectangle { return _bounds; }

		/** Pixel per point. (Also known as (csf) content scale factor) */
		public function get ppdp():Number { return Starling.current.contentScaleFactor; }

		/** Pixels per millimeter (in current node). */
		public function get ppmm():Number { return Capabilities.screenDPI / 25.4; }

		/** Current node 'fontSize' expressed in pixels.*/
		public function get ppem():Number
		{
			// TODO: Optimize calculation (bubbling ppem method call is poor)
			var base:int = 12;
			var inherit:Number = parent ? parent.ppem : base;
			var attribute:Attribute = getOrCreateAttribute(Attribute.FONT_SIZE);
			if (attribute.isInherit) return inherit;
			return Gauge.toPixels(attribute.value, ppmm, inherit, ppdp, inherit, 0, 0, 0, 0);
		}

		/** This is 'auto' callback for gauges: width, minWidth, maxWidth. */
		private function measureAutoWidth(width:Number, height:Number):Number
		{
			return layout.measureAutoWidth(this, width, height);
		}

		/** This is 'auto' callback for gauges: height, minHeight, maxHeight. */
		private function measureAutoHeight(width:Number, height:Number):Number
		{
			return layout.measureAutoHeight(this, width, height);
		}

		/** Node layout strategy class. */
		private function get layout():Layout
		{
			var layoutAlias:String = getAttribute(Attribute.LAYOUT);
			return Layout.getLayoutByAlias(layoutAlias);
		}

		private function onSelfAttributeChange(e:Event):void
		{
			var layoutName:String = getAttribute(Attribute.LAYOUT);
			var invalidate:Boolean = Layout.isObservableSelfAttribute(layoutName, e.data as String);
			if (invalidate) commit();
		}

		private function onChildAttributeChange(e:Event):void
		{
			var layoutName:String = getAttribute(Attribute.LAYOUT);
			var invalidate:Boolean = Layout.isObservableChildAttribute(layoutName, e.data as String);
			if (invalidate) commit();
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
			child.addEventListener(Event.CHANGE, onChildAttributeChange);
			child.dispatchEventWith(Event.ADDED);
		}

		/** Removes a child from the container. If the object is not a child throws ArgumentError */
		public function removeChild(child:Node):void
		{
			var indexOf:int = _children.indexOf(child);
			if (indexOf == -1) throw new ArgumentError("Supplied node must be a child of the caller");
			_children.splice(indexOf, 1);
			child.removeEventListener(Event.CHANGE, onChildAttributeChange);
			child.dispatchEventWith(Event.REMOVED);
			child._parent = null;
			child.restyle();
			child.resource();
		}

		/** Returns a child object at a certain index. */
		public function getChildAt(index:int):Node
		{
			if (index < 0 || index >= numChildren) new RangeError("Invalid child index");

			return _children[index];
		}
	}
}