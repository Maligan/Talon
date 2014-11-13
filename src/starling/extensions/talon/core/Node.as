package starling.extensions.talon.core
{
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;

	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.extensions.talon.layout.Layout;
	import starling.extensions.talon.utils.Visibility;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

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
		private var _style:StyleSheet;
		private var _resources:Object;
		private var _parent:Node;
		private var _children:Vector.<Node> = new Vector.<Node>();
		private var _bounds:Rectangle = new Rectangle();

		public function Node():void
		{
			const ZERO:String = "0px";
			const TRANSPARENT:String = "transparent";
			const WHITE:String = "white";
			const NULL:String = null;

			width.auto = minWidth.auto = maxWidth.auto = measureAutoWidth;
			height.auto = minHeight.auto = maxHeight.auto = measureAutoHeight;

			// Bounds
			bind("width", Gauge.AUTO, width.toString, width.parse, width);
			bind("minWidth", Gauge.AUTO, minWidth.toString, minWidth.parse, minWidth);
			bind("maxWidth", Gauge.AUTO, maxWidth.toString, maxWidth.parse, maxWidth);
			bind("height", Gauge.AUTO, height.toString, height.parse, height);
			bind("minHeight", Gauge.AUTO, minHeight.toString, minHeight.parse, minHeight);
			bind("maxHeight", Gauge.AUTO, maxHeight.toString, maxHeight.parse, maxHeight);

			// Margin
			bind("margin", ZERO, margin.toString, margin.parse, margin);
			bind("marginTop", ZERO, margin.top.toString, margin.top.parse, margin.top);
			bind("marginRight", ZERO, margin.right.toString, margin.right.parse, margin.right);
			bind("marginBottom", ZERO, margin.bottom.toString, margin.bottom.parse, margin.bottom);
			bind("marginLeft", ZERO, margin.left.toString, margin.left.parse, margin.left);

			// Padding
			bind("padding", ZERO, padding.toString, padding.parse, padding);
			bind("paddingTop", ZERO, padding.top.toString, padding.top.parse, padding.top);
			bind("paddingRight", ZERO, padding.right.toString, padding.right.parse, padding.right);
			bind("paddingBottom", ZERO, padding.bottom.toString, padding.bottom.parse, padding.bottom);
			bind("paddingLeft", ZERO, padding.left.toString, padding.left.parse, padding.left);

			// Background
			bind("backgroundImage", NULL);
			bind("background9Scale", ZERO);
			bind("backgroundColor", TRANSPARENT);
			bind("backgroundChromeColor", WHITE);

			// Font
			bind("fontColor", Attribute.INHERIT);
			bind("fontName", Attribute.INHERIT);
			bind("fontSize", Attribute.INHERIT);

			// Layout
			bind("visibility", Visibility.VISIBLE);
			bind("layout", Layout.FLOW);
			bind("halign", HAlign.LEFT);
			bind("valign", VAlign.TOP);
			bind("gap", ZERO);
		}

		private function bind(name:String, initial:String, getter:Function = null, setter:Function = null, dispatcher:EventDispatcher = null):void
		{
			setter && setter(initial);
			_attributes[name] = new Attribute(this, name, initial, initial == Attribute.INHERIT, getter, setter, dispatcher);
		}

		//
		// Attributes
		//
		public function getAttribute(name:String):String
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
		public function get classes():Vector.<String> { return Vector.<String>(getAttribute("class") ? getAttribute("class").split(" ") : []) }
		public function set classes(value:Vector.<String>):void { setAttribute("states", value.join(" ")); restyle(); }

		/** Current active CSS pseudoClasses. */
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

		public function get pppt():Number { return Capabilities.screenDPI / 72; }
		public function get ppem():Number
		{
			var attribute:Attribute = _attributes["fontSize"];
			if (attribute.isInherit) return parent?parent.ppem:12;
			var gauge:Gauge = new Gauge();
			gauge.parse(attribute.value);
			var base:Number = parent?parent.ppem:12;
			return gauge.toPixels(pppt, base, base, 0);
		}

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
			child.restyle();
			child.dispatchEventWith(Event.ADDED);
		}

		public function removeChild(child:Node):void
		{
			var indexOf:int = _children.indexOf(child);
			if (indexOf == -1) throw new ArgumentError("");
			_children.splice(indexOf, 1);
			child.dispatchEventWith(Event.REMOVED);
			child._parent = null;
			child.restyle();
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

	private var _inheritable:Boolean;
	private var _inherit:String;
	private var _assign:String;
	private var _style:String;
	private var _initial:String;

	public function Attribute(node:Node, name:String, initial:String = null, inheritable:Boolean = false, getter:Function = null, setter:Function = null, dispatcher:EventDispatcher = null)
	{
		if (node == null) throw new ArgumentError("Parameter node must be non-null");
		if (name == null) throw new ArgumentError("Parameter name must be non-null");

		_node = node;
		_name = name;
		_initial = initial;
		_inheritable = inheritable;

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
		return isInherit ? _inherit : (_assign || _style || _initial);
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
		return _inheritable && (_assign || _style || _initial) == INHERIT;
	}

	private function dispatchChange():void
	{
		_node.dispatchEventWith(Event.CHANGE, false, name);
	}
}