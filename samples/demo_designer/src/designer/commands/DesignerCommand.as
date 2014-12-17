package designer.commands
{
	import starling.errors.AbstractMethodError;
	import starling.events.EventDispatcher;

	[Event(name="progress", type="starling.events.Event")]
	public class DesignerCommand extends EventDispatcher
	{
		public function execute():void
		{
			throw new AbstractMethodError();
		}
	}
}
