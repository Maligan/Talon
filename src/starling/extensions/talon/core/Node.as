package starling.extensions.talon.core
{
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.extensions.talon.layout.Layout;

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
		private var _bounds:Rectangle = new Rectangle();
		private var _style:StyleSheet;
		private var _parent:Node;
		private var _children:Vector.<Node> = new Vector.<Node>();
		private var _attributes:Dictionary = new Dictionary();
		private var _resources:Object;

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
//			map("backgroundImage", "none");
//			map("backgroundColor", "transparent");
//			map("backgroundScale", "0px 0px 0px 0px");

			// Style
			// ...

			// Font
			bind("fontColor", Attribute.INHERIT);
			bind("fontName", Attribute.INHERIT);
			bind("fontSize", Attribute.INHERIT);

			// Layout
			bind("layout", "none");
		}

		private function bind(name:String, defaultValue:String = null, assignedGetter:Function = null, assignedSetter:Function = null, assignedDispatcher:EventDispatcher = null):void
		{
			_attributes[name] = new Attribute(this, name, defaultValue, assignedGetter, assignedSetter, assignedDispatcher);
		}

		private function onAttributeChange(name:String):void
		{
			dispatchEventWith(Event.CHANGE, false, name);
		}

		//
		// Styling
		//
		public function setStyleSheet(style:StyleSheet):void
		{
			_style = style;

			var styles:Object = _style.getStyle(this);
			for each (var attribute:Attribute in _attributes)
			{
				attribute.setStyledValue(styles[attribute.name]);
				delete styles[attribute.name];
			}

			for (var name:String in styles)
			{
				attribute = _attributes[name] || (_attributes[name] = new Attribute(this, name));
				attribute.setStyledValue(styles[name]);
			}

			for each (var child:Node in _children)
			{
				child.setStyleSheet(style);
			}
		}

		public function getAttribute(name:String, defaultValue:String = null):String
		{
			var attribute:Attribute = _attributes[name];
			if (attribute) return attribute.value || defaultValue;
			return defaultValue;
		}

		public function setAttribute(name:String, value:String):void
		{
			var attribute:Attribute = _attributes[name];
			if (attribute == null) attribute = _attributes[name] = new Attribute(this, name);
			attribute.setAssignedValue(value);
		}

		//
		// Resource
		//
		/** Set current node resources (an object containing key-value pairs). */
		public function setResources(resources:Object):void { _resources = resources; }
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
		public function get bounds():Rectangle { return _bounds; }
		/** Apply bounds changes, dispatch RESIZE event & arrange children. */
		public function commit():void
		{
			dispatchEventWith(Event.RESIZE);
			layout.arrange(this, 0, 0, bounds.width, bounds.height);
		}

		private function measureAutoWidth():Number { return layout.measureAutoWidth(this, 0, 0); }
		private function measureAutoHeight():Number { return layout.measureAutoHeight(this, 0, 0); }
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
			if (_style) child.setStyleSheet(_style);
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

	private var _node:Node;
	private var _name:String;

	private var _assignedValueGetter:Function;
	private var _assignedValueSetter:Function;
	private var _assignedDispatcher:EventDispatcher;

	private var _value:String;
	private var _assignedValue:String;
	private var _styledValue:String;
	private var _defaultValue:String;

	public function Attribute(node:Node, name:String, defaultValue:String = null, getter:Function = null, setter:Function = null, dispatcher:EventDispatcher = null)
	{
		_name = name;
		_defaultValue = defaultValue;

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
		_assignedValue = _assignedValueGetter();
		dispatchChange();
	}

	private function onNodeParentChange(e:Event):void
	{
		_node.parent.addEventListener(Event.CHANGE, onParentNodeChange);

		var isInherit:Boolean = (_assignedValue || _styledValue || _defaultValue) == INHERIT;
		if (isInherit)
		{
			dispatchChange();
		}
	}

	private function onParentNodeChange(e:Event):void
	{
		if (e.data == name)
		{
			var isInherit:Boolean = (_assignedValue || _styledValue || _defaultValue) == INHERIT;
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
				_value = _node.parent ? _node.parent.getAttribute(name) : INHERIT;
			}
			else
			{
				_value = _assignedValue || _styledValue || _defaultValue;
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
		else if (_assignedValue != value)
		{
			_assignedValue = value;
			dispatchChange();
		}
	}

	public function setStyledValue(value:String):void
	{
		if (_styledValue != value)
		{
			_styledValue = value;

			if (_assignedValue == null)
			{
				if (_assignedValueSetter != null)
				{
					// Для того что бы в onAssignedChange не установилось значение _assignedValue
					_assignedDispatcher.removeEventListener(Event.CHANGE, onAssignedChange);
					_assignedValueSetter(value);
					_assignedDispatcher.addEventListener(Event.CHANGE, onAssignedChange);
				}

				dispatchChange();
			}
		}
	}

	private function get isInherit():Boolean
	{
		return (_assignedValue || _styledValue || _defaultValue) == INHERIT;
	}

	private function dispatchChange():void
	{
		_value = null;
		_node.dispatchEventWith(Event.CHANGE, false, name);
	}
}