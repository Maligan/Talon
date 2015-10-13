package talon.browser.plugins.tools
{
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragManager;
	import flash.display.InteractiveObject;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import talon.browser.AppConstants;
	import talon.browser.AppController;
	import talon.browser.plugins.IPlugin;
	import talon.browser.utils.DisplayTreeUtil;
	import talon.starling.TalonSprite;

	public class DragAndDropPlugin implements IPlugin
	{
		public static const EVENT_DRAG_IN:String = "documentDragIn";
		public static const EVENT_DRAG_OUT:String = "documentDragOut";
		public static const EVENT_DRAG_DROP:String = "documentDrop";

		private var _app:AppController;

		public function get id():String { return "talon.browser.tools.DragAndDrop"; }
		public function get version():String { return "0.0.1"; }
		public function get versionAPI():String { return "0.1.0"; }

		public function attach(app:AppController):void
		{
			_app = app;

			_app.root.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragIn);
			_app.root.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, onDragOut);
			_app.root.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop);

			_app.addEventListener(EVENT_DRAG_IN, activate);
			_app.addEventListener(EVENT_DRAG_OUT, deactivate);
			_app.addEventListener(EVENT_DRAG_DROP, deactivate);
		}

		private function activate():void
		{
			var overlay:TalonSprite = DisplayTreeUtil.findChildByName(_app.ui.host, "drag") as TalonSprite;
			if (overlay) overlay.node.classes.add("active");
		}

		private function deactivate():void
		{
			var overlay:TalonSprite = DisplayTreeUtil.findChildByName(_app.ui.host, "drag") as TalonSprite;
			if (overlay) overlay.node.classes.remove("active");
		}

		public function detach():void
		{
			_app.root.removeEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragIn);
			_app.root.removeEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, onDragOut);
			_app.root.removeEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop);
		}

		private function onDragIn(e:NativeDragEvent):void
		{
			var hasFiles:Boolean = e.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT);
			if (hasFiles)
			{
				var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
				if (files.length == 1)
				{
					var file:File = File(files[0]);
					if (file.extension == AppConstants.BROWSER_DOCUMENT_EXTENSION)
					{
						NativeDragManager.acceptDragDrop(_app.root as InteractiveObject);
						NativeDragManager.dropAction = NativeDragActions.MOVE;
						_app.dispatchEventWith(EVENT_DRAG_IN, files[0]);
					}
				}
			}
		}

		private function onDragOut(e:NativeDragEvent):void
		{
			_app.dispatchEventWith(EVENT_DRAG_OUT);
		}

		private function onDragDrop(e:NativeDragEvent):void
		{
			_app.dispatchEventWith(EVENT_DRAG_DROP);
			var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			var file:File = File(files[0]);
			_app.invoke(file.nativePath);
		}
	}
}