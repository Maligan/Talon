package talon
{
	import flash.events.Event;

	import talon.enums.*;
	import talon.layout.Layout;
	import talon.utils.*;

	public final class Attribute
	{
        public static const INHERIT:String      = "inherit";
        public static const NONE:String         = "none";

        private static const AUTO:String         = "auto";
        private static const FALSE:String        = "false";
        private static const TRUE:String         = "true";
        private static const ZERO:String         = "0px";
        private static const ZERO_PERCENTS:String = "0%";
        private static const ONE:String          = "1";
        private static const LEFT:String         = "left";
		private static const TOP:String          = "top";

		//
		// Standard Attribute list
		//
		public static const ID:String                   = registerAttributeDefaults("id",                  null,                     false,  false);
		public static const TYPE:String                 = registerAttributeDefaults("type",                null,                     false,  false);
		public static const CLASS:String                = registerAttributeDefaults("class",               null,                     false,  false);
		public static const STATE:String                = registerAttributeDefaults("state",               null,                     false,  false);

		public static const WIDTH:String                = registerAttributeDefaults("width",               NONE);
		public static const MIN_WIDTH:String            = registerAttributeDefaults("minWidth",            NONE);
		public static const MAX_WIDTH:String            = registerAttributeDefaults("maxWidth",            NONE);

		public static const HEIGHT:String               = registerAttributeDefaults("height",              NONE);
		public static const MIN_HEIGHT:String           = registerAttributeDefaults("minHeight",           NONE);
		public static const MAX_HEIGHT:String           = registerAttributeDefaults("maxHeight",           NONE);

		public static const MARGIN_TOP:String           = registerAttributeDefaults("marginTop",           ZERO);
		public static const MARGIN_RIGHT:String         = registerAttributeDefaults("marginRight",         ZERO);
		public static const MARGIN_BOTTOM:String        = registerAttributeDefaults("marginBottom",        ZERO);
		public static const MARGIN_LEFT:String          = registerAttributeDefaults("marginLeft",          ZERO);
		public static const MARGIN:String               = registerAttributeDefaults("margin",              ZERO,                     false,  true, [MARGIN_TOP, MARGIN_RIGHT, MARGIN_BOTTOM, MARGIN_LEFT]);

		public static const PADDING_TOP:String          = registerAttributeDefaults("paddingTop",          ZERO);
		public static const PADDING_RIGHT:String        = registerAttributeDefaults("paddingRight",        ZERO);
		public static const PADDING_BOTTOM:String       = registerAttributeDefaults("paddingBottom",       ZERO);
		public static const PADDING_LEFT:String         = registerAttributeDefaults("paddingLeft",         ZERO);
		public static const PADDING:String              = registerAttributeDefaults("padding",             ZERO,                     false,  true, [PADDING_TOP, PADDING_RIGHT, PADDING_BOTTOM, PADDING_LEFT]);

		public static const ANCHOR_TOP:String           = registerAttributeDefaults("anchorTop",           NONE);
		public static const ANCHOR_RIGHT:String         = registerAttributeDefaults("anchorRight",         NONE);
		public static const ANCHOR_BOTTOM:String        = registerAttributeDefaults("anchorBottom",        NONE);
		public static const ANCHOR_LEFT:String          = registerAttributeDefaults("anchorLeft",          NONE);
		public static const ANCHOR:String               = registerAttributeDefaults("anchor",              NONE,                     false,  true, [ANCHOR_TOP, ANCHOR_RIGHT, ANCHOR_BOTTOM, ANCHOR_LEFT]);

		public static const BACKGROUND_FILL:String                  = registerAttributeDefaults("backgroundFill",               NONE);
		public static const BACKGROUND_STRETCH_GRID_TOP:String          = registerAttributeDefaults("backgroundStretchGridTop",        NONE);
		public static const BACKGROUND_STRETCH_GRID_RIGHT:String          = registerAttributeDefaults("backgroundStretchGridRight",        NONE);
		public static const BACKGROUND_STRETCH_GRID_BOTTOM:String          = registerAttributeDefaults("backgroundStretchGridBottom",        NONE);
		public static const BACKGROUND_STRETCH_GRID_LEFT:String          = registerAttributeDefaults("backgroundStretchGridLeft",        NONE);
		public static const BACKGROUND_STRETCH_GRID:String          = registerAttributeDefaults("backgroundStretchGrid",        NONE, false, true, [BACKGROUND_STRETCH_GRID_TOP, BACKGROUND_STRETCH_GRID_RIGHT, BACKGROUND_STRETCH_GRID_BOTTOM, BACKGROUND_STRETCH_GRID_LEFT]);
		public static const BACKGROUND_ALPHA:String                 = registerAttributeDefaults("backgroundAlpha",              ONE);
		public static const BACKGROUND_FILL_MODE_HORIZONTAL:String  = registerAttributeDefaults("backgroundFillModeHorizontal", FillMode.STRETCH);
		public static const BACKGROUND_FILL_MODE_VERTICAL:String    = registerAttributeDefaults("backgroundFillModeVertical",   FillMode.STRETCH);
		public static const BACKGROUND_FILL_MODE:String             = registerAttributeDefaults("backgroundFillMode",           FillMode.STRETCH, false, true, [BACKGROUND_FILL_MODE_HORIZONTAL, BACKGROUND_FILL_MODE_VERTICAL]);

		public static const FONT_COLOR:String           = registerAttributeDefaults("fontColor",           INHERIT,                  true);
		public static const FONT_NAME:String            = registerAttributeDefaults("fontName",            INHERIT,                  true);
		public static const FONT_SIZE:String            = registerAttributeDefaults("fontSize",            INHERIT,                  true);
		public static const FONT_AUTO_SCALE:String      = registerAttributeDefaults("fontAutoScale",       INHERIT,                  true);
		public static const FONT_SHARPNESS:String       = registerAttributeDefaults("fontSharpness",       INHERIT,                  true);

		public static const ALPHA:String                = registerAttributeDefaults("alpha",               ONE);
		public static const CLIPPING:String             = registerAttributeDefaults("clipping",            FALSE);
		public static const BLEND_MODE:String           = registerAttributeDefaults("blendMode",           AUTO);
		public static const CURSOR:String               = registerAttributeDefaults("cursor",              AUTO);
		public static const FILTER:String               = registerAttributeDefaults("filter",              NONE);
		public static const Z_INDEX:String              = registerAttributeDefaults("zIndex",              ZERO);
		public static const VISIBLE:String              = registerAttributeDefaults("visible",             TRUE);
		public static const LAYOUT:String               = registerAttributeDefaults("layout",              Layout.FLOW);

		public static const X:String                    = registerAttributeDefaults("x",                   ZERO);
		public static const Y:String                    = registerAttributeDefaults("y",                   ZERO);
		public static const POSITION:String             = registerAttributeDefaults("position",            ZERO,                     false,  true, [X, Y]);

		public static const PIVOT_X:String              = registerAttributeDefaults("pivotX",              ZERO);
		public static const PIVOT_Y:String              = registerAttributeDefaults("pivotY",              ZERO);
		public static const PIVOT:String                = registerAttributeDefaults("pivot",               ZERO,                     false,  true, [PIVOT_X, PIVOT_Y]);

		public static const HALIGN:String               = registerAttributeDefaults("halign",              LEFT);
		public static const VALIGN:String               = registerAttributeDefaults("valign",              TOP);
		public static const ALIGN:String                = registerAttributeDefaults("align",               LEFT + " " + TOP,            false,  true, [HALIGN, VALIGN]);

		public static const ORIENTATION:String          = registerAttributeDefaults("orientation",         Orientation.HORIZONTAL);
		public static const IHALIGN:String              = registerAttributeDefaults("ihalign",             LEFT);
		public static const IVALIGN:String              = registerAttributeDefaults("ivalign",             TOP);
		public static const GAP:String                  = registerAttributeDefaults("gap",                 ZERO);
		public static const INTERLINE:String            = registerAttributeDefaults("interline",           ZERO);
		public static const WRAP:String                 = registerAttributeDefaults("wrap",                FALSE);
		public static const BREAK:String                = registerAttributeDefaults("break",               BreakMode.AUTO);

		public static const TEXT:String                 = registerAttributeDefaults("text");
		public static const SRC:String                  = registerAttributeDefaults("src");

		//
		// Defaults
		//
		private static var _defaults:Object;
		private static var _inheritable:Vector.<String>;
		private static var _composite:Vector.<String>;

		public static function registerAttributeDefaults(name:String, inited:String = null, isInheritable:Boolean = false, isStyleable:Boolean = true, format:Array = null):String
		{
			_defaults ||= new Object();
			_defaults[name] = {};
			_defaults[name].inited = inited;
			_defaults[name].isInheritable = isInheritable;
			_defaults[name].isStyleable = isStyleable;
			_defaults[name].format = format;

			if (isInheritable)
			{
				_inheritable ||= new <String>[];
				_inheritable[_inheritable.length] = name;
			}

			if (format)
			{
				_composite ||= new <String>[];
				_composite[_composite.length] = name;
			}

			return name;
		}

		/** @private */
		public static function getAttributeDefault(name:String, field:String, fallback:*):* { return _defaults[name] ? _defaults[name][field] : fallback; }

		/** @private */
		public static function getInheritableAttributeNames():Vector.<String> { return _inheritable || new Vector.<String>(); }

		/** @private */
		public static function getCompositeAttributeNames():Vector.<String> { return _composite || new Vector.<String>(); }

		//
		// Attribute Implementation
		//
		private var _node:Node;
		private var _name:String;
		private var _change:Trigger;

		private var _inited:IValue;
		private var _styled:IValue;
		private var _setted:IValue;
		private var _basic:ComplexValue;
		private var _value:InheritValue;

		private var _valueCache:*;
		private var _valueCached:Boolean;

		/** @private */
		public function Attribute(node:Node, name:String)
		{
			if (node == null) throw new ArgumentError("Parameter node must be non-null");
			if (name == null) throw new ArgumentError("Parameter name must be non-null");

			_node = node;
			_name = name;
			_change = new Trigger(this);

			_inited = newValue(node, name, "inited");
			_styled = newValue(node, name, "styled");
			_setted = newValue(node, name, "setted");
			_basic = new ComplexValue(_inited, _styled, _setted);
			_value = new InheritValue(_basic);
			_value.change.addListener(dispatchChange);

			inited = getAttributeDefault(name, "inited", null);
			isStyleable = getAttributeDefault(name, "isStyleable", true);
			isInheritable = getAttributeDefault(name, "isInheritable", false);
		}

		private function newValue(node:Node, name:String, type:String):IValue
		{
			var format:Array = _defaults[name] ? _defaults[name].format : null;
			if (format == null) return new SimpleValue();

			var values:Vector.<IValue> = new <IValue>[];
			for each (var attrName:String in format)
			{
				var attr:Attribute = node.getOrCreateAttribute(attrName);
				switch (type)
				{
					case "inited": values.push(attr._inited); break;
					case "styled": values.push(attr._styled); break;
					case "setted": values.push(attr._setted); break;
				}
			}

			return new BindedValue(values);
		}

		//
		// Value
		//
		/** The node that contains this attribute. */
		public function get node():Node { return _node; }

		/** Unique (in-node) attribute name. */
		public function get name():String { return _name; }

		/** Default attribute value. */
		public function get inited():String { return _inited.string; }
		public function set inited(value:String):void { _inited.string = value; }

		/** Attribute value from node style sheet. */
		public function get styled():String { return _styled.string }
		public function set styled(value:String):void { _styled.string = value; }

		/** Explicit setted attribute value via code or markup. */
		public function get setted():String { return _setted.string; }
		public function set setted(value:String):void { _setted.string = value; }

		/** Value calculated from inited->styled->setted. */
		public function get basic():String { return _basic.string; }
		/** Value calculated from basic & inherit parent attribute. */
		public function get value():String { return _value.string; }

		/** NB! Optimized <code>value</code>property. Witch can extract mapped resource. */
		public function get valueCache():*
		{
			if (_valueCached == false)
			{
				// By default is equal to value
				_valueCached = true;
				_valueCache = value;

				// Extract resource value
                // XXX: Stack overflow (loops)
				while (_valueCache is String)
				{
					var key:String = StringParseUtil.parseResource(_valueCache);
					if (key == null) break;

					_valueCache = node.getResource(key);
				}
			}

			return _valueCache;
		}

		//
		// Props
		//

		/** Use styled property when calculating attribute value. */
		public function get isStyleable():Boolean { return _basic.ignore == _styled; }
		public function set isStyleable(value:Boolean):void { _basic.ignore = value ? null : _styled; }

		/** If attribute value == 'inherit' concrete value must be taken from parent node. */
		public function get isInheritable():Boolean { return _value.isInheritable; }
		public function set isInheritable(value:Boolean):void
		{
			if (_value.isInheritable != value)
			{
				_value.isInheritable = value;

				if (value)
				{
					node.addTriggerListener(Event.ADDED,       onNodeAddedToParent);
					node.addTriggerListener(Event.REMOVED,     onNodeRemovedFromParent);
					if (node.parent) onNodeAddedToParent();
				}
				else
				{
					node.removeTriggerListener(Event.ADDED,    onNodeAddedToParent);
					node.removeTriggerListener(Event.REMOVED,  onNodeRemovedFromParent);
					onNodeRemovedFromParent();
				}
			}
		}

		private function onNodeAddedToParent():void
		{
			_value.parent = node.parent.getOrCreateAttribute(name)._value;
		}

		private function onNodeRemovedFromParent():void
		{
			_value.parent = null;
		}

		/** Attribute value is inherit from parent. */
		public function get isInherit():Boolean { return _value.isInherit; }

		/** Attribute value is mapped to resource. */
		public function get isResource():Boolean { return StringParseUtil.parseResource(value) != null; }

		//
		// Misc
		//
		public function dispose():void
		{
			_valueCache = null;
			_valueCached = false;
			_change.removeListeners();
		}

		/** @private Value change trigger. */
		public function get change():Trigger
		{
			return _change;
		}

		internal function dispatchChange():void
		{
			_valueCache = null;
			_valueCached = false;
			change.dispatch();
		}
	}
}

