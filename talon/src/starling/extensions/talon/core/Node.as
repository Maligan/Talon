package starling.extensions.talon.core
{
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;

	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.extensions.talon.layout.Layout;
	import starling.extensions.talon.utils.FillMode;
	import starling.extensions.talon.utils.Orientation;
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
			bind("width", Gauge.AUTO, true, width);
			bind("minWidth", Gauge.NONE, true, minWidth);
			bind("maxWidth", Gauge.NONE, true, maxWidth);
			bind("height", Gauge.AUTO, true, height);
			bind("minHeight", Gauge.NONE, true, minHeight);
			bind("maxHeight", Gauge.NONE, true, maxHeight);

			// Margin
			bind("margin", ZERO, true, margin);
			bind("marginTop", ZERO, true, margin.top);
			bind("marginRight", ZERO, true, margin.right);
			bind("marginBottom", ZERO, true, margin.bottom);
			bind("marginLeft", ZERO, true, margin.left);

			// Padding
			bind("padding", ZERO, true, padding);
			bind("paddingTop", ZERO, true, padding.top);
			bind("paddingRight", ZERO, true, padding.right);
			bind("paddingBottom", ZERO, true, padding.bottom);
			bind("paddingLeft", ZERO, true, padding.left);

			// Anchor (Absolute Position)
			bind("anchor", Gauge.NONE, true, anchor);
			bind("anchorTop", Gauge.NONE, true, anchor.top);
			bind("anchorRight", Gauge.NONE, true, anchor.right);
			bind("anchorBottom", Gauge.NONE, true, anchor.bottom);
			bind("anchorLeft", Gauge.NONE, true, anchor.left);

			// Background
			bind("backgroundImage", NULL, true);
			bind("backgroundTint", WHITE, true);
			bind("background9Scale", ZERO, true);
			bind("backgroundColor", TRANSPARENT, true);
			bind("backgroundFillMode", FillMode.SCALE, true);

			// Font
			bind("fontColor", Attribute.INHERIT, true);
			bind("fontName", Attribute.INHERIT, true);
			bind("fontSize", Attribute.INHERIT, true);

			// Style (Block styling)
			bind("id", NULL, false);
			bind("type", NULL, false);
			bind("class", NULL, false);
			bind("status", NULL, false);

			// Layout
			bind("layout", Layout.FLOW, true);
			bind("visibility", Visibility.VISIBLE, true);

			bind("orientation", Orientation.HORIZONTAL, true);
			bind("halign", HAlign.LEFT, true);
			bind("valign", VAlign.TOP, true);
			bind("gap", ZERO, true);
			bind("interline", ZERO, true);

			bind("position", ZERO, true, position);
			bind("x", ZERO, true, position.x);
			bind("y", ZERO, true, position.y);

			bind("pivot", ZERO, true, pivot);
			bind("pivotX", ZERO, true, pivot.x);
			bind("pivotY", ZERO, true, pivot.y);

			bind("origin", ZERO, true, origin);
			bind("originX", ZERO, true, origin.x);
			bind("originY", ZERO, true, origin.y);
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
				if (value.indexOf("resource") == 0) dispatchEventWith(Event.CHANGE, false, attribute.name);
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
		/** Actual node bounds, calculated by parent. */
		public function get bounds():Rectangle
		{
			return _bounds;
		}

		/** Apply bounds changes: dispatch RESIZE event, arrange children. */
		public function commit():void
		{
			// Update self view object attached to node
			dispatchEventWith(Event.RESIZE);
			// Update children nodes
			layout.arrange(this, bounds.width, bounds.height);
		}

		/** Pixel per point. (Also known as (csf) content scale factor) */
		public function get pppt():Number { return Starling.current.contentScaleFactor; }
		/** Pixels per millimeter (in current node). */
		public function get ppmm():Number { return Capabilities.screenDPI / 25.4; }
		/** Current node 'fontSize' expressed in pixels.*/
		public function get ppem():Number
		{
			var attribute:Attribute = _attributes["fontSize"];
			if (attribute.isInherit) return parent?parent.ppem:12;
			var gauge:Gauge = new Gauge();
			gauge.parse(attribute.value);
			var base:Number = parent?parent.ppem:12;
			return gauge.toPixels(ppmm, base, pppt, base, 0, 0, 0, 0);
		}

		private function measureAutoWidth(width:Number, height:Number):Number { return layout.measureAutoWidth(this, width, height); }
		private function measureAutoHeight(width:Number, height:Number):Number { return layout.measureAutoHeight(this, width, height); }
		private function get layout():Layout { return Layout.getLayoutByAlias(getAttribute("layout")); }

		private function onChildAttributeChange(e:Event):void
		{
			var invalidate:Boolean = Layout.isChildAttribute(getAttribute("layout"), e.data as String);
			if (invalidate)
			{
				trace("Rearrage");
			}
		}

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
			child.resource();
			child.addEventListener(Event.CHANGE, onChildAttributeChange);
			child.dispatchEventWith(Event.ADDED);
		}

		public function removeChild(child:Node):void
		{
			var indexOf:int = _children.indexOf(child);
			if (indexOf == -1) throw new ArgumentError("");
			_children.splice(indexOf, 1);
			child.removeEventListener(Event.CHANGE, onChildAttributeChange);
			child.dispatchEventWith(Event.REMOVED);
			child._parent = null;
			child.restyle();
			child.resource();
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