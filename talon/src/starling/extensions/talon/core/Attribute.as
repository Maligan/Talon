package starling.extensions.talon.core
{
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.extensions.talon.utils.StringUtil;

	//[ExcludeClass]
	public class Attribute
	{
		//
		// Standart Attribute list
		//
		public static const ID:String = "id";
		public static const TYPE:String = "type";
		public static const CLASS:String = "class";
		public static const STATE:String = "state";

		public static const WIDTH:String = "width";
		public static const MIN_WIDTH:String = "minWidth";
		public static const MAX_WIDTH:String = "maxWidth";

		public static const HEIGHT:String = "height";
		public static const MIN_HEIGHT:String = "minHeight";
		public static const MAX_HEIGHT:String = "maxHeight";

		public static const MARGIN:String = "margin";
		public static const MARGIN_TOP:String = "marginTop";
		public static const MARGIN_RIGHT:String = "marginRight";
		public static const MARGIN_BOTTOM:String = "marginBottom";
		public static const MARGIN_LEFT:String = "marginLeft";

		public static const PADDING:String = "padding";
		public static const PADDING_TOP:String = "paddingTop";
		public static const PADDING_RIGHT:String = "paddingRight";
		public static const PADDING_BOTTOM:String = "paddingBottom";
		public static const PADDING_LEFT:String = "paddingLeft";

		public static const ANCHOR:String = "anchor";
		public static const ANCHOR_TOP:String = "anchorTop";
		public static const ANCHOR_RIGHT:String = "anchorRight";
		public static const ANCHOR_BOTTOM:String = "anchorBottom";
		public static const ANCHOR_LEFT:String = "anchorLeft";

		public static const BACKGROUND_IMAGE:String = "backgroundImage";
		public static const BACKGROUND_TINT:String = "backgroundTint";
		public static const BACKGROUND_9SCALE:String = "background9Scale";
		public static const BACKGROUND_COLOR:String = "backgroundColor";
		public static const BACKGROUND_FILL_MODE:String = "backgroundFillMode";

		public static const FONT_COLOR:String = "fontColor";
		public static const FONT_NAME:String = "fontName";
		public static const FONT_SIZE:String = "fontSize";

		public static const ALPHA:String = "alpha";
		public static const CLIPPING:String = "clipping";
		public static const CURSOR:String = "cursor";
		public static const FILTER:String = "filter";

		public static const LAYOUT:String = "layout";
		public static const VISIBILITY:String = "visibility";

		public static const POSITION:String = "position";
		public static const X:String = "x";
		public static const Y:String = "y";

		public static const PIVOT:String = "pivot";
		public static const PIVOT_X:String = "pivotX";
		public static const PIVOT_Y:String = "pivotY";

		public static const ORIGIN:String = "origin";
		public static const ORIGIN_X:String = "originX";
		public static const ORIGIN_Y:String = "originY";

		public static const ORIENTATION:String = "orientation";
		public static const HALIGN:String = "halign";
		public static const VALIGN:String = "valign";
		public static const GAP:String = "gap";
		public static const INTERLINE:String = "interline";
		public static const WRAP:String = "wrap";
		public static const BREAK:String = "break";

		public static const TEXT:String = "text";

		//
		// Attribute Implementation
		//
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

		public function getValue():*
		{
			// If attribute is simple return string value
			var invokeInfo:Array = StringUtil.parseFunction(value);
			if (invokeInfo == null) return value;

			// Obtain invoker via invokeInfo
			var invokeMethodName:String = invokeInfo.shift();
			var invokeMethod:Function = _node.getInvoker(invokeMethodName);
			if (invokeMethod == null) return value;

			return invokeMethod.apply(null, invokeInfo);
		}

		/** Attribute value mapped to resource. */
		public function get isResource():Boolean
		{
			var split:Array = StringUtil.parseFunction(value);
			return split && split[0] == "res";
		}

		public function setAssignedValue(value:String):void
		{
			if (_assignedValueSetter != null)
			{
				_assignedValueSetter(value);
			}
			else if (_assign != value)
			{
				// FIXME: Set assigned value while value == this.value
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
}