import talon.Attribute;
import talon.utils.Trigger;

interface IValue
{
	function get change():Trigger;
	function get string():String;
	function set string(value:String):void;
}

/** Simple string value. */
class SimpleValue implements IValue
{
	private var _string:String;
	private var _change:Trigger = new Trigger(this);

	public function get change():Trigger { return _change; }

	public function get string():String { return _string; }
	public function set string(value:String):void
	{
		if (_string != value)
		{
			_string = value;
			_change.dispatch();
		}
	}
}

/** Value calculated via others based on priority. */
class ComplexValue implements IValue
{
	private var _change:Trigger;
	private var _values:Vector.<IValue>;
	private var _cursor:IValue;
	private var _ignore:IValue;

	public function ComplexValue(...values):void
	{
		_change = new Trigger(this);
		_values = Vector.<IValue>(values);
		_cursor = _values[0];

		for each (var value:IValue in values)
			value.change.addListener(onValueChange);
	}

	public function onValueChange(value:IValue):void
	{
		var cursor:IValue = getCursor();

		// Changed value is cursor or cursor was changed
		if (_cursor == value || _cursor != cursor)
		{
			_cursor = cursor;
			_change.dispatch();
		}
	}

	public function get change():Trigger { return _change; }

	public function get ignore():IValue { return _ignore; }
	public function set ignore(value:IValue):void { _ignore = value; onValueChange(_ignore); }

