package starling.extensions.talon.core
{
	import starling.events.Event;
	import starling.events.EventDispatcher;

	public final class Node extends EventDispatcher
	{
		//
		// Strong typed attributes (NB! all of them have _synchronized_ analog in attributes)
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

		/** Proxy for all attributes. */
		public const attributes:Object = new Attributes(onAttributeChanged);

		public function Node():void
		{
			// Bounds
			map("width", width.toString, width.parse, width);
			map("minWidth", minWidth.toString, minWidth.parse, minWidth);
			map("maxWidth", maxWidth.toString, maxWidth.parse, maxWidth);
			map("height", height.toString, height.parse, height);
			map("minHeight", minHeight.toString, minHeight.parse, minHeight);
			map("maxHeight", maxHeight.toString, maxHeight.parse, maxHeight);

			// Margin
			map("margin", margin.toString, margin.parse, margin);
			map("marginTop", margin.top.toString, margin.top.parse, margin.top);
			map("marginRight", margin.right.toString, margin.right.parse, margin.right);
			map("marginBottom", margin.bottom.toString, margin.bottom.parse, margin.bottom);
			map("marginLeft", margin.left.toString, margin.left.parse, margin.left);

			// Padding
			map("padding", padding.toString, padding.parse, padding);
			map("paddingTop", padding.top.toString, padding.top.parse, padding.top);
			map("paddingRight", padding.right.toString, padding.right.parse, padding.right);
			map("paddingBottom", padding.bottom.toString, padding.bottom.parse, padding.bottom);
			map("paddingLeft", padding.left.toString, padding.left.parse, padding.left);

			// Background
			// ...

			// Style
			// ...
			map("class", )
		}

		private function map(name:String, getter:Function, setter:Function, dispatcher:EventDispatcher):void
		{
			Attributes(attributes).setGetter(name, getter);
			Attributes(attributes).setSetter(name, setter);
			dispatcher.addEventListener(Event.CHANGE, handler);

			function handler(e:Event):void
			{
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
	private var _dispatch:Function;
	private var _object:Object;

	public function Attributes(dispatch:Function)
	{
		_setters = new Dictionary();
		_getters = new Dictionary();
		_dispatch = dispatch;
		_object = new Object();
	}

	public function setSetter(name:String, setter:Function):void
	{
		_setters[name] = setter;
	}

	public function setGetter(name:String, getter:Function):void
	{
		_getters[name] = getter;
	}

	flash_proxy override function setProperty(name:*, value:*):void
	{
		if (flash_proxy::getProperty(name) != value)
		{
			if (_setters[name])
			{
				_setters[name](value);
			}
			else
			{
				_object[name] = value;
				_dispatch(name);
			}
		}
	}

	flash_proxy override function getProperty(name:*):*
	{
		return _getters[name]
			 ? _getters[name]()
			 : _object[name];
	}
}