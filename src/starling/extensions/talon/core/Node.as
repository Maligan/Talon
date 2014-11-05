package starling.extensions.talon.core
{
	import flash.geom.Rectangle;

	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.extensions.talon.layout.Layout;

	public final class Node extends EventDispatcher
	{
		/** Proxy for all attributes. */
		public const attributes:Object = new Attributes(onAttributeChanged);

		//
		// Strong typed attributes (NB! all of them have _synchronized_ analog in attributes)
		// Be aware, delete & reset to default available only from attribute.
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
		private var _mappings:Vector.<String> = new Vector.<String>();

		public function Node():void
		{
			// Bounds
			map("width", width.toString, width.parse, width, "auto");
			map("minWidth", minWidth.toString, minWidth.parse, minWidth, "auto");
			map("maxWidth", maxWidth.toString, maxWidth.parse, maxWidth, "auto");
			map("height", height.toString, height.parse, height, "auto");
			map("minHeight", minHeight.toString, minHeight.parse, minHeight, "auto");
			map("maxHeight", maxHeight.toString, maxHeight.parse, maxHeight, "auto");

			// Margin
			map("margin", margin.toString, margin.parse, margin, "auto");
			map("marginTop", margin.top.toString, margin.top.parse, margin.top, "auto");
			map("marginRight", margin.right.toString, margin.right.parse, margin.right, "auto");
			map("marginBottom", margin.bottom.toString, margin.bottom.parse, margin.bottom, "auto");
			map("marginLeft", margin.left.toString, margin.left.parse, margin.left, "auto");

			// Padding
			map("padding", padding.toString, padding.parse, padding, "auto");
			map("paddingTop", padding.top.toString, padding.top.parse, padding.top, "auto");
			map("paddingRight", padding.right.toString, padding.right.parse, padding.right, "auto");
			map("paddingBottom", padding.bottom.toString, padding.bottom.parse, padding.bottom, "auto");
			map("paddingLeft", padding.left.toString, padding.left.parse, padding.left, "auto");

			// Background
			// ...

			// Style
			// ...

			// Layout
			// ...
		}

		private function map(name:String, getter:Function, setter:Function, dispatcher:EventDispatcher, defaultValue:String):void
		{
			_mappings.push(name);

			Attributes(attributes).setGetter(name, getter);
			Attributes(attributes).setSetter(name, setter);
			Attributes(attributes).setDefault(name, defaultValue);
			dispatcher.addEventListener(Event.CHANGE, handler);

			function handler(e:Event):void
			{
				Attributes(attributes).setChanged(name);
				dispatchEventWith(Event.CHANGE, false, name);
			}
		}

		private function onAttributeChanged(name:String):void
		{
			dispatchEventWith(Event.CHANGE, false, name);
		}

		//
		// Styling
		//
		public function setStyleSheet(style:StyleSheet):void
		{
			_style = style;
			Attributes(attributes).setStyle(this, _style);

			for each (var name:String in _mappings)
			{
				var styleValue:String = style.getStyle(this, name);
				if (styleValue != null)
				{
					attributes[name] = styleValue;
				}
			}
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
			return Layout.getLayoutByAlias(attributes.layout || "none");
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

import flash.utils.Dictionary;
import flash.utils.Proxy;
import flash.utils.flash_proxy;

import starling.extensions.talon.core.Node;

import starling.extensions.talon.core.StyleSheet;

use namespace flash_proxy;

class Attributes extends Proxy
{
	private var _setters:Dictionary;
	private var _getters:Dictionary;
	private var _default:Dictionary;
	private var _changed:Dictionary;
	private var _object:Object;

	private var _style:StyleSheet;
	private var _node:Node;

	private var _handler:Function;

	public function Attributes(handler:Function)
	{
		_setters = new Dictionary();
		_getters = new Dictionary();
		_changed = new Dictionary();
		_default = new Dictionary();
		_object = new Object();
		_handler = handler;
	}

	public function setSetter(name:String, setter:Function):void
	{
		_setters[name] = setter;
	}

	public function setGetter(name:String, getter:Function):void
	{
		_getters[name] = getter;
	}

	public function setDefault(name:String, value:String):void
	{
		_default[name] = value;
	}

	public function setChanged(name:String):void
	{
		_changed[name] = true;
	}

	public function setStyle(node:Node, style:StyleSheet):void
	{
		_node = node;
		_style = style;
	}

	flash_proxy override function setProperty(name:*, value:*):void
	{
		if (_setters[name])
		{
			_setters[name](value);
		}
		else if (_object[name] != value)
		{
			_object[name] = value;
			_handler(name);
		}
	}

	flash_proxy override function getProperty(name:*):*
	{
		if (_getters[name] != null && _changed[name] === true)
		{
			return _getters[name]();
		}
		else if (_object[name])
		{
			return _object[name]
		}
		else if (name != "id" && name != "class" && name != "tag"  && _style != null)
		{
			return _style.getStyle(_node, name) || _default[name];
		}

		return _default[name];
	}
}