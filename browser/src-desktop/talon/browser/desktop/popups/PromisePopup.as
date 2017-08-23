package talon.browser.desktop.popups
{
	import flash.ui.Keyboard;

	import starling.display.DisplayObject;
	import starling.events.Event;

	import talon.core.Attribute;
	import talon.browser.platform.popups.Popup;

	public class PromisePopup extends Popup
	{
		private var _details:Boolean;
		
		protected override function initialize():void
		{
			addChild(manager.factory.build("PromisePopup") as DisplayObject);
			node.commit();

			query().setAttribute("header", "Hello World");
			query("#detailsInfo").setAttribute(Attribute.VISIBLE, _details);

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
			query("#details").setAttribute(Attribute.TRANSFORM, _details ? "rotate(-90deg)" : "none");
			query("#detailsInfo").setAttribute(Attribute.VISIBLE, _details);
		}
		
		public function setHeader(string:String):void
		{
			query("#header").setAttribute(Attribute.TEXT, string);
		}
		
		public function setStateProcess(status:String):void
		{
			query("#status")
				.setAttribute(Attribute.TEXT, status);

			query("#spinner")
				.setAttribute(Attribute.VISIBLE, true)
				.tween(1, { repeatCount: 0, onUpdate: function ():void {
					query("#spinner").setAttribute(Attribute.TRANSFORM, "rotate(" + (juggler.elapsedTime*180) + "deg)");
				}}, juggler);

			query("#details")
				.setAttribute(Attribute.VISIBLE, false);
		}
		
		public function setStateComplete(status:String = null, details:String = null):void
		{
			if (status) query("#status")
				.setAttribute(Attribute.TEXT, status);
			
			query("#spinner")
				.setAttribute(Attribute.VISIBLE, false)
				.tweenKill(juggler);

			query("#details")
				.setAttribute(Attribute.VISIBLE, details != null);

			query("#detailsInfo")
				.setAttribute(Attribute.TEXT, details);
		}
	}
}
