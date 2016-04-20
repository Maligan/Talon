package talon.browser.popups
{
	import flash.events.Event;

	import talon.browser.AppConstants;
	import talon.browser.utils.Updater;

	public class UpdatePopup extends Popup
	{
		private var _updater:Updater;

		protected override function initialize():void
		{
			addChild(manager.factory.produce("UpdatePopup"));

			_updater = new Updater(AppConstants.APP_UPDATE_URL, AppConstants.APP_VERSION);
			_updater.addEventListener(Event.CHANGE, onUpdaterChange);
			_updater.addEventListener(Event.COMPLETE, onUpdaterComplete);
			_updater.execute(true);
		}

		public override function dispose():void
		{
			_updater.removeEventListener(Event.CHANGE, onUpdaterChange);
			_updater.removeEventListener(Event.COMPLETE, onUpdaterComplete);
			_updater.stop();

			super.dispose();
		}

		private function onUpdateClick(e:*):void
		{
			_updater.execute();
		}

		//
		// Updater Events
		//
		private function onUpdaterChange(e:*):void
		{
			// show Updater log
		}

		private function onUpdaterComplete(e:*):void
		{
			if (_updater.lastStatus == "UPDATE_DESCRIPTOR_LOADED")
			{

			}
			else if (_updater.lastStatus == "UPDATER_STARTED")
			{

			}
			else
			{
				// show Error
			}
		}
	}
}
