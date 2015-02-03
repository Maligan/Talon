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

		private var _assigned:String;
		private var _styleable:Boolean;
		private var _styled:String;
		private var _inheritable:Boolean;
		private var _initial:String;

		private var _value:*;
		private var _valueCached:Boolean;

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
				_node.addEventListener(Event.ADDED, onAddedToParent);
				_node.addEventListener(Event.REMOVED, onRemovedFromParent);
			}

			_assignedValueGetter = getter;
			_assignedValueSetter = setter;
			_assignedDispatcher = dispatcher;
			_assignedDispatcher && _assignedDispatcher.addEventListener(Event.CHANGE, onAssignedChange);
		}

		private function onAssignedChange(e:Event):void
		{
			_assigned = _assignedValueGetter();
			dispatchChange();
		}

		//
		// Inherit observation
		//

		//
		// Properties
		//



		private function dispatchChange():void
		{
			_value = null;
			_valueCached = false;
			_node.dispatchEventWith(Event.CHANGE, false, name);
		}

		public function getValueExpanded():*
		{
			var value:String = getValue(true);

			// If attribute is simple return string value
			var invokeInfo:Array = StringUtil.parseFunction(value);
			if (invokeInfo == null) return value;

			// Obtain invoker via invokeInfo
			var invokeMethodName:String = invokeInfo.shift();
			var invokeMethod:Function = _node.getInvoker(invokeMethodName);
			if (invokeMethod == null) return value;

			return invokeMethod.apply(null, invokeInfo);
		}

		/** Get string value representation. @param deep - expand 'inherit' keyword. */
		public function getValue(deep:Boolean):String
		{
			if (deep && inheritable && getValue(false)==INHERIT)
			{
				return inherit;
			}
			else
			{
				return assigned || (styleable?styled:null) || initial;
			}
		}

		//
		// Inherit
		//
		public function get inherit():String { return node.parent ? node.getOrCreateAttribute(name).getValue(true) : null; }

		public function get inheritable():Boolean { return _inheritable; }
		public function set inheritable(value:Boolean):void
		{
			if (_inheritable != value)
			{
				_inheritable = value;
				// TODO: Check change
			}
		}

		private function onAddedToParent(e:Event):void
		{
			_node.parent.addEventListener(Event.CHANGE, onParentNodeAttributeChange);
			setInheritValue();
		}

		private function onRemovedFromParent(e:Event):void
		{
			_node.parent.removeEventListener(Event.CHANGE, onParentNodeAttributeChange);
			setInheritValue();
		}

		private function onParentNodeAttributeChange(e:Event):void
		{
			if (e.data == name)
			{
				setInheritValue();
			}
		}

		private function setInheritValue():void
		{
			if (getValue(false) == INHERIT) dispatchChange();
		}

		//
		// Initial
		//
		public function get initial():String { return _initial }
		public function set initial(value:String):void
		{
			if (_initial != value)
			{
				_initial = value;
				// TODO: Check change
			}
		}

		//
		// Assign
		//
		public function get assigned():String { return _assigned; }
		public function set assigned(value:String):void
		{
			if (_assignedValueSetter != null)
			{
				_assignedValueSetter(value);
			}
			else if (_assigned != value)
			{
				// FIXME: Set assigned value while value == this.value
				_assigned = value;
				dispatchChange();
			}
		}

		//
		// Style
		//
		public function get styleable():Boolean { return _styleable; }
		public function set styleable(value:Boolean):void
		{
			if (_styleable != value)
			{
				_styleable = value;
				// TODO: Check change
			}
		}

		public function get styled():String { return _styled }
		public function set styled(value:String):void
		{
			if (_styled != value)
			{
				_styled = value;

				if (_styleable && _assigned == null)
				{
					if (_assignedValueSetter != null)
					{
						// Для того что бы в onAssignedChange не установилось значение _assigned
						_assignedDispatcher.removeEventListener(Event.CHANGE, onAssignedChange);
						_assignedValueSetter(getValue(true));
						_assignedDispatcher.addEventListener(Event.CHANGE, onAssignedChange);
					}

					dispatchChange();
				}
			}
		}

		//
		// Misc
		//
		public function get node():Node
		{
			return _node;
		}

		public function get name():String
		{
			return _name;
		}

		/** Cached analog of getValueExpanded. */
		public function get value():*
		{
			if (_valueCached == false)
			{
				_valueCached = true;
				_value = getValueExpanded();
			}

			return _value;
		}

		/** Attribute value mapped to resource. */
		public function get isResource():Boolean
		{
			var split:Array = StringUtil.parseFunction(getValue(true));
			return split && split[0] == "res";
		}
	}
}
