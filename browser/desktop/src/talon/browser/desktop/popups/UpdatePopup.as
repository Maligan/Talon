package talon.browser.desktop.popups
{
	import flash.events.Event;

	import talon.browser.desktop.utils.Updater;
	import talon.browser.platform.popups.Popup;

	public class UpdatePopup extends Popup
	{
		private var _updater:Updater;

		protected override function initialize():void
		{
			addChild(manager.factory.create("UpdatePopup"));
			node.commit();

			query("#cancel").onTap(onCancelClick);
			query("#update").onTap(onUpdateClick);
			query("#spinner").tween(1, { rotation: 2*Math.PI, repeatCount: 0 }, juggler);

			_updater = Updater(data);
			_updater.addEventListener(Event.CHANGE, onUpdaterChange);
			_updater.addEventListener(Event.COMPLETE, onUpdaterComplete);
		}

		private function onUpdateClick(e:*):void
		{
			_updater.execute();
		}

		private function onCancelClick():void
		{
			_updater.stop();
			close();
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
