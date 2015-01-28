package starling.extensions.talon.core
{
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.utils.StringUtil;

	//[ExcludeClass]
	public class Attribute
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
