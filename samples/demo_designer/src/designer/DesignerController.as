package designer
{
	import designer.commands.DesignerCommand;
	import designer.commands.DesignerCommand;
	import designer.commands.OpenCommand;
	import designer.commands.ExportCommand;

	import designer.dom.Document;
	import flash.events.KeyboardEvent;
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

			_launcher.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

			_interface = new DesignerInterface();
			_interface.addEventListener(DesignerInterfaceEvent.COMMAND, onCommand);

			_host = host;
			_host.addChild(_interface);

			resizeTo(_host.stage.stageWidth, _host.stage.stageHeight);

			_prototype = "button";
		}

		private function onCommand(e:Event):void
		{
			var command:DesignerCommand = DesignerCommand(e.data);
			command.execute();

			if (command is OpenCommand) setCurrentDocument(OpenCommand(command).document);
		}

		private function onKeyDown(e:KeyboardEvent):void
		{
			if (e.ctrlKey && e.keyCode == Keyboard.S)
			{
				var file:File = new File("/interface.zip");
				file.browseForSave("Export");
				file.addEventListener(Event.SELECT, onFileSelect);
			}

			function onFileSelect(e:*):void
			{
				var archive:File = File(e.target);
				new ExportCommand(_document, archive).execute();
			}
		}

		private function onDocumentChange(e:Event):void
		{
			refresh();
		}

		private function refresh():void
		{
			if (_document && _prototype && _document.factory.hasPrototype(_prototype))
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
			var open:OpenCommand = new OpenCommand(file);
			open.execute();

			setCurrentDocument(open.document);
		}

		public function setCurrentDocument(document:Document):void
		{
			_document && _document.removeEventListener(Event.CHANGE, onDocumentChange);
			_document = document;
			_document && _document.addEventListener(Event.CHANGE, onDocumentChange);

			_interface.setDocument(_document);

			refresh();
		}
	}
}

//		_launcher.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onNativeDragEnter);
//		_launcher.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onNativeDragDrop);

//		private function onNativeDragEnter(e:NativeDragEvent):void
//		{
//			if (e.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
//			{
//				var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
//				if (files.length != 0)
//				{
//					if (_document != null)
//					{
//						NativeDragManager.dropAction = NativeDragActions.LINK;
//						NativeDragManager.acceptDragDrop(_launcher);
//					}
//					else if (files.length == 1 && files[0].indexOf("." + DesignerConstants.DESIGNER_FILE_EXTENSION) != -1)
//					{
//						NativeDragManager.dropAction = NativeDragActions.LINK;
//						NativeDragManager.acceptDragDrop(_launcher);
//					}
//				}
//			}
//		}
//
//		private function onNativeDragDrop(e:NativeDragEvent):void
//		{
//			var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
//			if (files.length != 0)
//			{
//				if (_document != null)
//				{
//					for each (var file:File in files)
//					{
//						var documentFile:DocumentFile = new DocumentFile(file);
//						_document.addFile(documentFile);
//					}
//				}
//			}
//		}