	public function get string():String { return _cursor.string; }
	public function set string(value:String):void { throw new Error("Unsupported"); }

	private function getCursor():IValue
	{
		for (var i:int = _values.length - 1; i >= 1; i--)
		{
			var value:IValue = _values[i];
			if (value.string && value != _ignore) return value;
		}

		return _values[0];
	}
}

/** Value witch can be inherit from other. */
class InheritValue implements IValue
{
	private var _isInheritable:Boolean;
	private var _change:Trigger;
	private var _parent:IValue;
	private var _basic:IValue;

	public function InheritValue(basic:IValue)
	{
		_change = new Trigger(this);
		_basic = basic;
		_basic.change.addListener(onBasicChange);
	}

	public function get isInherit():Boolean { return _isInheritable && _parent && _basic.string == Attribute.INHERIT; }

	public function get isInheritable():Boolean { return _isInheritable }
	public function set isInheritable(value:Boolean):void
	{
		if (_isInheritable != value)
		{
			var before:String = string;
			_isInheritable = value;
			if (before != string) _change.dispatch();
		}
	}

	public function get change():Trigger { return _change; }
	public function get string():String { return isInherit ? parent.string : _basic.string; }
	public function set string(value:String):void { throw new Error("Unsupported"); }

	public function get parent():IValue { return _parent; }
	public function set parent(value:IValue):void
	{
		_parent && _parent.change.removeListener(onParentChange);
		_parent = value;
		_parent && _parent.change.addListener(onParentChange);
		if (_isInheritable && _basic.string == Attribute.INHERIT) _change.dispatch();
	}

