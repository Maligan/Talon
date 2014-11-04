package starling.extensions.talon.core
{
	import starling.events.Event;
	import starling.events.EventDispatcher;

	public final class Node extends EventDispatcher
	{
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

		public const layout:Layout = new Layout(this);
		public const children:Vector.<Node> = new Vector.<Node>();

		/** Sets of default values. */
		public const style:StyleSheet = new StyleSheet(this);

		/** Proxy for all attributes. */
		public const attributes:Object = new Attributes(onAttributeChanged);

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
		}

		private function map(name:String, getter:Function, setter:Function, dispatcher:EventDispatcher, defaultValue:String):void
		{
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
	}
}

import flash.utils.Dictionary;
import flash.utils.Proxy;
import flash.utils.flash_proxy;

use namespace flash_proxy;

class Attributes extends Proxy
{
	private var _setters:Dictionary;
	private var _getters:Dictionary;
	private var _default:Dictionary;
	private var _changed:Dictionary;

	private var _object:Object;

	private var _change:Function;

	public function Attributes(change:Function)
	{
		_setters = new Dictionary();
		_getters = new Dictionary();
		_changed = new Dictionary();
		_default = new Dictionary();
		_object = new Object();
		_change = change;
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

	flash_proxy override function setProperty(name:*, value:*):void
	{
		if (flash_proxy::getProperty(name) != value)
		{
			if (_setters[name])
			{
				_setters[name](value);
			}
			else if (_object[name] != value)
			{
				_object[name] = value;
				_change(name);
			}
		}
	}

	flash_proxy override function getProperty(name:*):*
	{
		return _getters[name]
			 ? _getters[name]()
			 : _object[name];
	}

	flash_proxy override function deleteProperty(name:*):Boolean
	{
		// Reset to default value (first set default, _setter can invoke event & set _changed property)
		_setters[name] && _default[name] && _setters[name](_default[name]);

		delete _changed[name];
		delete _object[name];

		return true;
	}
}