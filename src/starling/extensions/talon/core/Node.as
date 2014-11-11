package starling.extensions.talon.core
{
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;

	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.extensions.talon.layout.Layout;
	import starling.extensions.talon.utils.Visibility;

	public final class Node extends EventDispatcher
	{
		//
		// Strong typed attributes/styles
		//
		public const width:Gauge = new Gauge();
		public const minWidth:Gauge = new Gauge();
		public const maxWidth:Gauge = new Gauge();

		public const height:Gauge = new Gauge();
		public const minHeight:Gauge = new Gauge();
		public const maxHeight:Gauge = new Gauge();

		public const margin:GaugeQuad = new GaugeQuad();
		public const padding:GaugeQuad = new GaugeQuad();

		//
		// Private properties
		//
		private var _attributes:Dictionary = new Dictionary();
		private var _classes:StyleSheet;
		private var _resources:Object;
		private var _parent:Node;
		private var _children:Vector.<Node> = new Vector.<Node>();
		private var _bounds:Rectangle = new Rectangle();

		public function Node():void
		{
			width.auto = measureAutoWidth;
			height.auto = measureAutoHeight;

			// Bounds
			bind("width", Gauge.AUTO, width.toString, width.parse, width);
			bind("minWidth", Gauge.AUTO, minWidth.toString, minWidth.parse, minWidth);
			bind("maxWidth", Gauge.AUTO, maxWidth.toString, maxWidth.parse, maxWidth);
			bind("height", Gauge.AUTO, height.toString, height.parse, height);
			bind("minHeight", Gauge.AUTO, minHeight.toString, minHeight.parse, minHeight);
			bind("maxHeight", Gauge.AUTO, maxHeight.toString, maxHeight.parse, maxHeight);

			// Margin
			bind("margin", Gauge.AUTO, margin.toString, margin.parse, margin);
			bind("marginTop", Gauge.AUTO, margin.top.toString, margin.top.parse, margin.top);
			bind("marginRight", Gauge.AUTO, margin.right.toString, margin.right.parse, margin.right);
			bind("marginBottom", Gauge.AUTO, margin.bottom.toString, margin.bottom.parse, margin.bottom);
			bind("marginLeft", Gauge.AUTO, margin.left.toString, margin.left.parse, margin.left);

			// Padding
			bind("padding", Gauge.AUTO, padding.toString, padding.parse, padding);
			bind("paddingTop", Gauge.AUTO, padding.top.toString, padding.top.parse, padding.top);
			bind("paddingRight", Gauge.AUTO, padding.right.toString, padding.right.parse, padding.right);
			bind("paddingBottom", Gauge.AUTO, padding.bottom.toString, padding.bottom.parse, padding.bottom);
			bind("paddingLeft", Gauge.AUTO, padding.left.toString, padding.left.parse, padding.left);

			// Background
//			bind("backgroundImage", "none");
//			bind("background9Scale", "0px");
//			bind("backgroundColor", "transparent");
//			bind("backgroundScale", "0px 0px 0px 0px");
			bind("backgroundChromeColor", "#FFFFFF");

			// Style
			// ...

			// Font
			bind("fontColor", Attribute.INHERIT);
			bind("fontName", Attribute.INHERIT);
			bind("fontSize", Attribute.INHERIT);

			// Layout
			bind("layout", "flow");
			bind("visibility", Visibility.VISIBLE);
		}

		private function bind(name:String, initial:String = null, getter:Function = null, setter:Function = null, dispatcher:EventDispatcher = null):void
		{
			_attributes[name] = new Attribute(this, name, initial, getter, setter, dispatcher);
		}

		//
		// Attributes
		//
		public function getAttribute(name:String, inherit:Boolean = true):String
		{
			var attribute:Attribute = _attributes[name];
			return attribute ? attribute.value : null;
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
			_classes = style;
			restyle();
		}

		public function getStyle(node:Node):Object
		{
			if (_classes == null && _parent != null) return _parent.getStyle(node);
			if (_classes != null && _parent == null) return _classes.getStyle(node);
			if (_classes != null && _parent != null) return _classes.getStyle(node, _parent.getStyle(node));
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

		public function get classes():Vector.<String> { return Vector.<String>(getAttribute("class") ? getAttribute("class").split(" ") : []) }
		public function set classes(value:Vector.<String>):void { setAttribute("states", value.join(" ")); restyle(); }

		public function get states():Vector.<String> { return Vector.<String>(getAttribute("states") ? getAttribute("states").split(" ") : []) }
		public function set states(value:Vector.<String>):void { setAttribute("states", value.join(" ")); restyle(); }

		//
		// Resource
		//
		/** Set current node resources (an object containing key-value pairs). */
		public function setResources(resources:Object):void
		{
			_resources = resources;
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

		//
		// Layout
		//
		/** Actual node bounds, calculated by parent. */
		public function get bounds():Rectangle
		{
			return _bounds;
		}

		/** Apply bounds changes: dispatch RESIZE event, arrange children. */
		public function commit():void
		{
			dispatchEventWith(Event.RESIZE);
			layout.arrange(this, bounds.width, bounds.height);
		}

		public function get ppem():Number
		{
			var attribute:Attribute = _attributes["fontSize"];
			if (attribute.isInherit && parent) return parent.ppem;
			if (attribute.isInherit) return 12;
			var gauge:Gauge = new Gauge();
			gauge.parse(attribute.value);
			var base:Number = parent?parent.ppem:12;
			return gauge.toPixels(ppp, base, base, 0);
		}

		public function get ppp():Number { return Capabilities.screenDPI / 72; }

		private function measureAutoWidth():Number { return layout.measureAutoWidth(this); }
		private function measureAutoHeight():Number { return layout.measureAutoHeight(this); }
		private function get layout():Layout { return Layout.getLayoutByAlias(getAttribute("layout")); }

		//
		// Complex
		//
		public function get parent():Node { return _parent; }
		public function get numChildren():int { return _children.length; }

		public function addChild(child:Node):void
		{
			_children.push(child);
			child._parent = this;
			if (_classes) child.setStyleSheet(_classes);
			child.dispatchEventWith(Event.ADDED);
		}

		public function getChildAt(index:int):Node
		{
			return _children[index];
		}
	}
}

import starling.events.Event;
import starling.events.EventDispatcher;
import starling.extensions.talon.core.Node;

/** @private */
internal class Attribute
{
	public static const INHERIT:String = "inherit";
	public static const INITIAL:String = "initial";

	private var _node:Node;
	private var _name:String;

	private var _assignedValueGetter:Function;
	private var _assignedValueSetter:Function;
	private var _assignedDispatcher:EventDispatcher;

	private var _value:String;
	private var _assign:String;
	private var _style:String;
	private var _initial:String;

	public function Attribute(node:Node, name:String, initial:String = null, getter:Function = null, setter:Function = null, dispatcher:EventDispatcher = null)
	{
		if (node == null) throw new ArgumentError("Parameter node must be non-null");
		if (name == null) throw new ArgumentError("Parameter name must be non-null");

		_name = name;
		_initial = initial;

		_node = node;
		_node.addEventListener(Event.ADDED, onNodeParentChange);
		_node.addEventListener(Event.REMOVED, onNodeParentChange);

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

	private function onNodeParentChange(e:Event):void
	{
		_node.parent.addEventListener(Event.CHANGE, onParentNodeChange);

		var isInherit:Boolean = (_assign || _style || _initial) == INHERIT;
		if (isInherit)
		{
			dispatchChange();
		}
	}

	private function onParentNodeChange(e:Event):void
	{
		if (e.data == name)
		{
			var isInherit:Boolean = (_assign || _style || _initial) == INHERIT;
			if (isInherit)
			{
				dispatchChange();
			}
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
		if (_value == null)
		{
			if (isInherit)
			{
				_value = _node.parent ? _node.parent.getAttribute(name) : null;
			}
			else if (isInitial)
			{
				_value = _initial;
			}
			else
			{
				_value = _assign || _style || _initial;
			}
		}

		return _value;
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

			if (_assign == null)
			{
				if (_assignedValueSetter != null)
				{
					// Для того что бы в onAssignedChange не установилось значение _assign
					_assignedDispatcher.removeEventListener(Event.CHANGE, onAssignedChange);
					_assignedValueSetter(value);
					_assignedDispatcher.addEventListener(Event.CHANGE, onAssignedChange);
				}

				dispatchChange();
			}
		}
	}

	/** Value must be inherit from parent. */
	public function get isInherit():Boolean
	{
		return (_assign || _style || _initial) == INHERIT;
	}

	/** Value must be initial value. */
	public function get isInitial():Boolean
	{
		return (_assign || _style) == INITIAL;
	}

	private function dispatchChange():void
	{
		_value = null;
		_node.dispatchEventWith(Event.CHANGE, false, name);
	}
}