	private function onBasicChange():void { if (!isInherit || _basic.string == Attribute.INHERIT) _change.dispatch(); }
	private function onParentChange():void { if (isInherit) _change.dispatch(); }
}

/** For example (t - top, r - right, b - bottom, l - left)
 *
 *  Format:
 *  [
 *      [ [t,r,b,l] ],
 *      [ [t,b], [r,l] ],
 *      [ [t], [r,l], [b] ],
 *      [ [t], [r], [b], [l] ],
 *  ]
 *
 */
class BindedValue implements IValue
{
	private static const _builder:Array = [];

	private var _change:Trigger;
	private var _string:String;
	private var _values:Vector.<IValue>;
	private var _format:Array;
	private var _enable:Boolean;
	private var _suppress:Boolean;

	public function BindedValue(values:Vector.<IValue>):void
	{
		_change = new Trigger(this);
		_values = values;
		_enable = true;
		_format = getFormat(_values);

		for each (var value:IValue in _values)
			value.change.addListener(onValueChange);

		onValueChange();
	}

	private function getFormat(v:Vector.<IValue>):Array
	{
		if (v.length == 4)
		{
			return [
				[ [v[0], v[1], v[2], v[3]] ],
				[ [v[0], v[2]], [v[1], v[3]] ],
				[ [v[0]], [v[1], v[3]], [v[2]] ],
				[ [v[0]], [v[1]], [v[2]], [v[3]] ]
			]
		}
		else if (v.length == 2)
		{
			return [
				[ [v[0], v[1]] ],
				[ [v[0]], [v[1]] ]
			]
		}

		return null;
	}

	private function onValueChange():void
	{
		if (_suppress === false)
		{
			// Search matched pattern
			enumeration:
			for each (var format:Array in _format)
			{
				for each (var group:Array in format)
					for (var i:int = 0; i < group.length; i++)
						if (group[i].string != group[0].string)
							continue enumeration;

				break;
			}

			// Build string
			_builder.length = 0;

			for each (group in format)
				_builder[_builder.length] = group[0].string;

			_string = _builder.join(" ");

			change.dispatch();
		}
	}

	public function get change():Trigger { return _change; }
	public function get string():String { return _string; }
	public function set string(value:String):void
	{
		var split:Array = (value || "").split(" ");
		if (split.length > _values.length)
			throw new Error("String has invalid format: " + value);

		_string = value;
		_suppress = true;

		var format:Array = _format[split.length - 1];

		for (var i:int = 0; i < format.length; i++)
			for each (var v:IValue in format[i])
				v.string = split[i];

		_suppress = false;
	}
}