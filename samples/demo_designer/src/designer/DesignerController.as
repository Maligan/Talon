package designer
{
	import designer.commands.SaveCommand;

	import designer.dom.Document;
	import designer.dom.DocumentFile;

	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragManager;
	import flash.events.KeyboardEvent;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import flash.ui.Keyboard;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.events.Event;

	public class DesignerController
	{
		private var _launcher:DesignerApplication;
		private var _host:DisplayObjectContainer;
		private var _document:Document;
		private var _prototype:String;
		private var _interface:DesignerInterface;

		public function DesignerController(application:DesignerApplication, host:DisplayObjectContainer)
		{
			_launcher = application;
			_launcher.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onNativeDragEnter);
			_launcher.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onNativeDragDrop);
			_launcher.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

			_interface = new DesignerInterface();

			_host = host;
			_host.addChild(_interface);

			resizeTo(_host.stage.stageWidth, _host.stage.stageHeight);

			_prototype = "button";
		}

		private function onKeyDown(e:KeyboardEvent):void
		{
			if (e.ctrlKey && e.keyCode == Keyboard.S)
			{
				var file:File = new File();
				file.browseForSave("Export");
				file.addEventListener(Event.SELECT, onFileSelect);
			}

			function onFileSelect(e:*):void
			{
				var archive:File = File(e.target);
				new SaveCommand(_document, archive).execute();
			}
		}

		private function onNativeDragEnter(e:NativeDragEvent):void
		{
			if (e.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
			{
				var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
				if (files.length != 0)
				{
					if (_document != null)
					{
						NativeDragManager.dropAction = NativeDragActions.LINK;
						NativeDragManager.acceptDragDrop(_launcher);
					}
					else if (files.length == 1 && files[0].indexOf("." + DesignerConstants.DESIGNER_FILE_EXTENSION) != -1)
					{
						NativeDragManager.dropAction = NativeDragActions.LINK;
						NativeDragManager.acceptDragDrop(_launcher);
					}
				}
			}
		}

		private function onNativeDragDrop(e:NativeDragEvent):void
		{
			var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			if (files.length != 0)
			{
				if (_document != null)
				{
					for each (var file:File in files)
					{
						var documentFile:DocumentFile = new DocumentFile(file);
						_document.addFile(documentFile);
					}
				}
			}
		}

		private function onDocumentChange(e:Event):void
		{
			if (_document.factory.hasPrototype(_prototype))
			{
				var view:DisplayObject = _document.factory.build(_prototype, true, true);
				_interface.setPrototype(view);
			}
		}

		public function resizeTo(width:int, height:int):void
		{
			_interface.resizeTo(width, height);
		}

		public function invoke(filePath:String):void
		{
			var file:File = new File(filePath);
			var documentFile:DocumentFile = new DocumentFile(file);
			_document.addFile(documentFile);
		}
	}
}