package designer
{
	import designer.commands.CloseCommand;
	import designer.commands.ExportCommand;
	import designer.commands.OpenCommand;
	import designer.dom.Document;

	import flash.desktop.NativeApplication;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.filesystem.File;
	import flash.net.FileFilter;
	import flash.utils.ByteArray;

	import starling.core.Starling;

	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.display.ITalonTarget;
	import starling.extensions.talon.display.TalonSprite;
	import starling.extensions.talon.display.TalonFactory;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.textures.Texture;

	public class DesignerInterface extends Sprite
	{
		[Embed(source="/../assets/interface.zip", mimeType="application/octet-stream")]
		private static const INTERFACE:Class;

		[Embed(source="/../assets/FrizQuadrata.fnt", mimeType="application/octet-stream")]
		private static const FNT:Class;
		[Embed(source="/../assets/FrizQuadrata.png")]
		private static const FNT_PNG:Class;

		private var _document:Document;
		private var _factory:TalonFactory;
		private var _interface:TalonSprite;
		private var _layer:Sprite;
		private var _container:TalonSprite;

		private var _export:NativeMenuItem;
		private var _close:NativeMenuItem;
		private var _stats:NativeMenuItem;
		private var _console:NativeMenuItem;

		private var _view:DisplayObject;

		public function DesignerInterface()
		{
			var xml:XML = new XML(new FNT());
			var texture:Texture = Texture.fromEmbeddedAsset(FNT_PNG);
			TextField.registerBitmapFont(new BitmapFont(texture, xml), "FrizQuadrata");

			_factory = new TalonFactory();
			_factory.addEventListener(Event.COMPLETE, onFactoryComplete);
			_factory.addArchiveAsync(new INTERFACE() as ByteArray);

			_layer = new Sprite();
			initializeNativeMenu();
		}

		private function initializeNativeMenu():void
		{
			var menu:NativeMenu = new NativeMenu();

			NativeApplication.nativeApplication.activeWindow.menu = menu;

			// File
			var file:NativeMenu = new NativeMenu();
			menu.addSubmenu(file, DesignerConstants.T_MENU_FILE);

			var open:NativeMenuItem = new NativeMenuItem(DesignerConstants.T_MENU_FILE_OPEN);
			open.keyEquivalent = "o";
			open.addEventListener(Event.SELECT, onOpenSelect);
			file.addItem(open);

			var export:NativeMenuItem = new NativeMenuItem(DesignerConstants.T_MENU_FILE_EXPORT);
			export.keyEquivalent = "s";
			export.addEventListener(Event.SELECT, onExportSelect);
			export.enabled = false;
			file.addItem(export);
			_export = export;

			var close:NativeMenuItem = new NativeMenuItem(DesignerConstants.T_MENU_FILE_CLOSE);
			close.keyEquivalent = "w";
			close.addEventListener(Event.SELECT, onCloseSelect);
			close.enabled = false;
			file.addItem(close);
			_close = close;

			// View
			var view:NativeMenu = new NativeMenu();
			menu.addSubmenu(view, DesignerConstants.T_MENU_VIEW);

			var stats:NativeMenuItem = new NativeMenuItem(DesignerConstants.T_MENU_VIEW_STATS);
			stats.addEventListener(Event.SELECT, onStatsSelect);
			view.addItem(stats);
			_stats = stats;

			var console:NativeMenuItem = new NativeMenuItem(DesignerConstants.T_MENU_VIEW_CONSOLE);
			console.addEventListener(Event.SELECT, onConsoleSelect);
			console.keyEquivalent = '~';
			console.keyEquivalentModifiers = [];
			view.addItem(console);
			_console = console;
			DesignerApplication.current.console.addEventListener(Event.OPEN, onConsoleOpen);
			DesignerApplication.current.console.addEventListener(Event.CLOSE, onConsoleClose);

			// Help
			var help:NativeMenu = new NativeMenu();
			menu.addSubmenu(help, DesignerConstants.T_MENU_HELP);

			var online:NativeMenuItem = new NativeMenuItem(DesignerConstants.T_MENU_HELP_ONLINE);
			online.addEventListener(Event.SELECT, onOnlineHelpSelect);
			help.addItem(online);

			var about:NativeMenuItem = new NativeMenuItem(DesignerConstants.T_MENU_HELP_ABOUT);
			about.addEventListener(Event.SELECT, onAboutSelect);
			help.addItem(about);
		}

		//
		// Command handlers
		//
		private function onOpenSelect(e:*):void
		{
			var filter:FileFilter = new FileFilter(DesignerConstants.T_DESIGNER_FILE_EXTENSION_NAME, "*." + DesignerConstants.DESIGNER_FILE_EXTENSION);
			var file:File = new File();
			file.addEventListener(Event.SELECT, onOpenFileSelect);
			file.browseForOpen(DesignerConstants.T_MENU_FILE_OPEN, [filter]);
		}

		private function onOpenFileSelect(e:*):void
		{
			var file:File = File(e.target);
			var open:OpenCommand = new OpenCommand(file);
			dispatchEventWith(DesignerInterfaceEvent.COMMAND, false, open);
		}

		private function onExportSelect(e:*):void
		{
			var file:File = new File("/" + _document.exportFileName);
			file.addEventListener(Event.SELECT, onOpenExportSelect);
			file.browseForSave(DesignerConstants.T_MENU_FILE_EXPORT);
		}

		private function onOpenExportSelect(e:*):void
		{
			var file:File = File(e.target);
			var export:ExportCommand = new ExportCommand(_document, file);
			dispatchEventWith(DesignerInterfaceEvent.COMMAND, false, export);
		}

		private function onCloseSelect(e:*):void
		{
			var close:CloseCommand = new CloseCommand();
			dispatchEventWith(DesignerInterfaceEvent.COMMAND, false, close);
		}

		private function onStatsSelect(e:*):void
		{
			_stats.checked = Starling.current.showStats = !Starling.current.showStats;
		}

		private function onConsoleSelect(e:*):void
		{
			_console.checked
				? DesignerApplication.current.console.hide()
				: DesignerApplication.current.console.show();
		}

		private function onConsoleOpen(e:*):void { _console.checked = DesignerApplication.current.console.visible; }
		private function onConsoleClose(e:*):void { _console.checked = DesignerApplication.current.console.visible; }


		private function onOnlineHelpSelect(e:*):void { }
		private function onAboutSelect(e:*):void { }

		//
		// Logic
		//
		private function onFactoryComplete(e:Event):void
		{
			_interface = _factory.build("interface") as TalonSprite;
			_container = _interface.getChildByName("container") as TalonSprite;
			_container.addChild(_layer);
			stage && resizeTo(stage.stageWidth, stage.stageHeight);

			addChild(_interface);
		}

		public function setDocument(document:Document):void
		{
			_document = document;
			_export.enabled = _document != null;
			_close.enabled = _document != null;
		}

		public function setPrototype(view:DisplayObject):void
		{
			_view = view;
			_layer.removeChildren();

			if (_view)
			{
				_layer.addChild(_view);
				stage && resizeTo(stage.stageWidth, stage.stageHeight);
			}
		}

		public function resizeTo(width:int, height:int):void
		{
			if (_interface)
			{
				_interface.node.bounds.setTo(0, 0, width, height);
				_interface.node.commit();
			}

			if (_view is ITalonTarget)
			{
				var node:Node = ITalonTarget(_view).node;
				node.bounds.setTo(0, 0, _container.node.bounds.width, _container.node.bounds.height);
				node.commit();
			}
		}
	}
}