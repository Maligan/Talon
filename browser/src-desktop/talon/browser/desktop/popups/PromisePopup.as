package talon.browser.desktop.popups
{
	import flash.ui.Keyboard;

	import starling.display.DisplayObject;
	import starling.events.Event;

	import talon.browser.platform.popups.Popup;
	import talon.core.Attribute;

	public class PromisePopup extends Popup
	{
		private var _details:Boolean;
		
		protected override function initialize():void
		{
			addChild(manager.factory.build("PromisePopup") as DisplayObject);
			node.validate();

			query().set("header", "Hello World");
			query("#detailsInfo").set(Attribute.VISIBLE, _details);

			query("#cancel").onTap(onCancelClick);
			query("#details").onTap(onDetailsClick);
			
			addKeyboardListener(Keyboard.ESCAPE, onCancelClick);
		}

		private function onCancelClick():void
		{
			dispatchEventWith(Event.CANCEL);
		}
		
		private function onDetailsClick():void
		{
			_details = !_details;
			query("#details").set(Attribute.TRANSFORM, _details ? "rotate(-90deg)" : "none");
			query("#detailsInfo").set(Attribute.VISIBLE, _details);
		}
		
		public function setHeader(string:String):void
		{
			query("#header").set(Attribute.TEXT, string);
		}
		
		public function setStateProcess(status:String):void
		{
			query("#status")
				.set(Attribute.TEXT, status);

			query("#spinner")
				.set(Attribute.VISIBLE, true)
				.forEach(juggler.tween, 1, {
						repeatCount: 0,
						onUpdate: function():void { query("#spinner").set(Attribute.TRANSFORM, "rotate({0})", juggler.elapsedTime*180); }
					}
				);
				
			query("#details")
				.set(Attribute.VISIBLE, false);
		}
		
		public function setStateComplete(status:String = null, details:String = null):void
		{
			if (status) query("#status")
				.set(Attribute.TEXT, status);
			
			query("#spinner")
				.set(Attribute.VISIBLE, false)
				.forEach(juggler.removeTweens);

			query("#details")
				.set(Attribute.VISIBLE, details != null);

			query("#detailsInfo")
				.set(Attribute.TEXT, details);
		}
	}
}
