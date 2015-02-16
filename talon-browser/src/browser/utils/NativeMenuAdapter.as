package browser.utils
{
	import browser.commands.Command;

	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	import flash.utils.Dictionary;

	public class NativeMenuAdapter
	{
		private var _menu:NativeMenu;
		private var _locale:Dictionary;
		private var _itemsByCommand:Dictionary;
		private var _itemsPriority:Dictionary;

		public function NativeMenuAdapter(menu:NativeMenu = null)
		{
			_menu = menu || new NativeMenu();
			_locale = new Dictionary();
			_itemsByCommand = new Dictionary();
			_itemsPriority = new Dictionary();
		}

		public function removeItem(path:String):void
		{
			var item:NativeMenuItem = getOrCreateMenuItem(path);
			removeNativeMenuItem(item);
		}

		public function removeItemChildren(path:String):void
		{
			var item:NativeMenuItem = getOrCreateMenuItem(path);
			if (item.submenu)
			{
				while (item.submenu.numItems > 0)
				{
					var subitem:NativeMenuItem = item.submenu.getItemAt(0);
					removeNativeMenuItem(subitem);
				}
			}
		}

		private function removeNativeMenuItem(item:NativeMenuItem):void
		{
			if (item.submenu != null)
			{
				for (var i:int = 0; i < item.submenu.numItems; i++)
				{
					var subitem:NativeMenuItem = item.submenu.getItemAt(i);
					removeNativeMenuItem(subitem);
				}
			}

			if (item.menu != null)
			{
				item.menu.removeItem(item);
				item.removeEventListener(Event.SELECT, onItemSelect);

				var command:Command = Command(item.data);
				if (command) command.removeEventListener(Event.CHANGE, onCommandChange);
				delete _itemsByCommand[item];
			}
		}

		public function addItem(path:String, label:String = null, command:Command = null, keyEquivalent:String = null, priority:int = 0):void
		{
			_itemsPriority[path] = priority;
			var item:NativeMenuItem = getOrCreateMenuItem(path);
			item.data = command;
			if (label) item.label = label;
			if (keyEquivalent) item.keyEquivalent = keyEquivalent;
			item.addEventListener(Event.SELECT, onItemSelect);

			if (command)
			{
				item.enabled = command.isExecutable;
				item.checked = command.isActive;
				command.addEventListener(Event.CHANGE, onCommandChange);
				_itemsByCommand[command] = item;
			}
		}

		private function onCommandChange(e:*):void
		{
			var command:Command = Command(e.target);
			var item:NativeMenuItem = _itemsByCommand[command];
			item.enabled = command.isExecutable;
			item.checked = command.isActive;
		}

		private function onItemSelect(e:*):void
		{
			var item:NativeMenuItem = NativeMenuItem(e.target);
			var command:Command =  Command(item.data);
			command && command.execute();
		}

		private function getOrCreateMenuItem(path:String):NativeMenuItem
		{
			var split:Array = path.split("/");

			var name:String = null;
			var item:NativeMenuItem = null;
			var menu:NativeMenu = _menu;

			for (var i:int = 0; i < split.length; i++)
			{
				name = split[i];

				if (menu == null)
				{
					menu = new NativeMenu();
					item.submenu = menu;
				}

				item = menu.getItemByName(name);

				if (item == null)
				{
					item = new NativeMenuItem(name, name.charAt(0) == "-");
					item.name = name;
					var index:int = searchIndexOf(path, menu);
					menu.addItemAt(item, index);
				}

				menu = item.submenu;
			}

			return item;
		}

		private function searchIndexOf(path:String, parent:NativeMenu):int
		{
			var priority:int = _itemsPriority[path];
			var split:Array = path.split("/");

			var i:int = parent.numItems;
			while (i > 0)
			{
				var item:NativeMenuItem = parent.getItemAt(i-1);

				split.pop();
				split.push(item.name);
				var name:String = split.join("/");
				var p:int = _itemsPriority[name];

				if (priority <= p) break;
				i--;
			}

			return i;
		}

		public function get menu():NativeMenu
		{
			return _menu;
		}
	}
}
