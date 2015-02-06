package starling.extensions.talon.core
{
	import flash.utils.Dictionary;

	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.extensions.talon.utils.QueryUtil;
	import starling.extensions.talon.utils.StringUtil;

	//[ExcludeClass]
	public class Attribute
	{
		//1
		// Standard Attribute list
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

		public static const ORIGIN:String = "value";
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

		private static var _queries:Dictionary;

		private static function initialize():void
		{
			if (_queries == null)
			{
				_queries = new Dictionary();
				registerQueryAlias("res", QueryUtil.queryResource);
				registerQueryAlias("brightness", QueryUtil.queryBrightnessFilter);
				registerQueryAlias("blur", QueryUtil.queryBlurFilter);
				registerQueryAlias("glow", QueryUtil.queryGlowFilter);
				registerQueryAlias("drop-shadow", QueryUtil.queryDropShadow);
			}
		}

		/** Add new attribute query. TODO: Move to other place... */
		public static function registerQueryAlias(aliasName:String, callback:Function):void
		{
			if (_queries == null) initialize();
			_queries[aliasName] = callback;
		}

		private var _node:Node;
		private var _name:String;

		private var _assignedValueGetter:Function;
		private var _assignedValueSetter:Function;
		private var _assignedDispatcher:EventDispatcher;
		private var _assignIgnore:Boolean;

		private var _styleable:Boolean;
		private var _styled:String;
		private var _initial:String;
		private var _assigned:String;
		private var _inheritable:Boolean;
		private var _inherit:String;

		public function Attribute(node:Node, name:String)
		{
			initialize();

			if (node == null) throw new ArgumentError("Parameter node must be non-null");
			if (name == null) throw new ArgumentError("Parameter name must be non-null");

			_node = node;
			_name = name;
			_styleable = true;
			_inheritable = false;
		}

		//
		// Base properties
		//
		/** The node that contains this attribute. */
		public function get node():Node { return _node; }

		/** Unique (in-node) attribute name. */
		public function get name():String { return _name; }

		/**
		 * Attribute value (based on assigned, styled and initial values)
		 * NB! There are two optimized version of this property: origin & expanded, but remember this value is basis for them.
		 */
		public function get value():String { return assigned || (styleable?styled:null) || initial; }

		//
		// Optimization
		//
		/** NB! Optimize <code>value</code> property. Expand 'inherit' value if attribute is inheritable. */
		public function get origin():String { return isInherit ? inherit : value; }

		/** NB! Optimize <code>value</code>property. Expand 'inherit' value and call invokers (like 'url(...)', 'res(...)', 'blur(...)' etc.) for convert value to strongly typed object. */
		public function get expanded():*
		{
			// If attribute has no query - return origin value
			var queryInfo:Array = StringUtil.parseFunction(origin);
			if (queryInfo == null) return origin;

			// Obtain query method via queryInfo
			var queryMethodName:String = queryInfo.shift();
			var queryMethod:Function = _queries[queryMethodName];
			if (queryMethod == null) return origin;

			queryInfo.unshift(this);
			return queryMethod.apply(null, queryInfo);
		}

		//
		// Inherit
		//
		public function get inherit():String { return _inherit; }

		public function get inheritable():Boolean { return _inheritable; }
		public function set inheritable(value:Boolean):void
		{
			if (_inheritable != value)
			{
				_inheritable = value;

				if (_inheritable)
				{
					_node.addEventListener(Event.ADDED, onAddedToParent);
					_node.addEventListener(Event.REMOVED, onRemovedFromParent);
					_node.parent && node.parent.addEventListener(Event.CHANGE, onParentNodeAttributeChange);
				}
				else
				{
					_node.removeEventListener(Event.ADDED, onAddedToParent);
					_node.removeEventListener(Event.REMOVED, onRemovedFromParent);
				}

				if (_inheritable)
					validateInherit();
				else if (origin == INHERIT)
					dispatchChange();
			}
		}

		private function onAddedToParent(e:Event):void
		{
			node.parent.addEventListener(Event.CHANGE, onParentNodeAttributeChange);
			validateInherit();
		}

		private function onRemovedFromParent(e:Event):void
		{
			node.parent.removeEventListener(Event.CHANGE, onParentNodeAttributeChange);
			validateInherit();
		}

		private function onParentNodeAttributeChange(e:Event):void
		{
			if (e.data == name) validateInherit();
		}

		private function validateInherit():void
		{
			_inherit = node.parent ? node.parent.getOrCreateAttribute(name).origin : null;
			if (isInherit) dispatchChange();
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

				if (_assigned == null && (!_styleable || _styled == null))
				{
					if (_assignedValueSetter != null)
					{
						// Для того что бы в onAssignedChange не установилось значение _assigned
						_assignIgnore = true;
						_assignedValueSetter(this.origin);
						_assignIgnore = false;
					}

					dispatchChange();
				}
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
				// FIXME: Set assigned origin while origin == this.origin
				_assigned = value;
				dispatchChange();
			}
		}

		/** @private Bind assigned value to same object. */
		public function bind(dispatcher:EventDispatcher, getter:Function, setter:Function):void
		{
			if (dispatcher == null) return;
			if (getter == null) throw new ArgumentError("Invalid binding getter");
			if (setter == null) throw new ArgumentError("Invalid binding setter");

			if (dispatcher && getter && setter)
			{
				_assignedValueGetter = getter;
				_assignedValueSetter = setter;
				_assignedDispatcher = dispatcher;
				_assignedDispatcher.addEventListener(Event.CHANGE, onAssignedChange);
			}
		}

		private function onAssignedChange(e:Event):void
		{
			if (_assignIgnore == false)
			{
				_assigned = _assignedValueGetter();
				dispatchChange();
			}
		}

		//
		// Style
		//
		/** Need use styled property when calculating attribute value. */
		public function get styleable():Boolean { return _styleable; }
		public function set styleable(value:Boolean):void
		{
			if (_styleable != value)
			{
				_styleable = value;

				if (_assigned == null && _styled != null)
				{
					dispatchChange();
				}
			}
		}

		/** Attribute value from node style sheet. */
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
						_assignIgnore = true;
						_assignedValueSetter(this.origin);
						_assignIgnore = false;
					}

					dispatchChange();
				}
			}
		}

		//
		// Misc
		//

		/** Attribute value is mapped to resource. */
		public function get isResource():Boolean
		{
			var split:Array = StringUtil.parseFunction(origin);
			return split && split[0] == "res";
		}

		/** Attribute value user inherit from parent. */
		public function get isInherit():Boolean
		{
			return inheritable && value==INHERIT;
		}

		private function dispatchChange():void
		{
			_node.dispatchEventWith(Event.CHANGE, false, name);
		}
	}
}
