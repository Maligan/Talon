package browser.ui.popups
{
	import starling.errors.AbstractMethodError;

	import talon.starling.TalonSprite;
	import talon.utils.ITalonElement;

	public class Popup extends TalonSprite implements ITalonElement
	{
		public function Popup():void
		{
			node.position.parse("50%");
			node.pivot.parse("50%");
		}

		public function initialize(manager:PopupManager, data:Object = null):void
		{
			throw new AbstractMethodError();
		}
	}
}