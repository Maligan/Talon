package talon.core
{
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;

	import talon.layouts.Layout;
	import talon.utils.Gauge;
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

	public final class Node
	{
		private var _attributes:Dictionary = new Dictionary();
		private var _styles:Vector.<Style>;
		private var _styleTouches:Dictionary = new Dictionary();
		private var _styleTouch:int = -1;
		
		private var _resources:Object;
		private var _parent:Node;
		private var _children:Vector.<Node> = new Vector.<Node>();
		private var _bounds:Rectangle = new Rectangle(0, 0, NaN, NaN);
		private var _triggers:Dictionary = new Dictionary();
		private var _ppdp:Number = 1;
		private var _ppmm:Number = Capabilities.screenDPI / 25.4;  // 25.4mm in 1 inch
		private var _invalidated:Boolean = true;
		private var _freeze:Boolean = false;

		/** @private */
		public function Node():void
		{
			// Initialize all inheritable attributes (initialize theirs listeners)
			for each (var attributeName:String in Attribute.getInheritableAttributeNames())
				getOrCreateAttribute(attributeName);

			// Listen attribute change
			addTriggerListener(Event.CHANGE, onSelfAttributeChange);

			// Setup typed attributes
			width.auto = measureAutoWidth;
			height.auto = measureAutoHeight;
			states.change.addListener(refreshStyle);
			classes.change.addListener(refreshStyle);
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
		// Freeze
		//
		public function freeze():void
		{
			_freeze = true;
		}

		public function unfreeze():void
		{
			_freeze = false;

			for (var i:int = 0; i < numChildren; i++)
				getChildAt(i).unfreeze();
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
		public function setStyles(styles:Vector.<Style>):void
		{
			_styles = styles;
			refreshStyle();
		}

		/** Recursive apply style to current node. */
		private function refreshStyle():void
		{
			if (_freeze) return;

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
			{
				if (_styleTouches[attribute.name] != _styleTouch)
					attribute.styled = null;
			}

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
			if (_freeze) return;

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
		/** This flag means that current automatic width/height is changed from last measurement. */
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

				if (_parent && (width.isNone||height.isNone))
					_parent.invalidate();
			}
		}

		/** Commit node bounds (and validate node layout):
		 *
		 *  1) Dispatch RESIZE event.
		 *  2) Arrange children with layout algorithm and commit them.
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
			// Avoid loops (toPixels() <-> ppem) with EM or PERCENT units
			// 12 is hardcoded version of fontSize 'based' value
			
			if (fontSize.unit == Gauge.EM)
				return fontSize.amount * (parent ? parent.ppem : 12);

			else if (fontSize.unit == Gauge.PERCENT)
				return fontSize.amount * (parent ? parent.ppem : 12) / 100;

			return fontSize.toPixels(this);
		}

		/** This is default 'auto' callback for gauges: width, minWidth, maxWidth. */
		private function measureAutoWidth(height:Number):Number
		{
			return layout.measureWidth(this, height);
		}

		/** This is default 'auto' callback for gauges: height, minHeight, maxHeight. */
		private function measureAutoHeight(width:Number):Number
		{
			return layout.measureHeight(this, width);
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
		public function addChild(child:Node, index:int = -1):void
		{
			if (child._parent != null) throw new ArgumentError("Child must be free from parent");
			if (index < 0 || index > numChildren) index = numChildren;

			_children.insertAt(index, child);
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
			if (child._parent != this) throw new ArgumentError("Child must be child of node");

			_children.removeAt(_children.indexOf(child));
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