package talon.core
{
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	import talon.layouts.Layout;
	import talon.utils.Gauge;
	import talon.utils.Metrics;
	import talon.utils.ParseUtil;
	import talon.utils.StringSet;
	import talon.utils.StyleUtil;
	import talon.utils.Trigger;

	/** Any attribute changed. */
	[Event(name="change")]
	/** Property 'bounds' changed. */
	[Event(name="resize")]
	/** Added to parent node. */
	[Event(name="added")]
	/** Removed from parent node. */
	[Event(name="removed")]
	/** Node is changed (visual cache must be ignored). */
	[Event(name="update")]

	/**  */
	public final class Node
	{
		private static const RESOURCES:int	= 0x1;
		private static const STYLE:int		= 0x2;
		private static const LAYOUT:int		= 0x4;
		
		private var _attributes:Dictionary = new Dictionary();
		private var _styles:Vector.<Style>;
		private var _styleTouches:Dictionary = new Dictionary();
		private var _styleTouch:int = -1;
		private var _resources:Object;
		private var _parent:Node;
		private var _children:Vector.<Node> = new Vector.<Node>();
		private var _bounds:Rectangle = new Rectangle(0, 0, -1, -1);
		private var _boundsCache:Rectangle = new Rectangle();
		private var _triggers:Dictionary = new Dictionary();
		private var _metrics:Metrics = new Metrics(this);
		private var _status:int = RESOURCES | STYLE | LAYOUT;
		
		/** @private */
		public function Node():void
		{
			// Initialize all inheritable attributes (initialize theirs listeners)
			for each (var attributeName:String in Attribute.getInheritableAttributeNames())
				getOrCreateAttribute(attributeName);

			// Listen attribute change
			addListener(Event.CHANGE, onSelfOrChildAttributeChange);

			// Setup typed attributes
			width.auto = measureAutoWidth;
			height.auto = measureAutoHeight;
			states.change.addListener(resetStyle);
			classes.change.addListener(resetStyle);
		}

		//
		// Strong typed attributes wrappers:
		// For internal/layouts usage only.
		//
		/** @private */ public const fontSize:Gauge = new Gauge(this, Attribute.FONT_SIZE);

		/** @private */ public const width:Gauge = new Gauge(this, Attribute.WIDTH);
		/** @private */ public const height:Gauge = new Gauge(this, Attribute.HEIGHT);

		/** @private */ public const minWidth:Gauge = new Gauge(this, Attribute.MIN_WIDTH);
		/** @private */ public const minHeight:Gauge = new Gauge(this, Attribute.MIN_HEIGHT);

		/** @private */ public const maxWidth:Gauge = new Gauge(this, Attribute.MAX_WIDTH);
		/** @private */ public const maxHeight:Gauge = new Gauge(this, Attribute.MAX_HEIGHT);

		/** @private */ public const marginTop:Gauge = new Gauge(this, Attribute.MARGIN_TOP);
		/** @private */ public const marginRight:Gauge = new Gauge(this, Attribute.MARGIN_RIGHT);
		/** @private */ public const marginBottom:Gauge = new Gauge(this, Attribute.MARGIN_BOTTOM);
		/** @private */ public const marginLeft:Gauge = new Gauge(this, Attribute.MARGIN_LEFT);

		/** @private */ public const paddingTop:Gauge = new Gauge(this, Attribute.PADDING_TOP);
		/** @private */ public const paddingRight:Gauge = new Gauge(this, Attribute.PADDING_RIGHT);
		/** @private */ public const paddingBottom:Gauge = new Gauge(this, Attribute.PADDING_BOTTOM);
		/** @private */ public const paddingLeft:Gauge = new Gauge(this, Attribute.PADDING_LEFT);

		/** @private */ public const top:Gauge = new Gauge(this, Attribute.TOP);
		/** @private */ public const right:Gauge = new Gauge(this, Attribute.RIGHT);
		/** @private */ public const bottom:Gauge = new Gauge(this, Attribute.BOTTOM);
		/** @private */ public const left:Gauge = new Gauge(this, Attribute.LEFT);

		/** @private */ public const pivotX:Gauge = new Gauge(this, Attribute.PIVOT_X);
		/** @private */ public const pivotY:Gauge = new Gauge(this, Attribute.PIVOT_Y);

		/** @private */ public const classes:StringSet = new StringSet(this, Attribute.CLASS);
		/** @private */ public const states:StringSet = new StringSet(this, Attribute.STATE);

		//
		// Attributes
		//
		/** @private */
		public function get attributes():Object { return _attributes; }
		
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
		public function setStyles(styles:Vector.<Style>):void
		{
			status |= STYLE;
			_styles = styles;
		}

		/** Recursive apply style to current node. */
		private function refreshStyle():void
		{
			status &= ~STYLE;
			
			var style:Object = requestStyle(this);
	
			_styleTouch++;
	
			// Set styled values (NB! Order is important)
			for (var name:String in style)
			{
				getOrCreateAttribute(name).styled = style[name];
				_styleTouches[name] = _styleTouch;
			}
	
			// Clear all previous styles
			for each (var attribute:Attribute in _attributes)
				if (_styleTouches[attribute.name] != _styleTouch)
					attribute.styled = null;
			
			// Recursive children restyling
			for (var i:int = 0; i < numChildren; i++)
				getChildAt(i).refreshStyle();
		}
		
		private function requestStyle(node:Node):Object
		{
			if (_styles == null && _parent != null) return _parent.requestStyle(node);
			if (_styles != null && _parent == null) return StyleUtil.style(node, _styles);
			if (_styles != null && _parent != null) return StyleUtil.style(node, _styles, _parent.requestStyle(node));
			return {};
		}
		
		private function resetStyle():void
		{
			status |= STYLE;

			for (var i:int = 0; i < numChildren; i++)
				getChildAt(i).resetStyle();
		}
		
		//
		// Resource
		//
		/** Set current node resources (an object containing key-value pairs). */
		public function setResources(resources:Object):void
		{
			status |= RESOURCES;
			_resources = resources;
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
			status &= ~RESOURCES;
	
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
		
		private function refreshLayout():void
		{
			var visible:Boolean = ParseUtil.parseBoolean(getAttributeCache(Attribute.VISIBLE));
			if (!visible) return;
			
			if (boundsIsResized || status | LAYOUT)
			{
				status &= ~LAYOUT;
				layout.arrange(this, bounds.width, bounds.height);
			}

			if (boundsIsChanged)
			{
				_boundsCache.copyFrom(bounds);
				dispatch(Event.RESIZE);
			}

			for (var i:int = 0; i < numChildren; i++)
				getChildAt(i).refreshLayout();
		}

		public function invalidate():void
		{
			status |= LAYOUT;
			
			if (width.isNone || height.isNone)
				parent && parent.invalidate();
		}
		
		public function get invalidated():Boolean
		{
			return status > 0
				|| boundsIsChanged;
		}

		public function validate(layout:Boolean = true):void
		{
			if (status & STYLE)
				refreshStyle();
			
			if (status & RESOURCES)
				refreshResource();
			
			if (layout)
				refreshLayout();
		}
		
		/** Bonds was changed from external code. */
		private function get boundsIsChanged():Boolean
		{
			return boundsIsResized
				|| _boundsCache.x != _bounds.x
				|| _boundsCache.y != _bounds.y;
		}
		
		private function get boundsIsResized():Boolean
		{
			return _boundsCache.width != _bounds.width
				|| _boundsCache.height != _bounds.height;
		}
		
		/** Actual node bounds in pixels. */
		public function get bounds():Rectangle { return _bounds; }

		/** Gauge units metrics within current node. */
		public function get metrics():Metrics { return _metrics; }
		
		/** This is default 'auto' callback for gauges: width, minWidth, maxWidth. */
		private function measureAutoWidth(height:Number):Number { return invalidated ? layout.measureWidth(this, height) : _boundsCache.width; }

		/** This is default 'auto' callback for gauges: height, minHeight, maxHeight. */
		private function measureAutoHeight(width:Number):Number { return invalidated ? layout.measureHeight(this, width) : _boundsCache.height; }

		/** Node layout strategy class. */
		private function get layout():Layout
		{
			var name:String = getAttributeCache(Attribute.LAYOUT);
			return Layout.getLayout(name);
		}

		private function onSelfOrChildAttributeChange(attribute:Attribute):void
		{
			var layoutChanged:Boolean = layout.isObservable(this, attribute);
			if (layoutChanged)
				invalidate();
		}

		//
		// Helper for validation
		//
		private function get status():int { return _status }
		private function set status(value:int):void
		{
			if (_status != value)
			{
				var changed:int = ~_status && value;	// Bits which was setted to one
				_status = value;
				if (changed != 0) dispatch("update");	// There is not flash.events.Event.UPDATE (but there is in Starling)
			}
		}

		//
		// Complex pattern
		//
		/** The node that contains this node. */
		public function get parent():Node { return _parent; }

		/** The number of children of this node. */
		public function get numChildren():int { return _children.length; }

		/** Adds a child to the container. */
		public function addChild(child:Node, index:int = -1):void
		{
			if (child._parent != null) throw new ArgumentError("Child must be free from parent");
			if (index < 0 || index > numChildren) index = numChildren;

			_children.insertAt(index, child);
			child._parent = this;
			child.addListener(Event.CHANGE, onSelfOrChildAttributeChange);
			child.dispatch(Event.ADDED);
			child.status |= STYLE | RESOURCES;

			invalidate();
		}

		/** Removes a child from the container. If the object is not a child throws ArgumentError. */
		public function removeChild(child:Node):void
		{
			if (child._parent != this) throw new ArgumentError("Child must be child of node");

			_children.removeAt(_children.indexOf(child));
			child.removeListener(Event.CHANGE, onSelfOrChildAttributeChange);
			child.dispatch(Event.REMOVED);
			child.status |= STYLE | RESOURCES;
			child._parent = null;

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
		public function addListener(type:String, listener:Function):void
		{
			var trigger:Trigger = _triggers[type];
			if (trigger == null)
				trigger = _triggers[type] = new Trigger(this);

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
			_styles = null;
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
