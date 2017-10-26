package talon.browser.desktop.popups
{
	import flash.ui.Keyboard;

	import starling.display.DisplayObject;
	import starling.events.Event;

	import talon.browser.core.popups.Popup;
	import talon.core.Attribute;

	public class PromisePopup extends Popup
	{
		private var _details:Boolean;
		
		protected override function initialize():void
		{
			addChild(manager.factory.build("PromisePopup") as DisplayObject);

			query().attr("header", "Hello World");
			query("#detailsInfo").attr(Attribute.VISIBLE, _details);

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
			query("#details").attr(Attribute.TRANSFORM, _details ? "rotate(-90deg)" : "none");
			query("#detailsInfo").attr(Attribute.VISIBLE, _details);
		}
		
		public function setHeader(string:String):void
		{
			query("#header").attr(Attribute.TEXT, string);
		}
		
		public function setStateProcess(status:String):void
		{
			query("#status")
				.attr(Attribute.TEXT, status);

			query("#spinner")
				.attr(Attribute.VISIBLE, true)
				.forEach(juggler.tween, 1, {
						repeatCount: 0,
						onUpdate: function():void { query("#spinner").attr(Attribute.TRANSFORM, "rotate(" + juggler.elapsedTime*180 + ")"); }
					}
				);
				
			query("#details")
				.attr(Attribute.VISIBLE, false);
		}
		
		public function setStateComplete(status:String = null, details:String = null):void
		{
			if (status) query("#status")
				.attr(Attribute.TEXT, status);
			
			query("#spinner")
				.attr(Attribute.VISIBLE, false)
				.forEach(juggler.removeTweens);

			query("#details")
				.attr(Attribute.VISIBLE, details != null);

			query("#detailsInfo")
				.attr(Attribute.TEXT, details);
		}
	}
}
