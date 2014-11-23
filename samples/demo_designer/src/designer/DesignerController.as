package designer
{
	import designer.dom.Document;
	import designer.dom.DocumentFile;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragManager;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
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

			_document = new Document();
			_document.addEventListener(Event.CHANGE, onDocumentChange);

			_interface = new DesignerInterface();

			_host = host;
			_host.addChild(_interface);

			resizeTo(_host.stage.stageWidth, _host.stage.stageHeight);

			_prototype = "button";
		}

		private function onNativeDragEnter(e:NativeDragEvent):void
		{
			if (e.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
			{
				var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
				if (files.length != 0)
				{
					NativeDragManager.dropAction = NativeDragActions.LINK;
					NativeDragManager.acceptDragDrop(_launcher);
				}
			}
		}

		private function onNativeDragDrop(e:NativeDragEvent):void
		{
			var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			if (files.length != 0)
			{
				for each (var file:File in files)
				{
					var documentFile:DocumentFile = new DocumentFile(file);
					_document.addFile(documentFile);
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