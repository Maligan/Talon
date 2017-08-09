package talon.browser.desktop.utils
{
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.ui.Keyboard;

	import starling.events.Event;

	import talon.browser.platform.utils.Command;

	public class NativeMenuAdapter
	{
		//
		// Pooling
		//
		private static var sPoolSeparator:Vector.<NativeMenuAdapter> = new <NativeMenuAdapter>[];
		private static var sPool:Vector.<NativeMenuAdapter> = new <NativeMenuAdapter>[];

		private function fromPool(name:String, isSeparator:Boolean):NativeMenuAdapter
		{
			var pool:Vector.<NativeMenuAdapter> = isSeparator ? sPoolSeparator : sPool;
			var item:NativeMenuAdapter = pool.pop() || new NativeMenuAdapter(name, isSeparator);

			item._nativeItem.name = name;
			item._name = name;
			item.label = name;

			return item;
		}

		private function toPool(item:NativeMenuAdapter):void
		{
			item.command = null;
			item.label = null;
			item._children.length = 0;
			item._parent = null;

			var list:Vector.<NativeMenuAdapter> = item.isSeparator ? sPoolSeparator : sPool;
			list[list.length] = item;
		}

		//
		// Instance
		//

		private var _nativeItem:NativeMenuItem;
		private var _nativeMenu:NativeMenu;

		private var _parent:NativeMenuAdapter;
		private var _name:String;
		private var _isSeparator:Boolean;
		private var _children:Vector.<NativeMenuAdapter>;

		private var _command:Command;
		private var _isEnabled:Boolean;

		public function NativeMenuAdapter(name:String = null, isSeparator:Boolean = false)
		{
			_name = name;
			_isSeparator = isSeparator;
			_nativeItem = new NativeMenuItem(name, isSeparator);
			_nativeItem.data = this;
			_nativeItem.addEventListener(Event.SELECT, onItemSelect);
			_children = new <NativeMenuAdapter>[];
			_isEnabled = true;
		}

		public function insert(path:String, label:String = null, command:Command = null, keyEquivalent:String = null, keyEquivalentModifiers:Array = null):NativeMenuAdapter
		{
			var isSeparator:Boolean = path.charAt(path.lastIndexOf("/") + 1) == "-";
			var node:NativeMenuAdapter = addChildByPath(path, isSeparator);
			if (command) node.command = command;
			if (label) node.label = label;
			if (keyEquivalent) node.keyEquivalent = keyEquivalent;
			if (keyEquivalentModifiers) node.keyEquivalentModifiers = keyEquivalentModifiers || [Keyboard.CONTROL];
			return node;
		}

		//
		// Methods
		//
		private function refreshSubmenu():void
		{
			if (_children.length > 0 && !isSeparator && _nativeItem.submenu != nativeMenu)
				_nativeItem.submenu = nativeMenu;

			// TODO: Cleanup submenu if there is no children
		}

		private function refreshStatus():void
		{
			if (_nativeItem.enabled != enabled)
				_nativeItem.enabled  = enabled;

			if (_nativeItem.checked != checked)
				_nativeItem.checked  = checked;
		}

		private function onItemSelect(e:*):void
		{
			if (_command)
				_command.execute();
		}

		//
		// Children
		//
		public function getChildByPath(path:String):NativeMenuAdapter
		{
			var split:Array = path.split("/");
			if (split.length > 1)
			{
				var childName:String = split.shift();
				var childPath:String = split.join("/");
				var child:NativeMenuAdapter = getChildByName(childName);
				return child ? child.getChildByPath(childPath) : null;
			}

			return getChildByName(path);
		}

		private function getChildByName(name:String):NativeMenuAdapter
		{
			for each (var child:NativeMenuAdapter in _children)
				if (child.name == name)
					return child;

			return null;
		}

		public function removeChildByPath(path:String):void
		{
			var child:NativeMenuAdapter = getChildByPath(path);
			if (child && child.parent)
				child.parent.removeChild(child);
		}

		public function removeChild(child:NativeMenuAdapter):void
		{
			var indexOf:int = _children.indexOf(child);
			if (indexOf != -1)
			{
				_children.splice(indexOf, 1);
				nativeMenu.removeItem(child._nativeItem);
				refreshSubmenu();
				toPool(child);
			}
		}

		public function removeChildren():void
		{
			while (_children.length)
				removeChild(_children[0]);
		}

		public function addChildByPath(path:String, isSeparator:Boolean):NativeMenuAdapter
		{
			var split:Array = path.split("/");
			if (split.length > 1)
			{
				var childName:String = split.shift();
				var childPath:String = split.join("/");
				var child:NativeMenuAdapter = getChildByName(childName) || addChildByPath(childName, false);
				return child.addChildByPath(childPath, isSeparator);
			}

			return addChild(fromPool(path, isSeparator))
		}

		public function addChild(child:NativeMenuAdapter):NativeMenuAdapter
		{
			if (_children.indexOf(child) == -1)
			{
				if (child.parent) child.parent.removeChild(child);
				_children[_children.length] = child;
				child._parent = this;
				nativeMenu.addItem(child._nativeItem);
				refreshSubmenu();
			}

			return child;
		}

		//
		// Properties
		//
		public function get parent():NativeMenuAdapter { return _parent }
		public function get name():String { return _name }
		public function get isSeparator():Boolean { return _nativeItem.isSeparator }

		public function get keyEquivalent():String { return _nativeItem.keyEquivalent }
		public function set keyEquivalent(value:String):void { _nativeItem.keyEquivalent = value }

		public function get keyEquivalentModifiers():Array { return _nativeItem.keyEquivalentModifiers }
		public function set keyEquivalentModifiers(value:Array):void { _nativeItem.keyEquivalentModifiers = value }

		public function get label():String { return _nativeItem.label }
		public function set label(value:String):void { _nativeItem.label = value }

		public function get command():Command { return _command; }
		public function set command(value:Command):void
		{
			_command && _command.removeEventListener(Event.CHANGE, refreshStatus);
			_command = value;
			_command && _command.addEventListener(Event.CHANGE, refreshStatus);
			refreshStatus();
		}

		public function get isEnabled():Boolean { return _isEnabled }
		public function set isEnabled(value:Boolean):void { _isEnabled = value; refreshStatus() }

		public function get isMenu():Boolean { return _nativeItem.submenu != null }
		public function set isMenu(value:Boolean):void { if (value) _nativeItem.submenu = nativeMenu }

		//
		// Lazy parts
		//
		private function get enabled():Boolean { return (_command == null || _command.isExecutable) && isEnabled }
		private function get checked():Boolean { return (_command && _command.isActive); }

		public function get nativeMenu():NativeMenu
		{
			if (_nativeMenu == null)
				_nativeMenu = new NativeMenu();

			return _nativeMenu;
		}
	}
}
