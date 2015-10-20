package talon.browser.plugins.tools
{
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragManager;
	import flash.display.InteractiveObject;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import talon.browser.AppConstants;
	import talon.browser.AppPlatform;
	import talon.browser.plugins.IPlugin;
	import talon.browser.utils.DisplayTreeUtil;
	import talon.starling.TalonSprite;

	public class CorePluginDragAndDrop implements IPlugin
	{
		public static const EVENT_DRAG_IN:String = "documentDragIn";
		public static const EVENT_DRAG_OUT:String = "documentDragOut";
		public static const EVENT_DRAG_DROP:String = "documentDrop";

		private var _platform:AppPlatform;

		public function get id():String { return "talon.browser.plugin.core.DragAndDrop"; }
		public function get version():String { return "0.0.1"; }
		public function get versionAPI():String { return "0.1.0"; }

		public function attach(platform:AppPlatform):void
		{
			_platform = platform;

			_platform.stage.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragIn);
			_platform.stage.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, onDragOut);
			_platform.stage.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop);

			_platform.addEventListener(EVENT_DRAG_IN, activate);
			_platform.addEventListener(EVENT_DRAG_OUT, deactivate);
			_platform.addEventListener(EVENT_DRAG_DROP, deactivate);
		}

		private function activate():void
		{
			var overlay:TalonSprite = DisplayTreeUtil.findChildByName(_platform.ui.host, "drag") as TalonSprite;
			if (overlay) overlay.node.classes.add("active");
		}

		private function deactivate():void
		{
			var overlay:TalonSprite = DisplayTreeUtil.findChildByName(_platform.ui.host, "drag") as TalonSprite;
			if (overlay) overlay.node.classes.remove("active");
		}

		public function detach():void
		{
			_platform.stage.removeEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragIn);
			_platform.stage.removeEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, onDragOut);
			_platform.stage.removeEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop);
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
						NativeDragManager.acceptDragDrop(_platform.stage as InteractiveObject);
						NativeDragManager.dropAction = NativeDragActions.MOVE;
						_platform.dispatchEventWith(EVENT_DRAG_IN, files[0]);
					}
				}
			}
		}

		private function onDragOut(e:NativeDragEvent):void
		{
			_platform.dispatchEventWith(EVENT_DRAG_OUT);
		}

		private function onDragDrop(e:NativeDragEvent):void
		{
			_platform.dispatchEventWith(EVENT_DRAG_DROP);
			var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			var file:File = File(files[0]);
			_platform.invoke(file.nativePath);
		}
	}
}