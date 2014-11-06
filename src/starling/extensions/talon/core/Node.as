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
		// Complex properties (components)
		//
		private var _bounds:Rectangle = new Rectangle();
		private var _style:StyleSheet;
		private var _parent:Node;
		private var _children:Vector.<Node> = new Vector.<Node>();
		private var _attributes:Dictionary = new Dictionary();

		public function Node():void
		{
			// Bounds
			map("width", "auto", width.toString, width.parse, width);
			map("minWidth", "auto", minWidth.toString, minWidth.parse, minWidth);
			map("maxWidth", "auto", maxWidth.toString, maxWidth.parse, maxWidth);
			map("height", "auto", height.toString, height.parse, height);
			map("minHeight", "auto", minHeight.toString, minHeight.parse, minHeight);
			map("maxHeight", "auto", maxHeight.toString, maxHeight.parse, maxHeight);

			// Margin
			map("margin", "auto", margin.toString, margin.parse, margin);
			map("marginTop", "auto", margin.top.toString, margin.top.parse, margin.top);
			map("marginRight", "auto", margin.right.toString, margin.right.parse, margin.right);
			map("marginBottom", "auto", margin.bottom.toString, margin.bottom.parse, margin.bottom);
			map("marginLeft", "auto", margin.left.toString, margin.left.parse, margin.left);

			// Padding
			map("padding", "auto", padding.toString, padding.parse, padding);
			map("paddingTop", "auto", padding.top.toString, padding.top.parse, padding.top);
			map("paddingRight", "auto", padding.right.toString, padding.right.parse, padding.right);
			map("paddingBottom", "auto", padding.bottom.toString, padding.bottom.parse, padding.bottom);
			map("paddingLeft", "auto", padding.left.toString, padding.left.parse, padding.left);

			// Background
			// ...

			// Style
			// ...

			// Layout
			map("layout", "none");
		}

		private function map(name:String, def:String = null, getter:Function = null, setter:Function = null, dispatcher:EventDispatcher = null):void
		{
			_attributes[name] = new Attribute(name, onAttributeChange, def, getter, setter, dispatcher);
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

			var styles:Object = _style.getStyles(this);
			for each (var attribute:Attribute in _attributes)
			{
				attribute.valueFromStyleSheet = styles[attribute.name];
				delete styles[attribute.name];
			}

			for (var name:String in styles)
			{
				attribute = _attributes[name] || (_attributes[name] = new Attribute(name, onAttributeChange));
				attribute.valueFromStyleSheet = styles[name];
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
			if (attribute == null) attribute = _attributes[name] = new Attribute(name, onAttributeChange);
			attribute.valueFromAssign = value;
		}

		//
		// Layout
		//
		public function get bounds():Rectangle
		{
			return _bounds;
		}

		public function commit():void
		{
			dispatchEventWith(Event.RESIZE);
			layout.arrange(this, 0, 0, bounds.width, bounds.height);
		}

		public function measureAutoWidth():Number
		{
			return layout.measureAutoWidth(this, 0, 0);
		}

		public function measureAutoHeight():Number
		{
			return layout.measureAutoHeight(this, 0, 0);
		}

		private function get layout():Layout
		{
			var aliasName:String = getAttribute("layout");
			return Layout.getLayoutByAlias(aliasName);
		}

		//
		// Complex
		//
		public function get numChildren():int
		{
			return _children.length;
		}

		public function addChild(child:Node):void
		{
			_children.push(child);
			child._parent = this;
			child.setStyleSheet(_style);
		}

		public function getChildAt(index:int):Node
		{
			return _children[index];
		}

		public function get parent():Node
		{
			return _parent;
		}
	}
}

import starling.events.Event;
import starling.events.EventDispatcher;

class Attribute
{
	private var _name:String;
	private var _handler:Function;

	private var _getter:Function;
	private var _setter:Function;
	private var _dispatcher:EventDispatcher;

	private var _valueFromAssign:String;
	private var _valueFromStyleSheet:String;
	private var _valueFromDefault:String;

	public function Attribute(name:String, handler:Function, def:String = null, getter:Function = null, setter:Function = null, dispatcher:EventDispatcher = null)
	{
		_name = name;
		_handler = handler;
		_valueFromDefault = def;

		_getter = getter;
		_setter = setter;
		_dispatcher = dispatcher;
		_dispatcher && _dispatcher.addEventListener(Event.CHANGE, onChanged);
	}

	private function onChanged(e:Event):void
	{
		_valueFromAssign = _getter();
		_handler(name);
	}

	//
	// Properties
	//
	public function get name():String { return _name }
	public function get value():String
	{
		return _valueFromAssign || _valueFromStyleSheet || _valueFromDefault
	}

	public function get valueFromAssign():String { return _valueFromAssign; }
	public function set valueFromAssign(value:String):void
	{
		if (_setter)
		{
			_setter(value);
		}
		else if (_valueFromAssign != value)
		{
			_valueFromAssign = value;
			_handler(name);
		}
	}

	public function get valueFromStyleSheet():String { return _valueFromStyleSheet }
	public function set valueFromStyleSheet(value:String):void
	{
		if (_valueFromStyleSheet != value)
		{
			_valueFromStyleSheet = value;

			if (_valueFromAssign == null)
			{
				if (_setter == null)
				{
					_handler(name);
				}
				else
				{
					_setter(value);
				}
			}
		}
	}
}