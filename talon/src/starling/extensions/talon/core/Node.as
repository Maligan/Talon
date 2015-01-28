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
	import starling.extensions.talon.utils.Attributes;
	import starling.extensions.talon.utils.FillMode;
	import starling.extensions.talon.utils.Orientation;
	import starling.extensions.talon.utils.StringUtil;
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
		private var _invokers:Object;
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

			_invokers = new Object();
			_invokers["res"] = getResource;

			width.auto = minWidth.auto = maxWidth.auto = measureAutoWidth;
			height.auto = minHeight.auto = maxHeight.auto = measureAutoHeight;

			// Style (Block styling)
			bind(Attributes.ID, NULL, false);
			bind(Attributes.TYPE, NULL, false);
			bind(Attributes.CLASS, NULL, false);
			bind(Attributes.STATE, NULL, false);

			// Bounds
			bind(Attributes.WIDTH, Gauge.AUTO, true, width);
			bind(Attributes.MIN_WIDTH, Gauge.NONE, true, minWidth);
			bind(Attributes.MAX_WIDTH, Gauge.NONE, true, maxWidth);
			bind(Attributes.HEIGHT, Gauge.AUTO, true, height);
			bind(Attributes.MIN_HEIGHT, Gauge.NONE, true, minHeight);
			bind(Attributes.MAX_HEIGHT, Gauge.NONE, true, maxHeight);

			// Margin
			bind(Attributes.MARGIN, ZERO, true, margin);
			bind(Attributes.MARGIN_TOP, ZERO, true, margin.top);
			bind(Attributes.MARGIN_RIGHT, ZERO, true, margin.right);
			bind(Attributes.MARGIN_BOTTOM, ZERO, true, margin.bottom);
			bind(Attributes.MARGIN_LEFT, ZERO, true, margin.left);

			// Padding
			bind(Attributes.PADDING, ZERO, true, padding);
			bind(Attributes.PADDING_TOP, ZERO, true, padding.top);
			bind(Attributes.PADDING_RIGHT, ZERO, true, padding.right);
			bind(Attributes.PADDING_BOTTOM, ZERO, true, padding.bottom);
			bind(Attributes.PADDING_LEFT, ZERO, true, padding.left);

			// Anchor (Absolute Position)
			bind(Attributes.ANCHOR, Gauge.NONE, true, anchor);
			bind(Attributes.ANCHOR_TOP, Gauge.NONE, true, anchor.top);
			bind(Attributes.ANCHOR_RIGHT, Gauge.NONE, true, anchor.right);
			bind(Attributes.ANCHOR_BOTTOM, Gauge.NONE, true, anchor.bottom);
			bind(Attributes.ANCHOR_LEFT, Gauge.NONE, true, anchor.left);

			// Background
			bind(Attributes.BACKGROUND_IMAGE, NULL, true);
			bind(Attributes.BACKGROUND_TINT, WHITE, true);
			bind(Attributes.BACKGROUND_9SCALE, ZERO, true);
			bind(Attributes.BACKGROUND_COLOR, TRANSPARENT, true);
			bind(Attributes.BACKGROUND_FILL_MODE, FillMode.SCALE, true);

			// Appearance
			bind(Attributes.ALPHA, ONE, true);
			bind(Attributes.CLIPPING, FALSE, true);
			bind(Attributes.CURSOR, MouseCursor.AUTO, true);

			// Font
			bind(Attributes.FONT_COLOR, Attribute.INHERIT, true);
			bind(Attributes.FONT_NAME, Attribute.INHERIT, true);
			bind(Attributes.FONT_SIZE, Attribute.INHERIT, true);

			// Layout
			bind(Attributes.LAYOUT, Layout.FLOW, true);
			bind(Attributes.VISIBILITY, Visibility.VISIBLE, true);

			bind(Attributes.ORIENTATION, Orientation.HORIZONTAL, true);
			bind(Attributes.HALIGN, HAlign.LEFT, true);
			bind(Attributes.VALIGN, VAlign.TOP, true);
			bind(Attributes.GAP, ZERO, true);
			bind(Attributes.INTERLINE, ZERO, true);

			bind(Attributes.POSITION, ZERO, true, position);
			bind(Attributes.X, ZERO, true, position.x);
			bind(Attributes.Y, ZERO, true, position.y);

			bind(Attributes.PIVOT, ZERO, true, pivot);
			bind(Attributes.PIVOT_X, ZERO, true, pivot.x);
			bind(Attributes.PIVOT_Y, ZERO, true, pivot.y);

			bind(Attributes.ORIGIN, ZERO, true, origin);
			bind(Attributes.ORIGIN_X, ZERO, true, origin.x);
			bind(Attributes.ORIGIN_Y, ZERO, true, origin.y);

			addEventListener(Event.CHANGE, onAttributeChange);
		}

		private function bind(name:String, initial:String, styleable:Boolean, source:* = null):void
		{
			var setter:Function = source ? source["parse"] : null;
			var getter:Function = source ? source["toString"] : null;
			var dispatcher:EventDispatcher = source;

			if (setter) setter(initial);

			_attributes[name] = new Attribute(this, name, initial, initial == Attribute.INHERIT, styleable, getter, setter, dispatcher);
		}

		//
		// Attributes
		//
		public function getAttribute(name:String):*
		{
			// If attribute doesn't exist return null
			var attribute:Attribute = _attributes[name];
			if (attribute == null) return null;

			// If attribute is simple return string value
			var value:String = attribute.value;
			var invokeInfo:Array = StringUtil.parseFunction(value);
			if (invokeInfo == null) return value;

			// Obtain invoker via invokeInfo
			var invokeMethodName:String = invokeInfo.shift();
			var invokeMethod:Function = _invokers[invokeMethodName];
			if (invokeMethod == null) return value;

			return invokeMethod.apply(null, invokeInfo);
		}

		public function setAttribute(name:String, value:String):void
		{
			var attribute:Attribute = _attributes[name];
			if (attribute == null) attribute = _attributes[name] = new Attribute(this, name);
			attribute.setAssignedValue(value);
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
				attribute.setStyledValue(style[attribute.name]);
				delete style[attribute.name];
			}

			// Addition attributes defined by style
			for (var name:String in style)
			{
				attribute = _attributes[name] || (_attributes[name] = new Attribute(this, name));
				attribute.setStyledValue(style[name]);
			}

			// Recursive children restyling
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:Node = getChildAt(i);
				child.restyle();
			}
		}

		/** CCS classes which determine node style. */
		public function get classes():Vector.<String> { return Vector.<String>(getAttribute(Attributes.CLASS) ? getAttribute(Attributes.CLASS).split(" ") : []) }
		public function set classes(value:Vector.<String>):void { setAttribute(Attributes.CLASS, value.join(" ")); restyle(); }

		/** Current active states (aka CSS pseudoClasses: hover, active, checked etc.) */
		public function get states():Vector.<String> { return Vector.<String>(getAttribute(Attributes.STATE) ? getAttribute(Attributes.STATE).split(" ") : []) }
		public function set states(value:Vector.<String>):void { setAttribute(Attributes.STATE, value.join(" ")); restyle(); }

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
				var value:String = attribute.value;
				if (value == null) continue;
				if (value.indexOf("res") == 0) dispatchEventWith(Event.CHANGE, false, attribute.name);
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
			var attribute:Attribute = _attributes[Attributes.FONT_SIZE];
			if (attribute.isInherit) return parent?parent.ppem:12;
			var gauge:Gauge = new Gauge();
			gauge.parse(attribute.value);
			var base:Number = parent?parent.ppem:12;
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
			return Layout.getLayoutByAlias(getAttribute(Attributes.LAYOUT));
		}

		private function onAttributeChange(e:Event):void
		{
			var layoutName:String = getAttribute(Attributes.LAYOUT);
			var invalidate:Boolean = Layout.isObservableAttribute(layoutName, e.data as String);
			if (invalidate) commit();
		}

		private function onChildAttributeChange(e:Event):void
		{
			var layoutName:String = getAttribute(Attributes.LAYOUT);
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

import starling.events.Event;
import starling.events.EventDispatcher;
import starling.extensions.talon.core.Node;

internal class Attribute
{
	public static const INHERIT:String = "inherit";

	private var _node:Node;
	private var _name:String;

	private var _assignedValueGetter:Function;
	private var _assignedValueSetter:Function;
	private var _assignedDispatcher:EventDispatcher;

	private var _assign:String;
	private var _styleable:Boolean;
	private var _style:String;
	private var _inheritable:Boolean;
	private var _inherit:String;
	private var _initial:String;

	public function Attribute(node:Node, name:String, initial:String = null, inheritable:Boolean = false, styleable:Boolean = true, getter:Function = null, setter:Function = null, dispatcher:EventDispatcher = null)
	{
		if (node == null) throw new ArgumentError("Parameter node must be non-null");
		if (name == null) throw new ArgumentError("Parameter name must be non-null");

		_node = node;
		_name = name;
		_initial = initial;
		_inheritable = inheritable;
		_styleable = styleable;

		if (_inheritable)
		{
			_node.addEventListener(Event.ADDED, onNodeAdded);
			_node.addEventListener(Event.REMOVED, onNodeRemoved);
		}

		_assignedValueGetter = getter;
		_assignedValueSetter = setter;
		_assignedDispatcher = dispatcher;
		_assignedDispatcher && _assignedDispatcher.addEventListener(Event.CHANGE, onAssignedChange);
	}

	private function onAssignedChange(e:Event):void
	{
		_assign = _assignedValueGetter();
		dispatchChange();
	}

	//
	// Inherit observation
	//
	private function onNodeAdded(e:Event):void
	{
		_node.parent.addEventListener(Event.CHANGE, onParentNodeChange);
		setInheritValue(_node.parent.getAttribute(name));
	}

	private function onNodeRemoved(e:Event):void
	{
		_node.parent.removeEventListener(Event.CHANGE, onParentNodeChange);
		setInheritValue(null);
	}

	private function onParentNodeChange(e:Event):void
	{
		if (e.data == name)
		{
			setInheritValue(_node.parent.getAttribute(name));
		}
	}

	//
	// Properties
	//
	public function get name():String
	{
		return _name;
	}

	public function get value():String
	{
		return isInherit ? _inherit : (_assign || (_styleable ? _style : null) || _initial);
	}

	public function setAssignedValue(value:String):void
	{
		if (_assignedValueSetter != null)
		{
			_assignedValueSetter(value);
		}
		else if (_assign != value)
		{
			_assign = value;
			dispatchChange();
		}
	}

	public function setStyledValue(value:String):void
	{
		if (_style != value)
		{
			_style = value;

			if (_styleable && _assign == null)
			{
				if (_assignedValueSetter != null)
				{
					// Для того что бы в onAssignedChange не установилось значение _assign
					_assignedDispatcher.removeEventListener(Event.CHANGE, onAssignedChange);
					_assignedValueSetter(this.value);
					_assignedDispatcher.addEventListener(Event.CHANGE, onAssignedChange);
				}

				dispatchChange();
			}
		}
	}

	private function setInheritValue(value:String):void
	{
		if (_inherit != value)
		{
			_inherit = value;
			isInherit && dispatchChange();
		}
	}

	/** Value must be inherit from parent. */
	public function get isInherit():Boolean
	{
		return _inheritable && (_assign || (_styleable ? _style : null) || _initial) == INHERIT;
	}

	private function dispatchChange():void
	{
		_node.dispatchEventWith(Event.CHANGE, false, name);
	}
}