package
{
	import browser.utils.Constants;
	import browser.AppController;
	import browser.utils.Console;

	import flash.desktop.NativeApplication;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.InvokeEvent;
	import flash.geom.Rectangle;

	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;

	[SWF(backgroundColor="#C7C7C7")]
	public class Launcher extends MovieClip
	{
		private var _dropTarget:flash.display.Sprite;
		private var _controller:AppController;
		private var _console:Console;
		private var _invoke:String;

		public function Launcher()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onResize);

			// NativeDragManager do not work with empty document root
			// add this object to fix this problem
			_dropTarget = new flash.display.Sprite();
			addChild(_dropTarget);

			// Add console
			addChild(_console = new Console());

			NativeApplication.nativeApplication.setAsDefaultApplication(Constants.DESIGNER_FILE_EXTENSION);
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);



			new Starling(starling.display.Sprite, stage);
			Starling.current.addEventListener(Event.ROOT_CREATED, onRootCreated);
			Starling.current.start();

			onResize(null);
		}

		private function onResize(e:*):void
		{
			Starling.current.stage.stageWidth = stage.stageWidth;
			Starling.current.stage.stageHeight = stage.stageHeight;
			Starling.current.viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);

			_dropTarget.graphics.beginFill(0xFFFFFF, 0);
			_dropTarget.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			_dropTarget.graphics.endFill();

			_controller && _controller.resizeTo(stage.stageWidth, stage.stageHeight);
		}

		private function onRootCreated(e:*):void
		{
			_controller = new AppController(this, Starling.current.root as starling.display.Sprite, _console);
			_invoke && _controller.invoke(_invoke);
		}

		private function onInvoke(e:InvokeEvent):void
		{
			if (e.arguments.length > 0)
			{
				_invoke = e.arguments[0];
				_controller && _controller.invoke(_invoke);
			}
		}
	}
}