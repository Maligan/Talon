package starling.extensions.talon.core
{
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.ui.MouseCursor;
	import flash.utils.Dictionary;

	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.extensions.talon.layout.Layout;
	import starling.extensions.talon.utils.FillMode;
	import starling.extensions.talon.utils.Orientation;
	import starling.extensions.talon.utils.Visibility;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	public final class Node extends EventDispatcher
	{
		//
		// Strong typed attributes
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
			const ZERO:String = "0px";
			const TRANSPARENT:String = "transparent";
			const WHITE:String = "white";
			const FALSE:String = "false";
			const ONE:String = "1";
			const NULL:String = null;

			width.auto = minWidth.auto = maxWidth.auto = measureAutoWidth;
			height.auto = minHeight.auto = maxHeight.auto = measureAutoHeight;

			// Style (Block styling)
			bind(Attribute.ID, NULL, false);
			bind(Attribute.TYPE, NULL, false);
			bind(Attribute.CLASS, NULL, false);
			bind(Attribute.STATE, NULL, false);

			// Bounds
			bind(Attribute.WIDTH, Gauge.AUTO, true, width);
			bind(Attribute.MIN_WIDTH, Gauge.NONE, true, minWidth);
			bind(Attribute.MAX_WIDTH, Gauge.NONE, true, maxWidth);
			bind(Attribute.HEIGHT, Gauge.AUTO, true, height);
			bind(Attribute.MIN_HEIGHT, Gauge.NONE, true, minHeight);
			bind(Attribute.MAX_HEIGHT, Gauge.NONE, true, maxHeight);

			// Margin
			bind(Attribute.MARGIN, ZERO, true, margin);
			bind(Attribute.MARGIN_TOP, ZERO, true, margin.top);
			bind(Attribute.MARGIN_RIGHT, ZERO, true, margin.right);
			bind(Attribute.MARGIN_BOTTOM, ZERO, true, margin.bottom);
			bind(Attribute.MARGIN_LEFT, ZERO, true, margin.left);

			// Padding
			bind(Attribute.PADDING, ZERO, true, padding);
			bind(Attribute.PADDING_TOP, ZERO, true, padding.top);
			bind(Attribute.PADDING_RIGHT, ZERO, true, padding.right);
			bind(Attribute.PADDING_BOTTOM, ZERO, true, padding.bottom);
			bind(Attribute.PADDING_LEFT, ZERO, true, padding.left);

			// Anchor (Absolute Position)
			bind(Attribute.ANCHOR, Gauge.NONE, true, anchor);
			bind(Attribute.ANCHOR_TOP, Gauge.NONE, true, anchor.top);
			bind(Attribute.ANCHOR_RIGHT, Gauge.NONE, true, anchor.right);
			bind(Attribute.ANCHOR_BOTTOM, Gauge.NONE, true, anchor.bottom);
			bind(Attribute.ANCHOR_LEFT, Gauge.NONE, true, anchor.left);

			// Background
			bind(Attribute.BACKGROUND_IMAGE, NULL, true);
			bind(Attribute.BACKGROUND_TINT, WHITE, true);
			bind(Attribute.BACKGROUND_9SCALE, ZERO, true);
			bind(Attribute.BACKGROUND_COLOR, TRANSPARENT, true);
			bind(Attribute.BACKGROUND_FILL_MODE, FillMode.SCALE, true);

			// Appearance
			bind(Attribute.ALPHA, ONE, true);
			bind(Attribute.CLIPPING, FALSE, true);
			bind(Attribute.CURSOR, MouseCursor.AUTO, true);

			// Font
			bind(Attribute.FONT_COLOR, Attribute.INHERIT, true);
			bind(Attribute.FONT_NAME, Attribute.INHERIT, true);
			bind(Attribute.FONT_SIZE, Attribute.INHERIT, true);

			// Layout
			bind(Attribute.LAYOUT, Layout.FLOW, true);
			bind(Attribute.VISIBILITY, Visibility.VISIBLE, true);

			bind(Attribute.ORIENTATION, Orientation.HORIZONTAL, true);
			bind(Attribute.HALIGN, HAlign.LEFT, true);
			bind(Attribute.VALIGN, VAlign.TOP, true);
			bind(Attribute.GAP, ZERO, true);
			bind(Attribute.INTERLINE, ZERO, true);

			bind(Attribute.POSITION, ZERO, true, position);
			bind(Attribute.X, ZERO, true, position.x);
			bind(Attribute.Y, ZERO, true, position.y);

			bind(Attribute.PIVOT, ZERO, true, pivot);
			bind(Attribute.PIVOT_X, ZERO, true, pivot.x);
			bind(Attribute.PIVOT_Y, ZERO, true, pivot.y);

			bind(Attribute.ORIGIN, ZERO, true, origin);
			bind(Attribute.ORIGIN_X, ZERO, true, origin.x);
			bind(Attribute.ORIGIN_Y, ZERO, true, origin.y);

			addEventListener(Event.CHANGE, onAttributeChange);
		}

		private function bind(name:String, initial:String, styleable:Boolean, source:* = null):void
		{
			var setter:Function = source ? source["parse"] : null;
			var getter:Function = source ? source["toString"] : null;
			var dispatcher:EventDispatcher = source;

			var attribute:Attribute = getOrCreateAttribute(name);
			attribute.bind(dispatcher, getter, setter);
			attribute.initial = initial;
			attribute.inheritable = initial == Attribute.INHERIT;
			attribute.styleable = styleable;
		}

		//
		// Attribute
		//
		/** Get attribute <strong>expanded</strong> value. */
		public function getAttribute(name:String):* { return getOrCreateAttribute(name).expanded; }

		/** Set attribute string <strong>assigned</strong> value. */
		public function setAttribute(name:String, value:String):void { getOrCreateAttribute(name).assigned = value; }

		/** @private Get (create if doesn't exists) attribute. */
		public function getOrCreateAttribute(name:String):Attribute { return _attributes[name] || (_attributes[name] = new Attribute(this, name)); }

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

		/** CCS classes which determine node style. TODO: Optimize. */
		public function get classes():Vector.<String> { return Vector.<String>(getAttribute(Attribute.CLASS) ? getAttribute(Attribute.CLASS).split(" ") : []) }
		public function set classes(value:Vector.<String>):void { setAttribute(Attribute.CLASS, value.join(" ")); restyle(); }

		/** Current active states (aka CSS pseudoClasses: hover, active, checked etc.). TODO: Optimize. */
		public function get states():Vector.<String> { return Vector.<String>(getAttribute(Attribute.STATE) ? getAttribute(Attribute.STATE).split(" ") : []) }
		public function set states(value:Vector.<String>):void { setAttribute(Attribute.STATE, value.join(" ")); restyle(); }

		//
		// Resource
		//
		/** Set current node resources (an object containing key-origin pairs). */
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
				if (attribute.isResource) dispatchEventWith(Event.CHANGE, false, attribute.name);
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

		/** Actual node bounds. */
		public function get bounds():Rectangle { return _bounds; }

		/** Pixel per point. (Also known as (csf) content scale factor) */
		public function get pppt():Number { return Starling.current.contentScaleFactor; }

		/** Pixels per millimeter (in current node). */
		public function get ppmm():Number { return Capabilities.screenDPI / 25.4; }

		/** Current node 'fontSize' expressed in pixels.*/
		public function get ppem():Number
		{
			var common:int = 12;

			var attribute:Attribute = getOrCreateAttribute(Attribute.FONT_SIZE);
			if (attribute.isInherit) return parent ? parent.ppem : common;

			var gauge:Gauge = new Gauge();
			gauge.parse(attribute.value);

			var base:Number =  parent? parent.ppem : common;
			return gauge.toPixels(ppmm, base, pppt, base, 0, 0, 0, 0);
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
			return Layout.getLayoutByAlias(getAttribute(Attribute.LAYOUT));
		}

		private function onAttributeChange(e:Event):void
		{
			var layoutName:String = getAttribute(Attribute.LAYOUT);
			var invalidate:Boolean = Layout.isObservableAttribute(layoutName, e.data as String);
			if (invalidate) commit();
		}

		private function onChildAttributeChange(e:Event):void
		{
			var layoutName:String = getAttribute(Attribute.LAYOUT);
			var invalidate:Boolean = Layout.isObservableChildrenAttribute(layoutName, e.data as String);
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